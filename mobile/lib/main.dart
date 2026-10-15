import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/reminder_notification_service.dart';
import 'core/theme/brutal_theme.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderNotificationService().initialize();
  runApp(
    const ProviderScope(
      child: LedgerApp(),
    ),
  );
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
    );
  }
}
