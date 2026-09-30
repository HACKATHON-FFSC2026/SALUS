import 'package:salus/features/admin/domain/models/admin_collection.dart';

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.activeSos,
    required this.organizations,
    required this.shelters,
    required this.users,
    required this.openReports,
    required this.activeZones,
  });

  final int activeSos;
  final int organizations;
  final int shelters;
  final int users;
  final int openReports;
  final int activeZones;

  int forCollection(AdminCollection collection) => switch (collection) {
    AdminCollection.sosAlerts => activeSos,
    AdminCollection.organizations => organizations,
    AdminCollection.shelters => shelters,
    AdminCollection.users => users,
    AdminCollection.reports => openReports,
    AdminCollection.zones => activeZones,
  };
}
