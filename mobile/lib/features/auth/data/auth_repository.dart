import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'models/auth_response.dart';
import 'models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final deviceId = await SecureStorageService.getDeviceId();
      final deviceName = SecureStorageService.getDeviceName();

      final response = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'device': deviceName,
          'deviceId': deviceId,
        },
      );

      final data = response.data['data'];
      final authResponse = AuthResponse.fromJson(data);

      await SecureStorageService.clearAll();
      await SecureStorageService.saveAccessToken(authResponse.accessToken);
      await SecureStorageService.saveRefreshToken(authResponse.refreshToken);
      await SecureStorageService.saveUser(authResponse.user.toJson());
      await SecureStorageService.saveCurrency(authResponse.user.currency);

      return authResponse;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: 'Registration failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Registration failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    bool force = false,
  }) async {
    try {
      final deviceId = await SecureStorageService.getDeviceId();
      final deviceName = SecureStorageService.getDeviceName();

      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'device': deviceName,
          'deviceId': deviceId,
          'force': force,
        },
      );

      final data = response.data['data'];
      final authResponse = AuthResponse.fromJson(data);

      await SecureStorageService.clearAll();
      await SecureStorageService.saveAccessToken(authResponse.accessToken);
      await SecureStorageService.saveRefreshToken(authResponse.refreshToken);
      await SecureStorageService.saveUser(authResponse.user.toJson());
      await SecureStorageService.saveCurrency(authResponse.user.currency);

      return authResponse;
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: 'Login failed: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Login failed: ${e.toString()}');
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      return response.data['message'] ?? 'OTP sent to your email';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to request password reset OTP');
    }
  }

  Future<String> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );
      final resetToken = response.data['data']?['resetToken'] as String?;
      if (resetToken == null) throw ApiException(message: 'Failed to retrieve reset token');
      return resetToken;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'OTP verification failed');
    }
  }

  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data['message'] ?? 'Password reset successfully';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Password reset failed');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        await _client.dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout, always clear local credentials
    } finally {
      await SecureStorageService.clearAll();
    }
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.userMe);
      final user = response.data['data']?['user'];
      if (user != null) {
        final userModel = UserModel.fromJson(user);
        await SecureStorageService.saveUser(userModel.toJson());
        return userModel;
      }
      return null;
    } catch (_) {
      // If offline, attempt to read stored user
      final cached = await SecureStorageService.getUser();
      if (cached != null) return UserModel.fromJson(cached);
      return null;
    }
  }

  Future<void> terminateAccountAndPurgeData() async {
    try {
      await _client.dio.delete(ApiEndpoints.userMe);
    } catch (_) {
      // Proceed with local wipe even if server error
    } finally {
      await SecureStorageService.clearAll();
    }
  }
}
