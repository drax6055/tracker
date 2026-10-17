import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/security/privacy_curtain.dart';
import 'core/services/ad_service.dart';
import 'core/services/reminder_notification_service.dart';
import 'core/theme/brutal_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };

  // Launch UI immediately so the app opens instantly
  runApp(
    const ProviderScope(
      child: LedgerApp(),
    ),
  );

  // Initialize native background services safely without blocking app launch
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  try {
    await ReminderNotificationService().initialize();
  } catch (e, stack) {
    debugPrint('[Startup] ReminderNotificationService init error: $e\n$stack');
  }

  try {
    await AdService.instance.initialize();
  } catch (e, stack) {
    debugPrint('[Startup] AdService init error: $e\n$stack');
  }
}

class LedgerApp extends ConsumerWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'LEDGER',
      debugShowCheckedModeBanner: false,
      theme: BrutalTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return PrivacyCurtain(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
