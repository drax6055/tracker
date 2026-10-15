import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/accounts/presentation/screens/add_account_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/verify_otp_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/main_shell_screen.dart';
import '../features/debts/presentation/screens/add_debt_screen.dart';
import '../features/debts/presentation/screens/debts_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Splash & Auth routes
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return VerifyOtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return ResetPasswordScreen(
          email: data['email'] ?? '',
          resetToken: data['resetToken'] ?? '',
        );
      },
    ),

    // Main App Shell with Bottom Tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 2: Accounts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              builder: (context, state) => const AccountsScreen(),
            ),
          ],
        ),
        // Tab 3: Transactions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ],
        ),
        // Tab 4: Debts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/debts',
              builder: (context, state) => const DebtsScreen(),
            ),
          ],
        ),
        // Tab 5: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Modal / Sub screens
    GoRoute(
      path: '/add-account',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddAccountScreen(),
    ),
    GoRoute(
      path: '/add-transaction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/add-debt',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddDebtScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
