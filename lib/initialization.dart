import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/firebase_options.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _initializeAuth();
}

Future<void> _initializeAuth() async {
  // ponytail: firebase_options.dart only configures Android, so this throws on
  // iOS/web until `flutterfire configure` is re-run. Not fatal: sign-in just
  // stays unavailable on those platforms.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await GoogleSignIn.instance.initialize();
  } catch (e, s) {
    Log.error('Initialisation Firebase/Google impossible', e, s);
  }
}
