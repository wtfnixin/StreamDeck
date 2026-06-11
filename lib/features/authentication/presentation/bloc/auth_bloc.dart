import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/pair_device_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatusUseCase checkAuthStatus;
  final PairDeviceUseCase pairDevice;
  final LogoutUseCase logout;
  final SecureStorage secureStorage;

  AuthBloc({
    required this.checkAuthStatus,
    required this.pairDevice,
    required this.logout,
    required this.secureStorage,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthPairDeviceRequested>(_onAuthPairDeviceRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDeviceNameChanged>(_onAuthDeviceNameChanged);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await checkAuthStatus();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (isPaired) {
        if (isPaired) {
          final token = secureStorage.getAuthToken() ?? '';
          emit(AuthAuthenticated(token));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthPairDeviceRequested(
    AuthPairDeviceRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await pairDevice(event.pairingInfo);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (token) => emit(AuthAuthenticated(token)),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await logout();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onAuthDeviceNameChanged(
    AuthDeviceNameChanged event,
    Emitter<AuthState> emit,
  ) async {
    await secureStorage.saveDeviceName(event.name);
  }
}
