import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

class LoginResult {
  final bool success;
  final bool hasActiveSession;
  final String? activeDevice;
  final String? errorMessage;

  const LoginResult({
    required this.success,
    this.hasActiveSession = false,
    this.activeDevice,
    this.errorMessage,
  });
}

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  Timer? _sessionPollTimer;

  @override
  AuthState build() {
    ref.onDispose(() {
      _stopSessionPolling();
    });

    ApiClient.onSessionRevoked = () {
      _stopSessionPolling();
      state = const AuthState(
        isAuthenticated: false,
        errorMessage: 'Account was logged in from another device. Please log in again.',
      );
    };
    Future.microtask(() => checkInitialAuth());
    return const AuthState(isLoading: true);
  }

  void _startSessionPolling() {
    _sessionPollTimer?.cancel();
    // Poll every 8 seconds to instantly detect logins from another device
    _sessionPollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!state.isAuthenticated) {
        _stopSessionPolling();
        return;
      }
      try {
        await _repo.getMe();
      } catch (_) {
        // ApiClient interceptor catches 401 SESSION_REVOKED and calls onSessionRevoked
      }
    });
  }

  void _stopSessionPolling() {
    _sessionPollTimer?.cancel();
    _sessionPollTimer = null;
  }

  Future<void> checkInitialAuth() async {
    state = state.copyWith(isLoading: true);
    final token = await SecureStorageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      final cachedUser = await SecureStorageService.getUser();
      UserModel? user = cachedUser != null ? UserModel.fromJson(cachedUser) : null;

      try {
        final freshUser = await _repo.getMe();
        if (freshUser != null) {
          user = freshUser;
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          _startSessionPolling();
          return;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.code == 'SESSION_REVOKED') {
          await SecureStorageService.clearAll();
          state = const AuthState(
            user: null,
            isAuthenticated: false,
            isLoading: false,
            errorMessage: 'Account was logged in from another device. Please log in again.',
          );
          return;
        }
      } catch (_) {
        // Offline network error: allow cached user only if demo or valid
      }

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      _startSessionPolling();
    } else {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  Future<LoginResult> login(String email, String password, {bool force = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.login(email: email, password: password, force: force);
      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );
      _startSessionPolling();
      return const LoginResult(success: true);
    } on ApiException catch (e) {
      final hasActiveSession = e.code == 'ACTIVE_SESSION_EXISTS';
      final activeDevice = e.data is Map ? e.data['activeDevice']?.toString() : null;

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return LoginResult(
        success: false,
        hasActiveSession: hasActiveSession,
        activeDevice: activeDevice,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
      return const LoginResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );
      _startSessionPolling();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred');
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final msg = await _repo.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return msg;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    }
  }

  Future<String?> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resetToken = await _repo.verifyOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return resetToken;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.resetPassword(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    _stopSessionPolling();
    await _repo.logout();
    state = const AuthState(isAuthenticated: false);
  }

  Future<void> terminateAccountAndPurgeData() async {
    _stopSessionPolling();
    state = state.copyWith(isLoading: true);
    await _repo.terminateAccountAndPurgeData();
    state = const AuthState(isAuthenticated: false);
  }
}
