import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [Icon(Icons.person_2_outlined, color: AppColors.primary)],
        // withOpacity(0.01) remplacait l'alpha, pas multiplication : rendu
        // quasi transparent. Equivalence exacte conservee, cf. livraison.
        backgroundColor: AppColors.primary.withValues(alpha: 0.01),
      ),
      body: Stack(
        children: [
          const SalusMapWidget(),

          // 2. Overlay d'accueil en haut de la carte
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.surface.withValues(alpha: 0.9),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const AppLogo(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Situation',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Aucune alerte à proximité',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
