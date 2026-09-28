import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: const Center(
        child: Text('Centre d\u2019aide — bientôt disponible.'),
      ),
    );
  }
}
