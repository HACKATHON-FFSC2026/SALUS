import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/sources/firestore_client.dart';

class PublicOrganization {
  const PublicOrganization({
    required this.id,
    required this.name,
    required this.type,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String type;
  final String? email;
  final String? phone;

  factory PublicOrganization.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return PublicOrganization(
      id: document.id,
      name: data['name']?.toString() ?? 'Organisation',
      type: data['type']?.toString() ?? 'other',
      email: data['contactEmail']?.toString(),
      phone: data['contactPhone']?.toString(),
    );
  }
}

class PublicOrganizationRepository {
  const PublicOrganizationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<PublicOrganization>> watchOrganizations() {
    var receivedFirstSnapshot = false;
    var timeoutReported = false;
    return _firestore
        .collection('organizations')
        .where('verified', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: (sink) {
            if (!receivedFirstSnapshot && !timeoutReported) {
              timeoutReported = true;
              sink.addError(
                TimeoutException('Le chargement des organisations a expiré.'),
              );
            }
          },
        )
        .map((snapshot) {
          receivedFirstSnapshot = true;
          final organizations = snapshot.docs
              .map(PublicOrganization.fromDocument)
              .toList();
          organizations.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return organizations;
        });
  }
}

final publicOrganizationRepositoryProvider =
    Provider<PublicOrganizationRepository>(
      (ref) => PublicOrganizationRepository(ref.watch(firestoreProvider)),
    );

final publicOrganizationsProvider = StreamProvider<List<PublicOrganization>>(
  (ref) => ref.watch(publicOrganizationRepositoryProvider).watchOrganizations(),
);
