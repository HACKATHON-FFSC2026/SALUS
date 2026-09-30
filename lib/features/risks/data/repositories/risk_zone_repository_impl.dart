import 'package:salus/core/entities/zone_entity.dart';
import 'package:salus/features/risks/data/datasources/gdacs_api_service.dart';
import '../../domain/repositories/risk_zone_repository.dart';

class RiskZoneRepositoryImpl implements RiskZoneRepository {
  final GdacsApiService _gdacsApi;

  RiskZoneRepositoryImpl(this._gdacsApi);

  @override
  Future<List<Zone>> getActiveRiskZones() async {
    final zones = await _gdacsApi.fetchPublicRiskZones();
    // Double sécurité : le use case filtre aussi isActive
    return zones.where((z) => z.isActive).toList();
  }
}