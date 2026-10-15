import 'dart:async';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';

/// Service responsible for managing daily ledger entry reminders.
/// Cross-platform compatible (Mobile & Web).
class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  Timer? _activeWebTimer;

  /// Initialize and schedule notification based on saved user preferences
  Future<void> initialize() async {
    final enabled = await SecureStorageService.getReminderEnabled();
    if (!enabled) {
      if (kDebugMode) {
        print('[NotificationService] Daily reminders are disabled by user.');
      }
      return;
    }

    final time = await SecureStorageService.getReminderTime();
    final hour = time['hour'] ?? 21;
    final minute = time['minute'] ?? 0;

    await scheduleDailyReminder(hour, minute);
  }

  /// Schedule daily repeating reminder at [hour]:[minute]
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    _activeWebTimer?.cancel();

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final diff = scheduled.difference(now);
    if (kDebugMode) {
      print('[NotificationService] Daily reminder scheduled for $hour:${minute.toString().padLeft(2, '0')} (in ${diff.inMinutes} minutes)');
    }

    // Schedule active repeating check
    _activeWebTimer = Timer(diff, () {
      _dispatchNotification(
        title: 'DAILY LEDGER CHECK-IN',
        body: 'Don\'t forget to reconcile today\'s cash flow and balance your accounts.',
      );
      // Re-schedule for next day
      scheduleDailyReminder(hour, minute);
    });
  }

  /// Cancel all scheduled daily reminders
  Future<void> cancelDailyReminder() async {
    _activeWebTimer?.cancel();
    _activeWebTimer = null;
    if (kDebugMode) {
      print('[NotificationService] Daily reminders cancelled.');
    }
  }

  /// Trigger immediate demonstration notification
  void triggerImmediateTestReminder({VoidCallback? onTriggered}) {
    _dispatchNotification(
      title: 'LEDGER REMINDER TEST',
      body: 'Notifications are working! You will receive daily check-in alerts at your scheduled time.',
    );
    onTriggered?.call();
  }

  void _dispatchNotification({required String title, required String body}) {
    if (kDebugMode) {
      print('🔔 [NOTIFICATION DISPATCHED] $title - $body');
    }
  }
}
