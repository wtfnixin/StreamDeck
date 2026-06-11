import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class SocketFailure extends Failure {
  const SocketFailure(super.message);
}

class PairingFailure extends Failure {
  const PairingFailure(super.message);
}

abstract class Either<L, R> {
  const Either();
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(value);
}
