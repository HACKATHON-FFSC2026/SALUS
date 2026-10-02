import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:salus/core/entities/sos_alert_entity.dart';

abstract class ISosRemoteDataSource {
  Future<void> createSosAlert({
    required double latitude,
    required double longitude,
    DistressType distressType = DistressType.other,
    String? description,
  });

  Future<void> cancelSosAlert(String alertId);

  Future<void> respondToSos(String alertId);

  Stream<List<SOSAlert>> watchActiveSosAlerts();
}

class SosRemoteDataSourceImpl implements ISosRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SosRemoteDataSourceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Convertit les coordonnées GPS en nom de lieu lisible (en lettres)
  Future<String> _getReadableLocationName(double lat, double lng) async {
    // 1. Essayer d'abord d'obtenir les vraies infos via l'API Nominatim (OpenStreetMap)
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=fr',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'SalusApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final suburb =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['quarter'] ??
              '';
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              address['state'] ??
              '';

          if (suburb.isNotEmpty && city.isNotEmpty && suburb != city) {
            return '$suburb, $city';
          } else if (suburb.isNotEmpty) {
            return suburb;
          } else if (city.isNotEmpty) {
            return city;
          }
        }
      }
    } catch (_) {
      // Si la requête HTTP échoue, passer au plugin natif
    }

    // 2. Essayer via le package geocoding natif
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.subLocality ?? place.locality ?? '';
        final cityRegion = place.locality ?? place.administrativeArea ?? '';

        final fullLocation = locality == cityRegion
            ? locality
            : '$locality, $cityRegion'.trim();

        if (fullLocation.replaceAll(',', '').trim().isNotEmpty) {
          return fullLocation;
        }
      }
    } catch (_) {}

    // 3. Si aucun résultat alphabétique n'est trouvé, retourner les coordonnées formatées
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
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

    // 1. Obtenir le vrai nom du lieu sous forme de texte (ex: "Analakely, Antananarivo")
    final String locationName = await _getReadableLocationName(
      latitude,
      longitude,
    );

    // 2. Obtenir le contact de l'utilisateur
    String userContact = currentUser.phoneNumber ?? '';
    if (userContact.isEmpty) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          userContact =
              userDoc.data()?['contact'] ??
              userDoc.data()?['phone'] ??
              userDoc.data()?['phoneNumber'] ??
              'Non renseigné';
        }
      } catch (_) {
        userContact = 'Non renseigné';
      }
    }

    final docRef = _firestore.collection('SOS_alertes').doc();

    final sosAlertData = <String, dynamic>{
      'id': docRef.id,
      'userId': currentUser.uid,
      'userEmail': currentUser.email ?? '',
      'userContact': userContact,
      'location': GeoPoint(latitude, longitude),
      'locationName': locationName,
      'distressType': distressType.name,
      'description': description,
      'status': SOSStatus.waiting.name,
      'respondersCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(sosAlertData);
  }

  @override
  Future<void> cancelSosAlert(String alertId) {
    return _firestore.collection('SOS_alertes').doc(alertId).update({
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
              .map((doc) => SOSAlert.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          alerts.sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
          return alerts;
        });
  }
}
