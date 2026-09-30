import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/map/data/geocoding_service.dart';

void main() {
  test('parseSearchResults ne garde que les entrées exploitables', () {
    final results = GeocodingService.parseSearchResults([
      {
        'display_name': 'Mahamasina, Antananarivo, Madagascar',
        'lat': '-18.9136',
        'lon': '47.5233',
      },
      {'display_name': 'Entrée sans coordonnées'},
      'entrée invalide',
      {
        'display_name': 'Analakely, Antananarivo, Madagascar',
        'lat': -18.9,
        'lon': 47.5,
      },
    ]);

    expect(results, hasLength(2));
    expect(results.first.label, 'Mahamasina, Antananarivo, Madagascar');
    expect(results.first.latitude, closeTo(-18.9136, 0.0001));
    expect(results.first.longitude, closeTo(47.5233, 0.0001));
    expect(results.last.point.latitude, closeTo(-18.9, 0.0001));
  });

  test('parseReverseLabel renvoie l\'adresse lisible ou null', () {
    expect(
      GeocodingService.parseReverseLabel({
        'display_name': 'Antananarivo, Madagascar',
      }),
      'Antananarivo, Madagascar',
    );
    expect(
      GeocodingService.parseReverseLabel({'error': 'Unable to geocode'}),
      isNull,
    );
    expect(GeocodingService.parseReverseLabel(null), isNull);
  });
}
