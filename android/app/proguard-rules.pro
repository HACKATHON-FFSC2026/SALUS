# Vosk uses JNA: JNI binding via reflection + field names, which R8 breaks.
-keep class com.sun.jna.** { *; }
-keep class org.vosk.** { *; }
-dontwarn com.sun.jna.**
