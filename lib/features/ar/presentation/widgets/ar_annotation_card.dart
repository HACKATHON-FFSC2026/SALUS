import 'package:flutter/material.dart';
import 'package:salus/features/ar/presentation/models/salus_ar_annotation.dart';
import 'package:salus/features/map/presentation/widgets/zone_bottom_sheet.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_bottom_sheet.dart';

/// Pastille d'annotation reliée à sa position projetée dans la caméra.
class ArAnnotationCard extends StatelessWidget {
  const ArAnnotationCard({
    super.key,
    required this.annotation,
    required this.pulse,
  });

  static const width = 250.0;
  static const cardHeight = 72.0;
  static const maxStemLength = 120.0;
  static const height = 2 * (cardHeight + maxStemLength);

  final SalusArAnnotation annotation;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final poi = annotation.poi;
    final shelter = poi.shelter;
    final zone = poi.zone;
    final distance = arDistanceLabel(annotation.distanceFromUser);
    final pointY = height / 2 - annotation.arPositionOffset.dy;
    final anchorY = annotation.arPosition.dy + height / 2;
    final spaceAbove = anchorY - cardHeight - 12;
    final placeAbove = spaceAbove >= 0;
    final availableStemLength = placeAbove
        ? spaceAbove
        : MediaQuery.sizeOf(context).height - anchorY - cardHeight - 12;
    final stemLength = availableStemLength.clamp(0.0, maxStemLength).toDouble();
    final stemTop = placeAbove ? pointY - stemLength : pointY;
    final cardTop = placeAbove ? stemTop - cardHeight : pointY + stemLength;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: width / 2 - 1,
                  top: stemTop,
                  width: 2,
                  height: stemLength,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Positioned(
                  left: width / 2 - 20,
                  top: pointY - 20,
                  width: 40,
                  height: 40,
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) => Center(
                      child: Opacity(
                        opacity: 1 - pulse.value,
                        child: SizedBox.square(
                          dimension: 14 + pulse.value * 22,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width / 2 - 5,
                  top: pointY - 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: cardTop,
            height: cardHeight,
            child: Tooltip(
              message: '${poi.title}, $distance',
              child: Material(
                color: Colors.white,
                elevation: 5,
                borderRadius: BorderRadius.circular(40),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () {
                    if (shelter != null) {
                      showShelterBottomSheet(context, shelter);
                    } else if (zone != null) {
                      showZoneBottomSheet(context, zone);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.black,
                          child: Icon(poi.icon, size: 25, color: Colors.white),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poi.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (poi.subtitle != null)
                                Text(
                                  poi.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF626262),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Color(0xFF454545),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
