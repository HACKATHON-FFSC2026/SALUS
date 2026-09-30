import 'package:flutter/material.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

/// Marqueur uniforme pour identifier les refuges sur la carte.
/// Le petit badge porte le statut opérationnel.
class ShelterMarkerPin extends StatelessWidget {
  const ShelterMarkerPin({super.key, required this.status});

  final ShelterStatus status;

  /// Taille visible du pin (le [Marker] qui l'accueille est plus large pour
  /// garder une zone de tap confortable).
  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refuge ${status.label}',
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    status.icon,
                    size: 9,
                    color: status.foregroundColor == status.color
                        ? Colors.white
                        : status.foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
