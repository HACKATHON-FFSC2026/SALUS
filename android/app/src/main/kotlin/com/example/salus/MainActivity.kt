package com.example.salus

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipFile
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val modelName = "vosk-model-small-fr-0.22"
    private val modelAssetSize = 42_233_323L
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var eventSink: EventChannel.EventSink? = null
    private var model: Model? = null
    private var recognizer: Recognizer? = null
    private var recordThread: Thread? = null
    @Volatile private var recording = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "salus/vosk")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val modelAsset = call.argument<String>("modelAsset")
                        if (modelAsset == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Missing Vosk model asset",
                                null,
                            )
                        } else {
                            runNative(result) {
                                releaseNative()
                                val modelPath = prepareBundledModel(modelAsset)
                                val loadedModel = Model(modelPath)
                                // Reconnaissance complète, sans grammaire Vosk :
                                // le mode grammaire exige un lexique que ce
                                // modèle n'expose pas et échoue silencieusement.
                                // Le filtrage des mots-clés se fait côté Dart.
                                model = loadedModel
                                recognizer = Recognizer(loadedModel, 16000f)
                                true
                            }
                        }
                    }

                    "start" -> runNative(result) {
                        val currentRecognizer = recognizer
                            ?: throw IllegalStateException("Vosk is not initialized")
                        stopRecognition()
                        currentRecognizer.reset()
                        startRecognition(currentRecognizer)
                        true
                    }

                    "stop" -> runNative(result) {
                        stopRecognition()
                        true
                    }

                    "dispose" -> runNative(result) {
                        releaseNative()
                        true
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "salus/vosk/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun runNative(result: MethodChannel.Result, operation: () -> Any?) {
        worker.execute {
            try {
                val value = operation()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error("VOSK_ERROR", error.message, null)
                }
            }
        }
    }

    private fun emit(type: String, hypothesis: String) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type, "json" to hypothesis))
        }
    }

    private fun emitModelProgress(progress: Double) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "modelProgress", "progress" to progress))
        }
    }

    private fun prepareBundledModel(assetPath: String): String {
        val modelDirectory = File(filesDir, modelName)
        val stagingDirectory = File(filesDir, "$modelName.tmp")
        val archiveFile = File(filesDir, "$modelName.zip")
        if (File(modelDirectory, "am/final.mdl").exists()) {
            archiveFile.delete()
            stagingDirectory.deleteRecursively()
            emitModelProgress(1.0)
            return modelDirectory.absolutePath
        }

        if (modelDirectory.exists()) modelDirectory.deleteRecursively()
        if (!stagingDirectory.mkdirs()) {
            if (!stagingDirectory.isDirectory) {
                throw IOException("Unable to prepare Vosk model directory")
            }
        }

        var copied = if (archiveFile.exists()) archiveFile.length() else 0L
        if (copied > modelAssetSize) {
            archiveFile.delete()
            copied = 0
        }
        assets.open(assetPath).use { input ->
            val discard = ByteArray(64 * 1024)
            var skipped = 0L
            while (skipped < copied) {
                val count = input.read(
                    discard,
                    0,
                    minOf(discard.size.toLong(), copied - skipped).toInt(),
                )
                if (count < 0) throw IOException("Bundled Vosk asset ended early")
                skipped += count
            }

            FileOutputStream(archiveFile, copied > 0).use { output ->
                val buffer = ByteArray(64 * 1024)
                var lastPercent = (copied * 35 / modelAssetSize).toInt()
                emitModelProgress(lastPercent / 100.0)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    output.write(buffer, 0, count)
                    copied += count
                    if (copied > modelAssetSize) {
                        throw IOException("Bundled Vosk model exceeds expected size")
                    }
                    val percent = (copied * 35 / modelAssetSize).toInt()
                    if (percent != lastPercent) {
                        lastPercent = percent
                        emitModelProgress(percent / 100.0)
                    }
                }
                if (copied != modelAssetSize) {
                    throw IOException("Bundled Vosk model has an unexpected size")
                }
            }
        }

        if (archiveFile.length() != modelAssetSize) {
            throw IOException("Bundled Vosk archive is incomplete")
        }

        ZipFile(archiveFile).use { zip ->
            var totalBytes = 0L
            val entriesForSize = zip.entries()
            while (entriesForSize.hasMoreElements()) {
                val entry = entriesForSize.nextElement()
                if (!entry.isDirectory) totalBytes += entry.size
            }
            if (totalBytes <= 0) throw IOException("Bundled Vosk model is empty")

            val rootPath = stagingDirectory.canonicalPath + File.separator
            val entries = zip.entries()
            var extractedBytes = 0L
            var lastPercent = -1
            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()
                val outputFile = File(stagingDirectory, entry.name)
                if (!outputFile.canonicalPath.startsWith(rootPath)) {
                    throw IOException("Invalid path in bundled Vosk model")
                }
                if (entry.isDirectory) {
                    outputFile.mkdirs()
                    continue
                }

                if (outputFile.exists() && outputFile.length() == entry.size) {
                    extractedBytes += entry.size
                    val percent = 35 + (extractedBytes * 65 / totalBytes).toInt()
                    if (percent != lastPercent) {
                        lastPercent = percent
                        emitModelProgress(percent / 100.0)
                    }
                    continue
                }

                outputFile.parentFile?.mkdirs()
                zip.getInputStream(entry).use { input ->
                    FileOutputStream(outputFile).use { output ->
                        val buffer = ByteArray(64 * 1024)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            output.write(buffer, 0, count)
                            extractedBytes += count
                            val percent = 35 + (extractedBytes * 65 / totalBytes).toInt()
                            if (percent != lastPercent) {
                                lastPercent = percent
                                emitModelProgress(percent / 100.0)
                            }
                        }
                    }
                }
            }
        }

        val extractedModel = File(stagingDirectory, modelName)
        if (!File(extractedModel, "am/final.mdl").exists() ||
            !extractedModel.renameTo(modelDirectory)
        ) {
            throw IOException("Unable to install bundled Vosk model")
        }
        archiveFile.delete()
        stagingDirectory.deleteRecursively()
        emitModelProgress(1.0)
        return modelDirectory.absolutePath
    }

    /// Construit un `AudioRecord` utilisable, en essayant plusieurs sources.
    ///
    /// `VOICE_RECOGNITION` n'est pas disponible sur tous les appareils réels
    /// (échec d'initialisation ou silence) alors que l'émulateur l'accepte
    /// toujours. On retombe donc sur `MIC` puis `DEFAULT`. Le micro interne est
    /// épinglé quand plusieurs entrées existent, pour éviter un routage vers un
    /// périphérique sans micro (casque, USB).
    private fun createRecorder(): AudioRecord {
        val sampleRate = 16000
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufferSize = maxOf(minBuffer, sampleRate * 2)
        val sources = intArrayOf(
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.DEFAULT,
        )
        for (source in sources) {
            var recorder: AudioRecord? = null
            try {
                recorder = AudioRecord(
                    source,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize,
                )
                if (recorder.state == AudioRecord.STATE_INITIALIZED) {
                    pinToBuiltInMic(recorder)
                    return recorder
                }
            } catch (_: Exception) {
                // Source indisponible, on essaie la suivante.
            }
            recorder?.release()
        }
        throw IOException("Impossible d'initialiser le microphone")
    }

    private fun pinToBuiltInMic(recorder: AudioRecord) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return
        try {
            val manager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val inputs = manager.getDevices(AudioManager.GET_DEVICES_INPUTS)
            if (inputs.size <= 1) return
            val builtIn = inputs.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC
            }
            if (builtIn != null) recorder.setPreferredDevice(builtIn)
        } catch (_: Exception) {
            // Le routage par défaut reste correct.
        }
    }

    /// Boucle de capture maison, à la place de `SpeechService`.
    ///
    /// La version 0.3.75 de `vosk-android` n'expose pas de constructeur
    /// acceptant un `AudioRecord` fourni : elle impose `VOICE_RECOGNITION`,
    /// qui échoue sur certains appareils réels. On gère donc nous-mêmes la
    /// capture pour choisir la source et router le micro.
    private fun startRecognition(recognizer: Recognizer) {
        if (recordThread != null) return
        recording = true
        recordThread = Thread {
            var recorder: AudioRecord? = null
            try {
                recorder = createRecorder()
                recorder.startRecording()
                // ~0,26 s par segment : assez fin pour des résultats partiels
                // réactifs, assez gros pour ne pas surcharger le recognizer.
                val buffer = ShortArray(4096)
                while (recording) {
                    val read = recorder.read(buffer, 0, buffer.size)
                    if (read <= 0) continue
                    if (recognizer.acceptWaveForm(buffer, read)) {
                        emit("result", recognizer.result)
                    } else {
                        emit("partial", recognizer.partialResult)
                    }
                }
                emit("final", recognizer.finalResult)
            } catch (error: Exception) {
                emitError(error.message.orEmpty())
            } finally {
                try {
                    recorder?.stop()
                } catch (_: Exception) {}
                recorder?.release()
            }
        }.also { it.start() }
    }

    private fun stopRecognition() {
        recording = false
        val thread = recordThread
        recordThread = null
        try {
            thread?.join(1500)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    private fun emitError(message: String) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "error", "message" to message))
        }
    }

    private fun releaseNative() {
        stopRecognition()
        recognizer?.close()
        recognizer = null
        model?.close()
        model = null
    }

    override fun onDestroy() {
        worker.execute { releaseNative() }
        worker.shutdown()
        super.onDestroy()
    }
}
