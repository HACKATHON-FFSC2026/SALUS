import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';

abstract class IAlertsRemoteDataSource {
  Future<void> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  Future<void> cancelSosAlert(String alertId);
  Future<void> respondToSos(String alertId);
  Future<void> resolveSosAlert(String alertId, {String? resolutionType, String? resolutionNote});
  Stream<SOSAlert?> watchSosAlert(String alertId);
  Stream<List<SOSAlert>> watchActiveSosAlerts();
}

class AlertsRemoteDataSourceImpl implements IAlertsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AlertsRemoteDataSourceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  SOSAlert _mapDocument(String id, Map<String, dynamic> data) {
    final location = data['location'] as GeoPoint? ?? const GeoPoint(0, 0);
    final distressType = DistressType.values.firstWhere(
      (value) => value.name == data['distressType'],
      orElse: () => DistressType.other,
    );
    final status = SOSStatus.values.firstWhere(
      (value) => value.name == data['status'],
      orElse: () => SOSStatus.waiting,
    );

    return SOSAlert(
      id: id,
      userId: data['userId'] ?? '',
      location: location,
      locationName: data['locationName'] as String?,
      distressType: distressType,
      description: data['description'] as String?,
      status: status,
      respondersCount: (data['respondersCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<void> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté.');
    }

    final locationName =
        'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    final docRef = _firestore.collection('SOS_alertes').doc();

    await docRef.set({
      'id': docRef.id,
      'userId': currentUser.uid,
      'location': GeoPoint(latitude, longitude),
      'locationName': locationName,
      'distressType': distressType.name,
      'description': description,
      'status': SOSStatus.waiting.name,
      'respondersCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) {
    return _firestore.collection('SOS_alertes').doc(alertId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return _mapDocument(doc.id, doc.data()!);
    });
  }

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts() {
    return _firestore
        .collection('SOS_alertes')
        .where(
          'status',
          whereIn: [SOSStatus.waiting.name, SOSStatus.inProgress.name],
        )
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => _mapDocument(doc.id, doc.data()))
              .toList();
          alerts.sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
          return alerts;
        });
  }

  @override
  Future<void> cancelSosAlert(String alertId) async {
    final docRef = _firestore.collection('SOS_alertes').doc(alertId);
    await docRef.update({
      'status': SOSStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> respondToSos(String alertId) async {
    final docRef = _firestore.collection('SOS_alertes').doc(alertId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Alerte introuvable.');
    }

    final current = snapshot.data() ?? {};
    final nextCount = ((current['respondersCount'] as num?)?.toInt() ?? 0) + 1;

    // Synchroniser le statut avec le nombre d'intervenants
    final newStatus = nextCount >= 1 ? SOSStatus.inProgress : SOSStatus.waiting;

    await docRef.update({
      'respondersCount': nextCount,
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resolveSosAlert(String alertId, {String? resolutionType, String? resolutionNote}) async {
    final docRef = _firestore.collection('SOS_alertes').doc(alertId);
    final updateData = <String, dynamic>{
      'status': SOSStatus.resolved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (resolutionType != null) {
      updateData['resolutionType'] = resolutionType;
    }
    
    if (resolutionNote != null && resolutionNote.isNotEmpty) {
      updateData['resolutionNote'] = resolutionNote;
    }
    
    await docRef.update(updateData);
  }
}
