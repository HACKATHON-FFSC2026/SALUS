import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/map/domain/location.dart';
import 'package:salus/features/map/domain/location_repository.dart';
import 'package:salus/features/map/presentation/providers/location_provider.dart';
import 'package:salus/features/map/presentation/state/location_state.dart';

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this.result);

  Future<GeoPoint> Function() result;
  int openSettingsCalls = 0;

  @override
  Future<GeoPoint> currentPosition() => result();

  @override
  Future<void> openAppSettings() async => openSettingsCalls++;

  @override
  Future<void> openLocationSettings() async => openSettingsCalls++;
}

void main() {
  group('LocationState.copyWith', () {
    const state = LocationState(
      status: LocationStatus.error,
      position: GeoPoint(latitude: 1, longitude: 2),
      errorMessage: 'boom',
    );

    test('omitted fields are kept', () {
      final next = state.copyWith(status: LocationStatus.loading);
      expect(next.status, LocationStatus.loading);
      expect(next.position, const GeoPoint(latitude: 1, longitude: 2));
      expect(next.errorMessage, 'boom');
    });

    test('explicit null clears the field', () {
      // Régression: `errorMessage ?? this.errorMessage` conservait
      // l'erreur après un succès, le message restait affiché.
      final next = state.copyWith(
        status: LocationStatus.success,
        errorMessage: null,
      );
      expect(next.errorMessage, isNull);
    });

    test('explicit null clears the position', () {
      expect(state.copyWith(position: null).position, isNull);
    });
  });

  test('GeoPoint compares by value', () {
    expect(
      const GeoPoint(latitude: -18.8792, longitude: 47.5079),
      const GeoPoint(latitude: -18.8792, longitude: 47.5079),
    );
    expect(
      const GeoPoint(latitude: 1, longitude: 2).hashCode,
      const GeoPoint(latitude: 1, longitude: 2).hashCode,
    );
    expect(
      const GeoPoint(latitude: 1, longitude: 2),
      isNot(const GeoPoint(latitude: 1, longitude: 3)),
    );
  });

  group('LocationNotifier', () {
    Future<LocationState> run(Future<GeoPoint> Function() result) {
      final container = ProviderContainer(
        overrides: [
          locationRepositoryProvider.overrideWithValue(
            _FakeLocationRepository(result),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container
          .read(locationProvider.notifier)
          .refresh()
          .then((_) => container.read(locationProvider));
    }

    test('publishes the position on success', () async {
      final state = await run(
        () async => const GeoPoint(latitude: -18.9, longitude: 47.5),
      );
      expect(state.status, LocationStatus.success);
      expect(state.position, const GeoPoint(latitude: -18.9, longitude: 47.5));
      expect(state.errorMessage, isNull);
    });

    test('maps a disabled service to its own status', () async {
      final state = await run(
        () async => throw const LocationFailureException(
          LocationFailure.serviceDisabled,
        ),
      );
      expect(state.status, LocationStatus.serviceDisabled);
      expect(state.position, isNull);
      expect(state.errorMessage, contains('GPS'));
    });

    test('maps a permanent denial to permissionDenied', () async {
      final state = await run(
        () async => throw const LocationFailureException(
          LocationFailure.permissionDeniedForever,
        ),
      );
      expect(state.status, LocationStatus.permissionDenied);
      expect(state.errorMessage, contains('bloquées'));
    });

    test('an unexpected error is not fatal', () async {
      final state = await run(() async => throw Exception('geolocator boom'));
      expect(state.status, LocationStatus.error);
      expect(state.errorMessage, contains('geolocator boom'));
    });

    test('a retry after a failure clears the stale error', () async {
      final fake = _FakeLocationRepository(
        () async =>
            throw const LocationFailureException(LocationFailure.serviceDisabled),
      );
      final container = ProviderContainer(
        overrides: [locationRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container
          .read(locationProvider.notifier)
          .refresh();
      expect(
        container.read(locationProvider).errorMessage,
        isNotNull,
      );

      // Le repository se rétablit: la seconde fixation doit repartir propre.
      fake.result =
          () async => const GeoPoint(latitude: -18.9, longitude: 47.5);
      await container
          .read(locationProvider.notifier)
          .refresh();

      final state = container.read(locationProvider);
      expect(state.status, LocationStatus.success);
      expect(state.errorMessage, isNull);
    });
  });
}
