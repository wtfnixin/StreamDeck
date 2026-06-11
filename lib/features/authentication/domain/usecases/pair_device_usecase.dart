import '../../../../core/errors/failures.dart';
import '../entities/pairing_info.dart';
import '../repositories/auth_repository.dart';

class PairDeviceUseCase {
  final AuthRepository _repository;

  PairDeviceUseCase(this._repository);

  Future<Either<Failure, String>> call(PairingInfo pairingInfo) {
    return _repository.pairDevice(pairingInfo);
  }
}
