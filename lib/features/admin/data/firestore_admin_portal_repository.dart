import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';
import 'package:salus/features/admin/domain/models/admin_zone_point.dart';

class FirestoreAdminPortalRepository implements AdminPortalRepository {
  FirestoreAdminPortalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<AdminPortalUser?> watchUser(String uid) =>
      _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        final roles = (data['roles'] as List<dynamic>? ?? const [])
            .map((role) => role.toString().split('.').last)
            .toSet();
        return AdminPortalUser(
          uid: uid,
          roles: roles,
          isActive: data['isActive'] != false,
          organizationId: data['organizationId'] as String?,
          displayName: data['displayName']?.toString(),
          email: data['email']?.toString(),
        );
      });

  @override
  Stream<List<AdminPortalRecord>> watchCollection(AdminCollection collection) =>
      _firestore
          .collection(collection.firestoreName)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => _recordFromMap(doc.id, doc.data()))
                .toList(),
          );

  @override
  Future<Map<AdminCollection, List<AdminPortalRecord>>> loadDashboardRecords({
    required bool admin,
  }) async {
    final collections = admin
        ? const [
            AdminCollection.sosAlerts,
            AdminCollection.organizations,
            AdminCollection.shelters,
            AdminCollection.users,
            AdminCollection.reports,
          ]
        : const [
            AdminCollection.sosAlerts,
            AdminCollection.reports,
            AdminCollection.zones,
          ];
    final snapshots = await Future.wait(
      collections.map(
        (collection) => _firestore.collection(collection.firestoreName).get(),
      ),
    );
    return {
      for (var i = 0; i < collections.length; i++)
        collections[i]: snapshots[i].docs
            .map((doc) => _recordFromMap(doc.id, doc.data()))
            .toList(),
    };
  }

  AdminPortalRecord _recordFromMap(String id, Map<String, dynamic> data) =>
      AdminPortalRecord(
        id: id,
        name: data['name']?.toString(),
        displayName: data['displayName']?.toString(),
        description: data['description']?.toString(),
        email: data['email']?.toString(),
        userId: data['userId']?.toString(),
        responderCount:
            (data['responderIds'] as List<dynamic>?)?.length ??
            _integer(data['respondersCount']) ??
            0,
        roles: (data['roles'] as List<dynamic>? ?? const [])
            .map((role) => role.toString())
            .toList(),
        safetyStatus: data['safetyStatus']?.toString(),
        distressType: data['distressType']?.toString(),
        createdAt: _date(data['createdAt']),
        startedAt: _date(data['startedAt']),
        address: data['address']?.toString(),
        capacityOccupied: _integer(data['capacityOccupied']),
        capacityTotal: _integer(data['capacityTotal']),
        contactEmail: data['contactEmail']?.toString(),
        contactPhone: data['contactPhone']?.toString(),
        type: data['type']?.toString(),
        targetType: data['targetType']?.toString(),
        targetId: data['targetId']?.toString(),
        reporterId: data['reporterId']?.toString(),
        reason: data['reason']?.toString(),
        status: data['status']?.toString(),
        verified: data['verified'] == true,
        verifiedBy: data['verifiedBy']?.toString(),
        verifiedAt: _date(data['verifiedAt']),
        validationStatus: data['validationStatus']?.toString(),
        isActive: data['isActive'] as bool?,
        organizationId: data['organizationId']?.toString(),
        assignedOrganizationId: data['assignedOrganizationId']?.toString(),
        createdBy: data['createdBy']?.toString(),
        source: data['source']?.toString(),
        zoneType: data['type']?.toString(),
        zoneOrigin: data['origin']?.toString(),
        disasterType: data['disasterType']?.toString(),
        severity: data['severity']?.toString(),
        geometry: (data['geometry'] as List<dynamic>? ?? const [])
            .whereType<GeoPoint>()
            .map(
              (point) => AdminZonePoint(
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            )
            .toList(),
      );

  DateTime? _date(Object? value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;

  int? _integer(Object? value) => value is num ? value.toInt() : null;

  @override
  Future<void> verifyOrganization(String id, String uid) =>
      _firestore.collection('organizations').doc(id).update({
        'verified': true,
        'isActive': true,
        'verifiedBy': uid,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> updateSos({
    required String id,
    required String status,
    required String? assignedOrganizationId,
    required String? organizationId,
  }) => _firestore.collection('sos_alerts').doc(id).update({
    'status': status,
    if (status == 'inProgress' &&
        (assignedOrganizationId != null || organizationId != null))
      'assignedOrganizationId': organizationId ?? assignedOrganizationId,
    if (status == 'resolved') 'resolvedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> updateReport({
    required String id,
    required String status,
    required String uid,
  }) => _firestore.collection('reports').doc(id).update({
    'status': status,
    'reviewedBy': uid,
  });

  @override
  Future<void> validateShelter(String id, String uid) => _firestore
      .collection('shelters')
      .doc(id)
      .update({'validationStatus': 'validated', 'validatedBy': uid});

  @override
  Future<void> setShelterValidationStatus(
    String id,
    String status,
    String uid,
  ) => _firestore.collection('shelters').doc(id).update({
    'validationStatus': status,
    'validatedBy': status == 'pending' ? null : uid,
  });

  @override
  Future<void> createShelter({
    required String name,
    required String address,
    required int capacityTotal,
    required double latitude,
    required double longitude,
    required Map<String, bool> resources,
    required String userId,
  }) => _firestore.collection('shelters').add({
    'name': name,
    'location': GeoPoint(latitude, longitude),
    'address': address,
    'capacityTotal': capacityTotal,
    'capacityOccupied': 0,
    'status': 'open',
    'resources': resources,
    'photos': <String>[],
    'createdBy': userId,
    'validationStatus': 'validated',
    'validatedBy': userId,
    'unsafeReportsCount': 0,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> toggleZone(String id, {required bool isActive}) =>
      _firestore.collection('zones').doc(id).update({
        'isActive': isActive,
        'endedAt': isActive ? null : FieldValue.serverTimestamp(),
      });

  @override
  Future<void> saveManualRiskZone({
    required String? id,
    required String name,
    required String description,
    required String disasterType,
    required String severity,
    required List<AdminZonePoint> geometry,
    required String userId,
    required String? organizationId,
  }) async {
    final collection = _firestore.collection('zones');
    final document = id == null ? collection.doc() : collection.doc(id);
    final values = <String, Object?>{
      'type': 'risk',
      'origin': 'manual',
      'source': name,
      'description': description,
      'disasterType': disasterType,
      'severity': severity,
      'geometry': [
        for (final point in geometry) GeoPoint(point.latitude, point.longitude),
      ],
    };
    if (id == null) {
      await document.set({
        ...values,
        'createdBy': userId,
        'organizationId': organizationId,
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await document.update(values);
    }
  }

  @override
  Future<void> setUserActive(String id, {required bool isActive}) =>
      _firestore.collection('users').doc(id).update({'isActive': isActive});

  @override
  Future<void> assignUserToOrganization(
    String userId,
    String organizationId,
  ) async {
    final userReference = _firestore.collection('users').doc(userId);
    final organizationReference = _firestore
        .collection('organizations')
        .doc(organizationId);
    await _firestore.runTransaction((transaction) async {
      final user = await transaction.get(userReference);
      final organization = await transaction.get(organizationReference);
      final organizationData = organization.data();
      if (!user.exists || !organization.exists || organizationData == null) {
        throw StateError('Compte ou organisation introuvable.');
      }
      if (organizationData['verified'] != true ||
          organizationData['isActive'] != true) {
        throw StateError('L’organisation doit être vérifiée et active.');
      }
      final roles =
          (user.data()?['roles'] as List<dynamic>? ?? const [])
              .map((role) => role.toString())
              .where((role) => role != 'shelterManager')
              .toSet()
            ..add('organizationMember');
      transaction.update(userReference, {
        'roles': roles.toList(),
        'organizationId': organizationId,
      });
    });
  }

  @override
  Future<void> removeUserOrganizationRole(String userId) async {
    final userReference = _firestore.collection('users').doc(userId);
    final user = await userReference.get();
    if (!user.exists) throw StateError('Compte introuvable.');
    final roles = (user.data()?['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString())
        .where(
          (role) => role != 'organizationMember' && role != 'shelterManager',
        )
        .toList();
    await userReference.update({
      'roles': roles,
      'organizationId': FieldValue.delete(),
    });
  }

  @override
  Future<void> createOrganization({
    required String name,
    required String type,
    required String email,
    required String phone,
  }) => _firestore.collection('organizations').add({
    'name': name,
    'type': type,
    'verified': false,
    'isActive': true,
    'contactEmail': email,
    'contactPhone': phone,
    'createdAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> updateOrganization({
    required String id,
    required String name,
    required String type,
    required String email,
    required String phone,
  }) => _firestore.collection('organizations').doc(id).update({
    'name': name,
    'type': type,
    'contactEmail': email,
    'contactPhone': phone,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> setOrganizationActive(String id, {required bool isActive}) =>
      _firestore.collection('organizations').doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
