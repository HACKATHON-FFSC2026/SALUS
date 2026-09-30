import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/admin/domain/models/admin_collection.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/domain/models/admin_portal_user.dart';

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
        roles: (data['roles'] as List<dynamic>? ?? const [])
            .map((role) => role.toString())
            .toList(),
        distressType: data['distressType']?.toString(),
        createdAt: _date(data['createdAt']),
        startedAt: _date(data['startedAt']),
        address: data['address']?.toString(),
        capacityOccupied: _integer(data['capacityOccupied']),
        capacityTotal: _integer(data['capacityTotal']),
        contactEmail: data['contactEmail']?.toString(),
        type: data['type']?.toString(),
        targetType: data['targetType']?.toString(),
        status: data['status']?.toString(),
        verified: data['verified'] == true,
        validationStatus: data['validationStatus']?.toString(),
        isActive: data['isActive'] as bool?,
        organizationId: data['organizationId']?.toString(),
        assignedOrganizationId: data['assignedOrganizationId']?.toString(),
        createdBy: data['createdBy']?.toString(),
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
        'verifiedBy': uid,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> updateSos({
    required String id,
    required String status,
    required String? assignedOrganizationId,
    required String uid,
  }) => _firestore.collection('sos_alerts').doc(id).update({
    'status': status,
    if (status == 'inProgress')
      'assignedOrganizationId': assignedOrganizationId ?? uid,
    if (status == 'resolved') 'resolvedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> validateShelter(String id, String uid) => _firestore
      .collection('shelters')
      .doc(id)
      .update({'validationStatus': 'validated', 'validatedBy': uid});

  @override
  Future<void> toggleZone(String id, {required bool isActive}) =>
      _firestore.collection('zones').doc(id).update({'isActive': isActive});

  @override
  Future<void> setUserActive(String id, {required bool isActive}) =>
      _firestore.collection('users').doc(id).update({'isActive': isActive});

  @override
  Future<void> createOrganization({
    required String name,
    required String email,
    required String phone,
  }) => _firestore.collection('organizations').add({
    'name': name,
    'type': 'ngo',
    'verified': false,
    'contactEmail': email,
    'contactPhone': phone,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
