import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/entities.dart';
import 'package:salus/core/sources/firestore_client.dart';
import 'package:salus/core/utils/log.dart';

class FirestoreRiskZoneRepository {
  const FirestoreRiskZoneRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Zone>> watchActiveRiskZones() => _firestore
      .collection('zones')
      .where('type', isEqualTo: ZoneType.risk.name)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final zones = <Zone>[];
        for (final document in snapshot.docs) {
          final zone = _decode(document.id, document.data());
          if (zone != null && zone.isActive && zone.geometry.length >= 3) {
            zones.add(zone);
          }
        }
        return zones;
      });

  Zone? _decode(String id, Map<String, dynamic> data) {
    try {
      return Zone.fromJson({...data, 'id': id});
    } catch (error, stackTrace) {
      Log.error('Zone à risque $id illisible, ignorée', error, stackTrace);
      return null;
    }
  }
}

final riskZoneRepositoryProvider = Provider<FirestoreRiskZoneRepository>(
  (ref) => FirestoreRiskZoneRepository(ref.watch(firestoreProvider)),
);
