import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/geo_grid.dart';
import 'package:salus/core/utils/log.dart';

/// Bornes de sécurité: au-delà, la liste devient inutilisable et coûte cher.
/// Un flux d'alertes vit ou meurt dans les premières minutes, pas des heures.
const _maxAlertsPerRead = 200;

abstract class ISosRemoteDataSource {
  /// Retourne l'identifiant du document créé.
  Future<String> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  Stream<SOSAlert?> watchSosAlert(String alertId);

  Future<void> cancelSosAlert(String alertId);

  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells});

  Stream<List<SOSAlert>> watchMyActiveSosAlerts();

  Future<void> respondToSos(String alertId);

  Future<void> shareSosLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  });
}

class SosRemoteDataSourceImpl implements ISosRemoteDataSource {
  SosRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// `sos_alerts` et non `alerts`: c'est le nom couvert par `firestore.rules`.
  static const alertsCollection = 'sos_alerts';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Connectez-vous pour envoyer une alerte SOS.');
    }
    return uid;
  }

  @override
  Future<String> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    final docRef = _firestore.collection(alertsCollection).doc();
    final now = DateTime.now();

    final sosAlert = SOSAlert(
      id: docRef.id,
      userId: _requireUid(),
      location: GeoPoint(latitude, longitude),
      distressType: distressType,
      description: description,
      status: SOSStatus.waiting,
      createdAt: now,
      locationUpdatedAt: now,
    );

    await docRef.set(sosAlert.toJson());
    return docRef.id;
  }

  @override
  Stream<SOSAlert?> watchSosAlert(String alertId) {
    return _firestore
        .collection(alertsCollection)
        .doc(alertId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      // L'id du document fait foi: le champ `id` peut diverger ou manquer.
      return SOSAlert.fromJson(data).copyWith(id: snapshot.id);
    });
  }

  @override
  Future<void> cancelSosAlert(String alertId) async {
    await _firestore.collection(alertsCollection).doc(alertId).update({
      'status': SOSStatus.cancelled.name,
    });
  }

  @override
  Stream<List<SOSAlert>> watchActiveSosAlerts({List<String>? geoCells}) {
    Query<Map<String, dynamic>> query = _firestore.collection(alertsCollection).where(
      'status',
      whereIn: [SOSStatus.waiting.name, SOSStatus.inProgress.name],
    );

    if (geoCells != null && geoCells.isNotEmpty) {
      query = query.where('geoCell', whereIn: geoCells);
    }

    return query.limit(_maxAlertsPerRead).snapshots().map(
      (snapshot) => _decode(snapshot.docs),
    );
  }

  /// Un document illisible est ignoré, jamais fatal: une alerte corrompue ne
  /// doit pas priver les autres récepteurs de la liste.
  List<SOSAlert> _decode(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final alerts = <SOSAlert>[];
    for (final doc in docs) {
      try {
        alerts.add(SOSAlert.fromJson(doc.data()).copyWith(id: doc.id));
      } on FormatException catch (e, s) {
        Log.error('Alerte SOS illisible, ignorée (${doc.id})', e, s);
      }
    }
    return alerts;
  }

  @override
  Stream<List<SOSAlert>> watchMyActiveSosAlerts() {
    return _firestore
        .collection(alertsCollection)
        .where('userId', isEqualTo: _requireUid())
        .where(
          'status',
          whereIn: [SOSStatus.waiting.name, SOSStatus.inProgress.name],
        )
        .limit(10)
        .snapshots()
        .map((snapshot) => _decode(snapshot.docs));
  }

  @override
  Future<void> respondToSos(String alertId) async {
    // `arrayUnion` plutôt qu'un incrément: deux taps ou deux providers ne
    // doivent pas compter deux fois la même personne. Le statut reste
    // `waiting`: seul un aidant identifié peut basculer en `inProgress`.
    await _firestore.collection(alertsCollection).doc(alertId).update({
      'responderIds': FieldValue.arrayUnion([_requireUid()]),
    });
  }

  @override
  Future<void> shareSosLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection(alertsCollection).doc(alertId).update({
      'location': GeoPoint(latitude, longitude),
      'geoCell': GeoGrid.cellFor(latitude, longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}