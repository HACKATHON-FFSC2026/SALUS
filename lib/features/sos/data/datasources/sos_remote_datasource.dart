import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salus/core/entities/help_response_entity.dart';
import 'package:salus/core/entities/location_share_entity.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import 'package:salus/core/utils/geo_grid.dart';
import 'package:salus/core/utils/log.dart';

/// Bornes de sécurité: au-delà, la liste devient inutilisable et coûte cher.
/// Un flux d'alertes vit ou meurt dans les premières minutes, pas des heures.
const _maxAlertsPerRead = 200;

/// Un document par intervenant et par alerte, dans les deux collections.
///
/// Conséquence recherchée: répondre deux fois à la même alerte réutilise le
/// même document au lieu d'en créer un second, qui doublerait le compte côté
/// victime. Le retrait ne l'efface pas — il passe par le statut.
String responderDocumentId({
  required String alertId,
  required String responderId,
}) => '${alertId}_$responderId';

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

  Future<String> createHelpResponse({
    required String alertId,
    required ResponseType responseType,
    String? message,
  });

  Future<void> setHelpResponseStatus({
    required String responseId,
    required HelpResponseStatus status,
  });

  Stream<List<HelpResponse>> watchHelpResponses(String alertId);

  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  });

  Future<void> stopResponderLocation(String alertId);

  Stream<List<LocationShare>> watchResponderLocations(String alertId);

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

  /// Noms imposés par `firestore.rules`.
  static const helpResponsesCollection = 'help_responses';
  static const locationSharesCollection = 'location_shares';

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
  Future<String> createHelpResponse({
    required String alertId,
    required ResponseType responseType,
    String? message,
  }) async {
    final uid = _requireUid();
    final docRef = _firestore.collection(helpResponsesCollection).doc(
      responderDocumentId(alertId: alertId, responderId: uid),
    );
    final existing = await docRef.get();
    if (existing.exists) {
      // Ne pas écraser un suivi en cours: le create fige `status` à `offered`,
      // le réécrire ferait régresser un intervenant déjà arrivé. Seul un
      // désistement se relance, parce que répondre à nouveau est un acte
      // explicite.
      if (_statusOf(existing.data()) == HelpResponseStatus.cancelled) {
        await docRef.update({
          'status': HelpResponseStatus.offered.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return docRef.id;
    }

    // ponytail: horloge client pour `createdAt`/`updatedAt`, l'entité les veut
    // non nuls. Ces deux champs ne servent qu'à l'affichage, les règles ne les
    // regardent pas, donc un skew d'horloge n'a rien à casser ici.
    final now = DateTime.now();
    final response = HelpResponse(
      id: docRef.id,
      responderId: uid,
      sosAlertId: alertId,
      responseType: responseType,
      status: HelpResponseStatus.offered,
      message: message,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(response.toJson());
    return docRef.id;
  }

  @override
  Future<void> setHelpResponseStatus({
    required String responseId,
    required HelpResponseStatus status,
  }) async {
    // Écriture brute, pas `toJson`: les règles n'autorisent que
    // `changedOnly(['status','message','updatedAt'])`, donc réécrire `id` ou
    // `createdAt` se ferait refuser.
    await _firestore.collection(helpResponsesCollection).doc(responseId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<HelpResponse>> watchHelpResponses(String alertId) {
    return _firestore
        .collection(helpResponsesCollection)
        .where('sosAlertId', isEqualTo: alertId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) _decodeHelpResponse(doc),
          ].whereType<HelpResponse>().toList(growable: false),
        );
  }

  @override
  Future<void> shareResponderLocation({
    required String alertId,
    required double latitude,
    required double longitude,
  }) async {
    final uid = _requireUid();
    final docRef = _firestore.collection(locationSharesCollection).doc(
      responderDocumentId(alertId: alertId, responderId: uid),
    );
    final location = LocationShare(
      id: docRef.id,
      userId: uid,
      sosAlertId: alertId,
      currentLocation: GeoPoint(latitude, longitude),
      // ponytail: même horloge client que pour `help_responses`, champ
      // d'affichage uniquement.
      updatedAt: DateTime.now(),
    );
    await docRef.set(location.toJson());
  }

  @override
  Future<void> stopResponderLocation(String alertId) async {
    final uid = _requireUid();
    final docRef = _firestore.collection(locationSharesCollection).doc(
      responderDocumentId(alertId: alertId, responderId: uid),
    );
    // Le document reste: les règles interdisent de modifier autre chose que
    // la position, et `isActive: false` dit à la victime que le point est
    // figé plutôt que disparu.
    try {
      await docRef.update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // GPS coupé: aucun point n'a jamais été publié, il n'y a rien à figer.
      if (e.code != 'not-found') rethrow;
    }
  }

  @override
  Stream<List<LocationShare>> watchResponderLocations(String alertId) {
    return _firestore
        .collection(locationSharesCollection)
        .where('sosAlertId', isEqualTo: alertId)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) _decodeLocationShare(doc),
          ].whereType<LocationShare>().toList(growable: false),
        );
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

/// Un document illisible ne doit pas faire tomber la liste entière: la victime
/// voit les autres intervenants plutôt que rien du tout.
///
/// freezed lève `CheckedFromJsonException` sur un champ manquant, d'où le
/// `Object` — un `FormatException` ne suffirait pas.
HelpResponse? _decodeHelpResponse(DocumentSnapshot<Map<String, dynamic>> doc) {
  try {
    return HelpResponse.fromJson({...?doc.data(), 'id': doc.id});
  } on Object catch (e) {
    Log.warning('Suivi intervenant ignoré (${doc.id}): $e');
    return null;
  }
}

LocationShare? _decodeLocationShare(DocumentSnapshot<Map<String, dynamic>> doc) {
  try {
    return LocationShare.fromJson({...?doc.data(), 'id': doc.id});
  } on Object catch (e) {
    Log.warning('Position intervenant ignorée (${doc.id}): $e');
    return null;
  }
}

/// Statut brut d'un suivi existant, sans passer par le désérialiseur complet:
/// `createdAt` peut manquer sur un document écrit par une version antérieure,
/// et ici seule la comparaison au statut `cancelled` compte.
HelpResponseStatus? _statusOf(Map<String, dynamic>? json) {
  final raw = json?['status'];
  if (raw is! String) return null;
  for (final status in HelpResponseStatus.values) {
    if (status.name == raw) return status;
  }
  return null;
}