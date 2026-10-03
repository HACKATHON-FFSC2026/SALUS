import 'package:ar_location_view/ar_annotation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/features/risks/presentation/mappers/zone_ui_mapper.dart';
import 'package:salus/features/shelters/presentation/widgets/shelter_status_ui.dart';

/// Donnée d'affichage d'un point d'intérêt superposé à la caméra.
/// `shelter` non null → ouverture de la fiche refuge à l'appui.
class ArPoi {
  const ArPoi({
    required this.uid,
    required this.title,
    required this.icon,
    required this.color,
    required this.position,
    this.subtitle,
    this.shelter,
  });

  final String uid;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Position position;
  final Shelter? shelter;
}

class SalusArAnnotation extends ArAnnotation {
  SalusArAnnotation({required this.poi})
    : super(uid: poi.uid, position: poi.position);

  final ArPoi poi;
}

/// Construit les annotations AR : refuges validés ouverts/avec places,
/// plus zones à risque et sûres (représentées par leur centroïde).
/// Ponytail : le filtrage distance est fait par ArLocationWidget
/// ([maxVisibleDistance]) ; on ne pré-filtre pas ici.
List<SalusArAnnotation> buildArAnnotations(
  List<Shelter> shelters,
  List<Zone> riskZones,
  List<Zone> safeZones,
) => [
  for (final s in shelters)
    if (s.canStartNavigation)
      SalusArAnnotation(
        poi: ArPoi(
          uid: 'shelter-${s.id}',
          title: s.name,
          subtitle:
              '${s.status.label} · ${s.availablePlaces} place${s.availablePlaces > 1 ? 's' : ''}',
          icon: Icons.night_shelter,
          color: s.status.foregroundColor,
          shelter: s,
          position: _position(s.location.latitude, s.location.longitude),
        ),
      ),
  for (final z in [...riskZones, ...safeZones])
    if (z.geometry.isNotEmpty)
      SalusArAnnotation(
        poi: ArPoi(
          uid: 'zone-${z.id}-${z.type.name}',
          title: z.type == ZoneType.safe ? 'Zone sûre' : 'Zone ${z.label}',
          subtitle:
              z.type == ZoneType.safe
                  ? 'à proximité'
                  : switch (z.severity) {
                    Severity.low => 'gravité faible',
                    Severity.medium => 'gravité moyenne',
                    Severity.high => 'gravité élevée',
                    Severity.critical => 'gravité critique',
                    null => null,
                  },
          icon: z.type == ZoneType.safe ? Icons.health_and_safety_outlined : z.icon,
          color: z.borderColor,
          position: _position(
            z.center.latitude,
            z.center.longitude,
          ),
        ),
      ),
];

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.now(),
  accuracy: 0,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

String arDistanceLabel(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${meters.round()} m';
