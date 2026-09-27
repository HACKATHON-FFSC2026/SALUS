import 'package:salus/initialization.dart';
import 'package:salus/my_app.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await initializeApp();
  runApp(const MyApp());
}
