import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelter_manager/presentation/widgets/shelter_detail_panel.dart';

/// Détail en écran étroit (téléphone). En large, le panneau est affiché
/// directement à droite de la liste.
class ShelterDetailPage extends StatelessWidget {
  const ShelterDetailPage({super.key, required this.shelterId});
  final String shelterId;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Mon refuge')),
        body: SafeArea(child: ShelterDetailPanel(shelterId: shelterId)),
      );
}
