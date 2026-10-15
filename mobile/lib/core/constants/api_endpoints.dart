import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Can be overridden at build time via --dart-define=API_BASE_URL=https://your-vercel-domain.com/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Machine LAN IP for local device testing over Wi-Fi
  static const String localServerIp = '192.168.29.241';
  static const int port = 5000;

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // When running in production release mode, use the live deployed Vercel backend API
    if (kReleaseMode) {
      return 'https://backend-wheat-ten-3sxqxizgt1.vercel.app/api/v1';
    }

    if (kIsWeb) {
      // For local Flutter web dev
      return 'http://localhost:$port/api/v1';
    }

    // For physical mobile device / emulator
    return 'http://$localServerIp:$port/api/v1';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User
  static const String userMe = '/user/me';

  // Core Money Modules
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String transfers = '/transfers';
  static const String debts = '/debts';
  static const String categories = '/categories';
  static const String budgets = '/budgets';

  // Reports & Dashboard
  static const String dashboard = '/dashboard';
  static const String reportsSummary = '/reports/summary';
  static const String reportsCategoryBreakdown = '/reports/category-breakdown';
  static const String reportsMonthlyTrend = '/reports/monthly-trend';
  static const String reportsNetWorth = '/reports/net-worth';
  static const String reportsExport = '/reports/export';
}
