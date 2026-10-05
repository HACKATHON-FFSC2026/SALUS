import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/sos/domain/entities/emergency_numbers.dart';

void main() {
  group('EmergencyNumbers.forCountryCode', () {
    test('résout Madagascar en 117/118', () {
      final numbers = EmergencyNumbers.forCountryCode('MG');
      expect(numbers?.police, '117');
      expect(numbers?.fire, '118');
    });

    test('résout la Réunion et ignore la casse', () {
      final numbers = EmergencyNumbers.forCountryCode('re');
      expect(numbers?.police, '17');
      expect(numbers?.ambulance, '15');
    });

    test('renvoie null pour un pays inconnu, pour laisser choisir un repli', () {
      expect(EmergencyNumbers.forCountryCode('US'), isNull);
      expect(EmergencyNumbers.forCountryCode(null), isNull);
    });
  });

  group('labelledEntries', () {
    test('Madagascar expose police, pompiers et le 112 universel', () {
      final labels = EmergencyNumbers.forCountryCode('MG')!.labelledEntries;
      expect(labels, hasLength(3));
      expect(labels.map((entry) => entry.$2), contains(EmergencyNumbers.universal));
    });

    test('France ajoute le 112 aux trois numéros nationaux', () {
      final labels = EmergencyNumbers.forCountry('France').labelledEntries;
      expect(labels, hasLength(4));
      expect(
        labels.map((entry) => entry.$2),
        containsAll(<String>['17', '18', '15', EmergencyNumbers.universal]),
      );
    });

    test('ne duplique pas le 112 quand le repli l’utilise déjà', () {
      final labels = EmergencyNumbers.forCountry(null).labelledEntries;
      expect(labels, hasLength(2));
      expect(labels.every((entry) => entry.$2 == EmergencyNumbers.universal), isTrue);
    });
  });
}
