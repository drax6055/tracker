import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../storage/secure_storage_service.dart';

/// Service responsible for managing daily ledger entry reminders.
/// Uses native OS AlarmManager (Android) and UNCalendarNotificationTrigger (iOS)
/// so notifications fire reliably even when the application is COMPLETELY CLOSED or killed.
class ReminderNotificationService {
  static final ReminderNotificationService _instance = ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  static const int reminderNotificationId = 888;
  static const String channelId = 'daily_ledger_reminders';
  static const String channelName = 'Daily Ledger Reminders';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Timer? _webTimerFallback;

  /// Initialize native notification channels and permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database for exact local schedule calculations
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            print('[NotificationService] Notification tapped: ${response.payload}');
          }
        },
      );

      // 3. Request runtime notification permissions (Android 13+ and iOS)
      await requestPermissions();

      _isInitialized = true;

      // 4. Check if daily reminders are enabled in user preferences and schedule
      final enabled = await SecureStorageService.getReminderEnabled();
      if (enabled) {
        final time = await SecureStorageService.getReminderTime();
        final hour = time['hour'] ?? 21;
        final minute = time['minute'] ?? 0;
        await scheduleDailyReminder(hour, minute);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Initialization error (continuing with fallback): $e');
      }
    }
  }

  /// Request permissions for alerts & exact alarms
  Future<void> requestPermissions() async {
    try {
      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();

        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Permission request warning: $e');
      }
    }
  }

  /// Schedule daily repeating reminder at [hour]:[minute].
  /// On Android/iOS, this registers a native system alarm (`RTC_WAKEUP`)
  /// which wakes the OS and shows the notification even if the app is killed.
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await initialize();

    // Cancel any previous scheduled notification
    await cancelDailyReminder();

    try {
      if (!kIsWeb) {
        final scheduledDate = _nextInstanceOfTime(hour, minute);

        const notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Daily alarms to record cash flow and reconcile ledger entries',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        // Native exact background schedule repeating every day at the given time
        await _notificationsPlugin.zonedSchedule(
          id: reminderNotificationId,
          title: 'DAILY LEDGER CHECK-IN',
          body: 'Don\'t forget to record today\'s transactions and balance your accounts.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        if (kDebugMode) {
          print('[NotificationService] Native OS Alarm registered for $hour:${minute.toString().padLeft(2, '0')} daily (repeats even when app is closed).');
        }
      } else {
        // Web fallback timer
        final now = DateTime.now();
        var target = DateTime(now.year, now.month, now.day, hour, minute);
        if (target.isBefore(now)) {
          target = target.add(const Duration(days: 1));
        }
        final diff = target.difference(now);
        _webTimerFallback = Timer(diff, () {
          triggerImmediateTestReminder();
          scheduleDailyReminder(hour, minute);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Failed to schedule native notification: $e');
      }
    }
  }

  /// Cancel all scheduled daily reminders from the native OS AlarmManager
  Future<void> cancelDailyReminder() async {
    _webTimerFallback?.cancel();
    _webTimerFallback = null;

    try {
      await _notificationsPlugin.cancel(id: reminderNotificationId);
      if (kDebugMode) {
        print('[NotificationService] Native OS alarms cancelled.');
      }
    } catch (_) {}
  }

  /// Trigger immediate demonstration notification into system tray
  Future<void> triggerImmediateTestReminder({VoidCallback? onTriggered}) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Daily alarms to record cash flow and reconcile ledger entries',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notificationsPlugin.show(
        id: 999,
        title: 'LEDGER CHECK-IN (TEST)',
        body: 'Your daily reminder alert is active! You will be alerted at your scheduled time even if the app is closed.',
        notificationDetails: details,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Immediate notification trigger error: $e');
      }
    }

    onTriggered?.call();
  }

  /// Calculate the next instance of [hour]:[minute] in the local timezone
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.Location location = tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
