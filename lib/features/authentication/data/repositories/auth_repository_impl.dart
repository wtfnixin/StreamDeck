import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/pairing_info.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SecureStorage _storage;
  final SocketService _socketService;

  AuthRepositoryImpl(this._storage, this._socketService);

  @override
  Future<Either<Failure, String>> pairDevice(PairingInfo pairingInfo) async {
    final completer = Completer<Either<Failure, String>>();
    final url = 'http://${pairingInfo.host}:${pairingInfo.port}';
    final deviceId = _storage.getDeviceId() ?? 'unknown_device';
    final deviceName = _storage.getDeviceName();

    AppLogger.info('Initiating pairing with agent at $url...');

    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .enableForceNew()
        .build();

    final tempSocket = io.io(url, options);

    // Timeout mechanism
    final timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        tempSocket.disconnect();
        tempSocket.dispose();
        completer.complete(const Left(PairingFailure('Connection timeout. Ensure PC agent is running and on the same network.')));
      }
    });

    tempSocket.onConnect((_) {
      AppLogger.info('Temp socket connected. Sending pairing request...');
      
      tempSocket.emit('pairing:request', {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'pairingToken': pairingInfo.token,
      });
    });

    tempSocket.on('pairing:response', (data) async {
      timeoutTimer.cancel();
      
      if (!completer.isCompleted) {
        if (data is Map && data['success'] == true) {
          final token = data['token'] as String;
          
          // Save credentials to local storage
          await _storage.savePairingData(
            host: pairingInfo.host,
            port: pairingInfo.port,
            token: token,
          );

          // Connect main SocketService
          _socketService.connect(
            customHost: pairingInfo.host,
            customPort: pairingInfo.port,
            token: token,
          );

          completer.complete(Right(token));
        } else {
          final errorMsg = (data is Map) ? data['error'] as String? ?? 'Pairing rejected' : 'Pairing failed';
          completer.complete(Left(PairingFailure(errorMsg)));
        }
        
        tempSocket.disconnect();
        tempSocket.dispose();
      }
    });

    tempSocket.onConnectError((err) {
      timeoutTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(Left(PairingFailure('Connection error: $err')));
        tempSocket.disconnect();
        tempSocket.dispose();
      }
    });

    tempSocket.connect();

    return completer.future;
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final isPaired = _storage.isPaired();
      if (isPaired && !_socketService.isConnected) {
        // Automatically trigger connection if paired
        _socketService.connect();
      }
      return Right(isPaired);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      _socketService.disconnect();
      await _storage.clearPairingData();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
