import 'package:equatable/equatable.dart';
import '../../../../core/network/socket_service.dart';

abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectionStatusUpdated extends ConnectionEvent {
  final ConnectionStatus status;

  const ConnectionStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class ConnectionReconnectRequested extends ConnectionEvent {}

class ConnectionDisconnectRequested extends ConnectionEvent {}
