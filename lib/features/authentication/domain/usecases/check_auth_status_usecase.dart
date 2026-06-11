import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repository;

  CheckAuthStatusUseCase(this._repository);

  Future<Either<Failure, bool>> call() {
    return _repository.checkAuthStatus();
  }
}
