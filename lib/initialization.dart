import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/firebase_options.dart';

const _googleWebClientId =
    '755877285966-gau26sei9rhj9f87r050qn7tqobv60at.apps.googleusercontent.com';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await _initializeAuth();
}

Future<void> _initializeAuth() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(clientId: _googleWebClientId);
    } else {
      await GoogleSignIn.instance.initialize();
    }
  } catch (e, s) {
    Log.error('Initialisation Firebase/Google impossible', e, s);
  }
}
