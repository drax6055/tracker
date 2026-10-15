import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../security/crypto_service.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Encrypt request body for POST/PUT/PATCH/DELETE
          if (options.data != null &&
              (options.data is Map || options.data is List) &&
              options.data is! FormData) {
            options.data = CryptoService().encryptPayload(options.data);
            options.headers['x-encrypted-payload'] = 'true';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Transparently decrypt encrypted response payload
          if (response.data is Map && response.data['_encrypted'] == true) {
            response.data = CryptoService().decryptPayload(response.data);
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Decrypt error body if encrypted
          if (error.response?.data is Map && error.response?.data['_encrypted'] == true) {
            error.response?.data = CryptoService().decryptPayload(error.response?.data);
          }

          // Auto-refresh token on 401 Unauthorized
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry original request with new token
              final token = await SecureStorageService.getAccessToken();
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';

              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(error);
              }
            } else {
              // Refresh failed, clear session
              await SecureStorageService.clearAll();
            }
          }

          // Format error message
          final message = _extractErrorMessage(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                message: message,
                statusCode: error.response?.statusCode,
                errors: error.response?.data?['errors'],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final tokens = data['tokens'];
        final newAccessToken = tokens['accessToken'];
        final newRefreshToken = tokens['refreshToken'];

        if (newAccessToken != null) {
          await SecureStorageService.saveAccessToken(newAccessToken);
        }
        if (newRefreshToken != null) {
          await SecureStorageService.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _extractErrorMessage(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response!.data as Map;
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet or server.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the backend server.';
    }
    return error.message ?? 'An unexpected network error occurred.';
  }
}
