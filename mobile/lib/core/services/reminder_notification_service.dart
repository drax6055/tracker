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

  /// Check if notification permissions are actively granted by the OS
  Future<bool> checkPermissionsGranted() async {
    if (kIsWeb) return true;
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Request runtime permissions for alerts & exact alarms
  Future<bool> requestPermissions() async {
    try {
      if (!kIsWeb) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final notifGranted = await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();

        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final iosGranted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

        return (notifGranted ?? true) && (iosGranted ?? true);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Permission request warning: $e');
      }
      return false;
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

  /// Schedule monthly repeating notification for EMI on [dueDay] of month at 9:00 AM
  Future<void> scheduleEmiReminder({
    required int notificationId,
    required String loanTitle,
    required double emiAmount,
    required int dueDay,
    required String currency,
  }) async {
    await initialize();
    try {
      if (!kIsWeb) {
        final now = DateTime.now();
        var scheduledYear = now.year;
        var scheduledMonth = now.month;

        // If today is past dueDay, schedule for next month
        if (now.day > dueDay || (now.day == dueDay && now.hour >= 9)) {
          if (scheduledMonth == 12) {
            scheduledMonth = 1;
            scheduledYear++;
          } else {
            scheduledMonth++;
          }
        }

        // Clamp dueDay to month's last day (e.g. Feb 28)
        final lastDay = DateTime(scheduledYear, scheduledMonth + 1, 0).day;
        final day = dueDay > lastDay ? lastDay : dueDay;

        final tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledYear,
          scheduledMonth,
          day,
          9, // 9:00 AM
          0,
        );

        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            'emi_reminders',
            'EMI & Loan Reminders',
            channelDescription: 'Notifications for upcoming and due EMI installments',
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

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'EMI PAYMENT DUE TODAY',
          body: '$loanTitle: EMI of $currency${emiAmount.toStringAsFixed(0)} is due today. Tap to record payment.',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );

        if (kDebugMode) {
          print('[NotificationService] Scheduled EMI reminder #$notificationId for $loanTitle on day $day of month.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error scheduling EMI reminder: $e');
      }
    }
  }

  /// Schedule monthly recurring reminder for Credit Card bill/EMI payment
  Future<void> scheduleCreditCardReminder({
    required int notificationId,
    required String cardTitle,
    required double outstandingAmount,
    required int dueDay,
    required String currency,
  }) async {
    await initialize();

    try {
      if (!kIsWeb) {
        final now = DateTime.now();
        var scheduledYear = now.year;
        var scheduledMonth = now.month;

        // If today is past dueDay, schedule for next month
        if (now.day > dueDay || (now.day == dueDay && now.hour >= 9)) {
          if (scheduledMonth == 12) {
            scheduledMonth = 1;
            scheduledYear++;
          } else {
            scheduledMonth++;
          }
        }

        final lastDay = DateTime(scheduledYear, scheduledMonth + 1, 0).day;
        final day = dueDay > lastDay ? lastDay : dueDay;

        final tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledYear,
          scheduledMonth,
          day,
          9, // 9:00 AM
          0,
        );

        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            'card_bill_reminders',
            'Credit Card Bill Reminders',
            channelDescription: 'Notifications for credit card bill payment due dates',
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

        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'CREDIT CARD BILL DUE TODAY',
          body: '$cardTitle: Payment of $currency${outstandingAmount.toStringAsFixed(0)} is due today. Tap to record payment.',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );

        if (kDebugMode) {
          print('[NotificationService] Scheduled Card Bill reminder #$notificationId for $cardTitle on day $day of month.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Error scheduling Card Bill reminder: $e');
      }
    }
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
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
