import '../../../../core/errors/failures.dart';
import '../entities/pairing_info.dart';

abstract class AuthRepository {
  Future<Either<Failure, String>> pairDevice(PairingInfo pairingInfo);
  Future<Either<Failure, bool>> checkAuthStatus();
  Future<Either<Failure, void>> logout();
}
