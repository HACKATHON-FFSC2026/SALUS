import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/auth/presentation/providers/auth_provider.dart';
import 'package:salus/features/reports/domain/models/road_incident.dart';
import 'package:salus/features/reports/domain/submit_report_use_case.dart';

final submitReportUseCaseProvider = Provider<SubmitReportUseCase>(
  (ref) => SubmitReportUseCase(ref.watch(reportRepositoryProvider)),
);

final myRoadIncidentsProvider = StreamProvider<List<RoadIncident>>((ref) {
  final reporterId = ref.watch(currentUidProvider);
  if (reporterId == null) return const Stream.empty();
  return ref.watch(reportRepositoryProvider).watchMyRoadIncidents(reporterId);
});
