import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/sources/firestore_client.dart';
import 'package:salus/core/sources/remote_client.dart';
import 'package:salus/features/admin/data/firestore_admin_portal_repository.dart';
import 'package:salus/features/admin/domain/admin_portal_repository.dart';
import 'package:salus/features/alerts/data/repositories/alert_read_repository.dart';
import 'package:salus/features/alerts/data/repositories/shared_prefs_alert_read_repository.dart';
import 'package:salus/features/auth/data/firebase_auth_repository.dart';
import 'package:salus/features/auth/domain/auth_repository.dart';
import 'package:salus/features/help/data/public_organization_repository.dart';
import 'package:salus/features/help/domain/entities/public_organization.dart';
import 'package:salus/features/map/data/geocoding_service.dart';
import 'package:salus/features/map/data/geolocator_location_repository.dart';
import 'package:salus/features/map/data/risk_zone_repository.dart';
import 'package:salus/features/map/domain/location_repository.dart';
import 'package:salus/features/risks/data/datasources/elevation_api_service.dart';
import 'package:salus/features/risks/data/datasources/gdacs_api_service.dart';
import 'package:salus/features/risks/data/repositories/risk_zone_repository_impl.dart';
import 'package:salus/features/risks/data/repositories/safe_zone_repository_impl.dart';
import 'package:salus/features/risks/data/services/turf_geofonce_service.dart';
import 'package:salus/features/risks/domain/repositories/risk_zone_repository.dart';
import 'package:salus/features/risks/domain/repositories/safe_zone.dart';
import 'package:salus/features/risks/domain/services/zone_geofence_service.dart';
import 'package:salus/features/reports/data/firestore_report_repository.dart';
import 'package:salus/features/reports/domain/report_repository.dart';
import 'package:salus/features/shelters/data/shelter_repository.dart';
import 'package:salus/features/sos/data/datasources/sos_remote_datasource.dart';
import 'package:salus/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:salus/features/sos/domain/repositories/sos_repository.dart';

/// Application composition root: infrastructure implementations are bound to
/// domain ports here, outside feature presentation code.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const FirebaseAuthRepository(),
);
final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => const GeolocatorLocationRepository(),
);
final shelterRepositoryProvider = Provider<ShelterRepository>(
  (ref) => FirestoreShelterRepository(ref.watch(firestoreProvider)),
);
final sosRemoteDataSourceProvider = Provider<ISosRemoteDataSource>(
  (ref) => SosRemoteDataSourceImpl(),
);
final sosRepositoryProvider = Provider<ISosRepository>(
  (ref) => SosRepositoryImpl(ref.watch(sosRemoteDataSourceProvider)),
);
final alertReadRepositoryProvider = Provider<AlertReadRepository>(
  (ref) => SharedPrefsAlertReadRepository(),
);
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => FirestoreReportRepository(ref.watch(firestoreProvider)),
);
final firestoreRiskZoneRepositoryProvider = Provider<FirestoreRiskZoneRepository>(
  (ref) => FirestoreRiskZoneRepository(ref.watch(firestoreProvider)),
);
final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => GeocodingService(ref.watch(remoteClientProvider)),
);
final dioProvider = Provider<Dio>((ref) => Dio());
final gdacsApiServiceProvider =
    Provider((ref) => GdacsApiService(ref.watch(dioProvider)));
final riskZoneRepositoryProvider = Provider<RiskZoneRepository>(
  (ref) => RiskZoneRepositoryImpl(ref.watch(gdacsApiServiceProvider)),
);
final elevationApiServiceProvider =
    Provider((ref) => ElevationApiService(ref.watch(dioProvider)));
final safeZoneRepositoryProvider = Provider<SafeZoneRepository>(
  (ref) => SafeZoneRepositoryImpl(ref.watch(elevationApiServiceProvider)),
);
final geofenceServiceProvider =
    Provider<ZoneGeofenceService>((ref) => TurfGeofenceService());
final publicOrganizationRepositoryProvider =
    Provider<PublicOrganizationRepository>(
      (ref) => PublicOrganizationRepository(ref.watch(firestoreProvider)),
    );
final publicOrganizationsProvider = StreamProvider<List<PublicOrganization>>(
  (ref) => ref.watch(publicOrganizationRepositoryProvider).watchOrganizations(),
);
final adminPortalRepositoryProvider = Provider<AdminPortalRepository>(
  (ref) => FirestoreAdminPortalRepository(ref.watch(firestoreProvider)),
);
