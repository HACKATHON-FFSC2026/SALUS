import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:salus/app/routes/app_router.dart';
import 'package:salus/core/themes/app_theme.dart';

class SheltersPage extends StatelessWidget {
  const SheltersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refuges')),
      body: const Center(child: Text('Aucun refuge à proximité.')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.router.push(const CreateShelterRoute()),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Créer un refuge'),
      ),
    );
  }
}
