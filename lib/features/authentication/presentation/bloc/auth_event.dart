import 'package:equatable/equatable.dart';
import '../../domain/entities/pairing_info.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthPairDeviceRequested extends AuthEvent {
  final PairingInfo pairingInfo;

  const AuthPairDeviceRequested(this.pairingInfo);

  @override
  List<Object?> get props => [pairingInfo];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthDeviceNameChanged extends AuthEvent {
  final String name;

  const AuthDeviceNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}
