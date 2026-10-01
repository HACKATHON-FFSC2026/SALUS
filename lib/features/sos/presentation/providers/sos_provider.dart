import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salus/core/entities/sos_alert_entity.dart';
import '../../data/repositories/sos_repository_impl.dart';
import '../../domain/usecases/send_sos_usecase.dart';

enum SosStatus { initial, loading, success, error }

class SosState {
  final SosStatus status;
  final String? errorMessage;

  const SosState({
    this.status = SosStatus.initial,
    this.errorMessage,
  });

  SosState copyWith({SosStatus? status, String? errorMessage}) {
    return SosState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final sendSosUseCaseProvider = Provider<SendSosUseCase>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return SendSosUseCase(repository);
});

final sosControllerProvider = NotifierProvider<SosController, SosState>(SosController.new);

class SosController extends Notifier<SosState> {
  @override
  SosState build() {
    return const SosState();
  }

  Future<void> triggerSos({
    DistressType distressType = DistressType.other,
    String? description,
  }) async {
    state = state.copyWith(status: SosStatus.loading);
    try {
      final sendSosUseCase = ref.read(sendSosUseCaseProvider);
      await sendSosUseCase.execute(
        distressType: distressType,
        description: description,
      );
      state = state.copyWith(status: SosStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: SosStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const SosState();
  }
}