import 'package:flutter/material.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/map/presentation/widgets/salus_map_widget.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SalusMapWidget()),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.surface.withValues(alpha: 0.96),
              elevation: 3,
              shadowColor: AppColors.primary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Aucune alerte à proximité',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
