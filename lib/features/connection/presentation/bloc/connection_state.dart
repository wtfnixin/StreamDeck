import 'package:equatable/equatable.dart';
import '../../../../core/network/socket_service.dart';

abstract class ConnectionBlocState extends Equatable {
  final ConnectionStatus status;

  const ConnectionBlocState(this.status);

  @override
  List<Object?> get props => [status];
}

class ConnectionInitial extends ConnectionBlocState {
  const ConnectionInitial() : super(ConnectionStatus.disconnected);
}

class ConnectionStatusState extends ConnectionBlocState {
  const ConnectionStatusState(super.status);
}
