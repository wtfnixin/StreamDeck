import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import 'gesture_event.dart';
import 'gesture_state.dart';

class GestureBloc extends Bloc<GestureEvent, GestureState> {
  final SocketService _socketService;

  GestureBloc(this._socketService) : super(GestureInitial()) {
    on<GestureTriggerEvent>(_onTrigger);
  }

  Future<void> _onTrigger(GestureTriggerEvent event, Emitter<GestureState> emit) async {
    emit(GestureTriggering());
    final completer = Completer<GestureState>();

    _socketService.emit('gesture:trigger', {'gestureType': event.gestureType}, ack: (response) {
      if (response is Map && response['success'] == true) {
        completer.complete(GestureTriggerSuccess(event.gestureType));
      } else {
        final error = response is Map ? response['error'] as String? : null;
        completer.complete(GestureTriggerFailure(error ?? 'Failed to trigger gesture on PC'));
      }
    });

    try {
      final state = await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => const GestureTriggerFailure('Request timed out'),
      );
      emit(state);
    } catch (e) {
      emit(GestureTriggerFailure(e.toString()));
    }
  }
}
