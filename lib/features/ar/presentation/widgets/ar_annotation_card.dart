import 'package:flutter/material.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';

/// Étiquette superposée à la caméra pour un [SalusArAnnotation].
/// Fond translucide + texte clair : lisible sur n'importe quel décor.
class ArAnnotationCard extends StatelessWidget {
  const ArAnnotationCard({super.key, required this.annotation});

  final SalusArAnnotation annotation;

  @override
  Widget build(BuildContext context) {
    final poi = annotation.poi;
    return GestureDetector(
      onTap: poi.shelter == null
          ? null
          : () => showShelterBottomSheet(context, poi.shelter!),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: poi.color, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: poi.color.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
                child: Icon(poi.icon, size: 26, color: poi.color),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${arDistanceLabel(annotation.distanceFromUser)}'
                      '${poi.subtitle == null ? '' : ' · ${poi.subtitle}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
