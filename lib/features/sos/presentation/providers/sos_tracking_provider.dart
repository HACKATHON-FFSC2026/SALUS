import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../../data/repositories/sos_repository_impl.dart';
import '../../domain/usecases/watch_sos_usecase.dart';

final watchSosUseCaseProvider = Provider<WatchSosUseCase>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return WatchSosUseCase(repository);
});

final sosTrackingStreamProvider = StreamProvider.family<SOSAlert?, String>((ref, alertId) {
  final watchSosUseCase = ref.watch(watchSosUseCaseProvider);
  return watchSosUseCase.execute(alertId);
});