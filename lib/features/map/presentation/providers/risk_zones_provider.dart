import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/features/map/data/risk_zone_repository.dart';

/// Zones à risque actives, diffusées en direct depuis Firestore.
final activeRiskZonesProvider = StreamProvider<List<Zone>>(
  (ref) => ref
      .watch(riskZoneRepositoryProvider)
      .watchActiveRiskZones()
      .handleError((Object error, StackTrace stackTrace) {
        Log.error('Échec du chargement des zones à risque', error, stackTrace);
        throw error;
      }),
);
