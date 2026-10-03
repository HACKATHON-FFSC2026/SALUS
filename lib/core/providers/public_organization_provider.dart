import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/sources/firestore_client.dart';

/// Nom affichable d'une organisation publiquement vérifiée et active.
final publicOrganizationNameProvider = StreamProvider.family<String?, String>(
  (ref, organizationId) => ref
      .watch(firestoreProvider)
      .collection('organizations')
      .doc(organizationId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists ||
            data == null ||
            data['verified'] != true ||
            data['isActive'] != true) {
          return null;
        }
        return data['name']?.toString();
      }),
);
