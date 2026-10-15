import 'user_model.dart';

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;
    final tokens = json['tokens'] as Map<String, dynamic>;

    return AuthResponse(
      user: UserModel.fromJson(userData),
      accessToken: tokens['accessToken'] ?? '',
      refreshToken: tokens['refreshToken'] ?? '',
    );
  }
}
