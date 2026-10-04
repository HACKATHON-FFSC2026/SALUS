import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/app/di/app_dependencies.dart';
import 'package:salus/features/reports/domain/submit_report_use_case.dart';

final submitReportUseCaseProvider = Provider<SubmitReportUseCase>(
  (ref) => SubmitReportUseCase(ref.watch(reportRepositoryProvider)),
);
