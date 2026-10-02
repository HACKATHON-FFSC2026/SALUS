import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';

void main() {
  group('SOSAlert model', () {
    test('reads locationName from JSON payload', () {
      final alert = SOSAlert.fromJson({
        'id': 'abc',
        'userId': 'u1',
        'location': const GeoPoint(12.3, 45.6),
        'locationName': 'Antananarivo',
        'distressType': 'medical',
        'description': 'Besoin d aide',
        'status': 'waiting',
        'respondersCount': 2,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      expect(alert.locationName, 'Antananarivo');
      expect(alert.distressType, DistressType.medical);
      expect(alert.status, SOSStatus.waiting);
    });
  });
}
