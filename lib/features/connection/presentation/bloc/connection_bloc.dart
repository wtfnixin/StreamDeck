import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import 'connection_event.dart';
import 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionBlocState> {
  final SocketService _socketService;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  ConnectionBloc(this._socketService) : super(const ConnectionInitial()) {
    on<ConnectionStatusUpdated>((event, emit) {
      emit(ConnectionStatusState(event.status));
    });

    on<ConnectionReconnectRequested>((event, emit) {
      _socketService.connect();
    });

    on<ConnectionDisconnectRequested>((event, emit) {
      _socketService.disconnect();
    });

    // Start listening to the network socket service status changes
    _statusSubscription = _socketService.statusStream.listen((status) {
      add(ConnectionStatusUpdated(status));
    });

    // Seed initial status
    add(ConnectionStatusUpdated(_socketService.currentStatus));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
