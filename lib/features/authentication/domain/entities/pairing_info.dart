import 'package:equatable/equatable.dart';

class PairingInfo extends Equatable {
  final String host;
  final int port;
  final String token;

  const PairingInfo({
    required this.host,
    required this.port,
    required this.token,
  });

  @override
  List<Object?> get props => [host, port, token];
}
