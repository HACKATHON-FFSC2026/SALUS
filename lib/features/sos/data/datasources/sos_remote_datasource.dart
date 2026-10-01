import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';

abstract class ISosRemoteDataSource {
  Future<void> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  Stream<SOSAlert?> watchSosAlert(String alertId);

  // Tâche 13 : Annuler dans Firestore
  Future<void> cancelSosAlert(String alertId);

  // Tâche 14 : Écouter tous les SOS actifs
  Stream<List<SOSAlert>> watchActiveSosAlerts();

  // Tâche 14 & 15 : Répondre à un SOS
  Future<void> respondToSos(String alertId);
}

class SosRemoteDataSourceImpl implements ISosRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SosRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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

    final docRef = _firestore.collection('alerts').doc();

    final sosAlert = SOSAlert(
      id: docRef.id,
      userId: currentUser.uid,
      location: GeoPoint(latitude, longitude),
      distressType: distressType,
      description: description,
      status: SOSStatus.waiting,
      respondersCount: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(sosAlert.toJson());
  }

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) {
    return _firestore
        .collection('alerts')
        .doc(alertId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return SOSAlert.fromJson(snapshot.data()!);
    });
  }

  @override
  Future<void> cancelSosAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'status': SOSStatus.cancelled.name,
    });
  }

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts() {
    return _firestore
        .collection('alerts')
        .where('status', whereIn: [
          SOSStatus.waiting.name,
          SOSStatus.inProgress.name,
        ])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SOSAlert.fromJson(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> respondToSos(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'respondersCount': FieldValue.increment(1),
      'status': SOSStatus.inProgress.name,
    });
  }
}