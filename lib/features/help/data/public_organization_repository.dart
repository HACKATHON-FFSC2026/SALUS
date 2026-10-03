import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salus/features/help/domain/entities/public_organization.dart';

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
              .map(
                (document) => PublicOrganization(
                  id: document.id,
                  name: document.data()['name']?.toString() ?? 'Organisation',
                  type: document.data()['type']?.toString() ?? 'other',
                  email: document.data()['contactEmail']?.toString(),
                  phone: document.data()['contactPhone']?.toString(),
                ),
              )
              .toList();
          organizations.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return organizations;
        });
  }
}
