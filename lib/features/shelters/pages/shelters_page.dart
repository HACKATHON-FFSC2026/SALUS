import 'package:flutter/material.dart';

class SheltersPage extends StatelessWidget {
  const SheltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refuges')),
      body: const Center(child: Text('Aucun refuge à proximité.')),
    );
  }
}
