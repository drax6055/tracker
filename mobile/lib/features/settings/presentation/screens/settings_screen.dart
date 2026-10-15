import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/security/bank_privacy_service.dart';
import '../../../../core/services/reminder_notification_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_toast.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedCurrency = 'INR';
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _bankPrivacyEnabled = true;
  bool _notifPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadReminderSettings();
    _loadSecurityAndPermissions();
  }

  Future<void> _loadSecurityAndPermissions() async {
    final secure = await BankPrivacyService.isSecureEnabled();
    final notif = await ReminderNotificationService().checkPermissionsGranted();
    if (mounted) {
      setState(() {
        _bankPrivacyEnabled = secure;
        _notifPermissionGranted = notif;
      });
    }
  }

  void _toggleBankPrivacy(bool val) async {
    if (val) {
      await BankPrivacyService.enableSecureFlag();
    } else {
      await BankPrivacyService.disableSecureFlag();
    }
    setState(() => _bankPrivacyEnabled = val);
    if (mounted) {
      BrutalToast.showSuccess(
        context,
        val
            ? 'BANK PRIVACY ACTIVE: App snapshot hidden in app drawer & screenshots disabled'
            : 'BANK PRIVACY DISABLED: App preview visible in task switcher',
      );
    }
  }

  void _requestNotificationPermission() async {
    final granted = await ReminderNotificationService().requestPermissions();
    if (mounted) {
      setState(() => _notifPermissionGranted = granted);
      if (granted) {
        BrutalToast.showSuccess(context, 'NOTIFICATION & ALARM PERMISSIONS AUTHORIZED');
      } else {
        BrutalToast.showWarning(context, 'PERMISSION STATUS PENDING IN OS SETTINGS');
      }
    }
  }

  Future<void> _loadCurrency() async {
    final cur = await SecureStorageService.getCurrency();
    setState(() => _selectedCurrency = cur);
  }

  Future<void> _loadReminderSettings() async {
    final enabled = await SecureStorageService.getReminderEnabled();
    final timeMap = await SecureStorageService.getReminderTime();
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = TimeOfDay(
        hour: timeMap['hour'] ?? 21,
        minute: timeMap['minute'] ?? 0,
      );
    });
  }

  void _handleCurrencyChange(String newCurrency) async {
    await SecureStorageService.saveCurrency(newCurrency);
    setState(() => _selectedCurrency = newCurrency);
    if (mounted) {
      BrutalToast.showSuccess(context, 'DEFAULT CURRENCY SET TO $newCurrency');
    }
  }

  void _toggleReminder(bool val) async {
    await SecureStorageService.saveReminderEnabled(val);
    setState(() => _reminderEnabled = val);
    if (val) {
      await ReminderNotificationService().scheduleDailyReminder(
        _reminderTime.hour,
        _reminderTime.minute,
      );
      if (mounted) {
        BrutalToast.showSuccess(
          context,
          'DAILY REMINDER ACTIVE FOR ${_formatTime(_reminderTime)}',
        );
      }
    } else {
      await ReminderNotificationService().cancelDailyReminder();
      if (mounted) {
        BrutalToast.showWarning(context, 'DAILY REMINDERS DISABLED');
      }
    }
  }

  Future<void> _pickReminderTime() async {
    if (!_reminderEnabled) {
      BrutalToast.showWarning(context, 'ENABLE REMINDERS FIRST TO CHANGE SCHEDULE');
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BrutalColors.primaryYellow,
              onPrimary: BrutalColors.textDark,
              surface: BrutalColors.surface,
              onSurface: BrutalColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: BrutalColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await SecureStorageService.saveReminderTime(picked.hour, picked.minute);
      setState(() => _reminderTime = picked);
      await ReminderNotificationService().scheduleDailyReminder(
        picked.hour,
        picked.minute,
      );
      if (mounted) {
        BrutalToast.showSuccess(
          context,
          'REMINDER SCHEDULED AT ${_formatTime(picked)}',
        );
      }
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    BrutalDialog.show(
      context: context,
      title: 'CHANGE PASSWORD',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPassController,
            obscureText: true,
            style: BrutalTypography.bodyMedium,
            decoration: const InputDecoration(hintText: 'Current Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassController,
            obscureText: true,
            style: BrutalTypography.bodyMedium,
            decoration: const InputDecoration(hintText: 'New Password (8+ chars)'),
          ),
        ],
      ),
      confirmText: 'UPDATE KEY',
      onConfirm: () {
        BrutalToast.showSuccess(context, 'SECURITY PASSWORD UPDATED');
      },
    );
  }

  void _handleLogout() async {
    BrutalDialog.show(
      context: context,
      title: 'DISCONNECT SESSION?',
      content: Text(
        'Revoking session will invalidate current refresh tokens. You will need to re-authenticate.',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'LOGOUT',
      confirmColor: BrutalColors.red,
      onConfirm: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
        }
      },
    );
  }

  void _handlePurgeAccount() async {
    BrutalDialog.show(
      context: context,
      title: 'PURGE VAULT ACCOUNT?',
      content: Text(
        'This action is irreversible. All transactions, accounts, and ledger data will be deleted permanently from the servers and your device.',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'PERMANENTLY PURGE',
      confirmColor: BrutalColors.red,
      onConfirm: () async {
        await ReminderNotificationService().cancelDailyReminder();
        await ref.read(authControllerProvider.notifier).terminateAccountAndPurgeData();
        if (mounted) {
          BrutalToast.showWarning(context, 'ALL VAULT DATA AND ACCOUNT PURGED');
          context.go('/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: const BrutalAppBar(
        title: 'PREFERENCES & VAULT',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Profile Card
            BrutalCard(
              backgroundColor: BrutalColors.surface,
              borderColor: BrutalColors.border,
              shadowColor: BrutalColors.primaryYellow,
              shadowOffset: 5.0,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: BrutalColors.primaryYellow,
                      border: Border.all(color: BrutalColors.border, width: 2.5),
                    ),
                    child: const Icon(Icons.person, size: 30, color: BrutalColors.textDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'OPERATOR',
                          style: BrutalTypography.headingSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'operator@ledger.app',
                          style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const BrutalChip(
                          label: 'VERIFIED VAULT',
                          backgroundColor: BrutalColors.lime,
                          textColor: BrutalColors.textDark,
                          shadowOffset: 0,
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Currency Selector
            Text('CURRENCY STANDARD', style: BrutalTypography.label),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCurrencyChip('INR', '₹ INR (Lakh/Crore)'),
                const SizedBox(width: 8),
                _buildCurrencyChip('USD', r'$ USD'),
                const SizedBox(width: 8),
                _buildCurrencyChip('EUR', '€ EUR'),
              ],
            ),
            const SizedBox(height: 24),

            // Daily Reminder Notification Settings
            Text('DAILY REMINDER NOTIFICATIONS', style: BrutalTypography.label),
            const SizedBox(height: 10),
            BrutalCard(
              backgroundColor: BrutalColors.surface,
              borderColor: BrutalColors.border,
              shadowColor: _reminderEnabled ? BrutalColors.primaryYellow : BrutalColors.borderDim,
              shadowOffset: 4.0,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _reminderEnabled ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: Icon(
                          _reminderEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          color: _reminderEnabled ? BrutalColors.textDark : BrutalColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY LEDGER CHECK-IN',
                              style: BrutalTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _reminderEnabled
                                  ? 'Alerts you at scheduled time to reconcile entries'
                                  : 'Muted - no reminder alerts will be dispatched',
                              style: BrutalTypography.bodySmall.copyWith(
                                color: BrutalColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _reminderEnabled,
                        activeTrackColor: BrutalColors.primaryYellow,
                        activeThumbColor: BrutalColors.textDark,
                        onChanged: _toggleReminder,
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 14),
                    const Divider(color: BrutalColors.borderDim, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALARM SCHEDULE',
                                style: BrutalTypography.label.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickReminderTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: BrutalColors.surfaceElevated,
                                    border: Border.all(color: BrutalColors.border, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: BrutalColors.border,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time_filled,
                                        size: 16,
                                        color: BrutalColors.primaryYellow,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(_reminderTime),
                                        style: BrutalTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: BrutalColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        BrutalChip(
                          label: '⚡ TEST ALERT',
                          backgroundColor: BrutalColors.surfaceElevated,
                          textColor: BrutalColors.primaryYellow,
                          borderColor: BrutalColors.primaryYellow,
                          shadowOffset: 2.0,
                          onTap: () {
                            ReminderNotificationService().triggerImmediateTestReminder(
                              onTriggered: () {
                                BrutalToast.showSuccess(
                                  context,
                                  'BELL ALERT: Daily Ledger Check-in Triggered!',
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bank Privacy & Runtime Permissions
            Text('BANK PRIVACY & OS PERMISSIONS', style: BrutalTypography.label),
            const SizedBox(height: 10),
            BrutalCard(
              backgroundColor: BrutalColors.surface,
              borderColor: BrutalColors.border,
              shadowColor: BrutalColors.cyan,
              shadowOffset: 4.0,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bank App Switcher / App Drawer Privacy
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bankPrivacyEnabled ? BrutalColors.cyan : BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: Icon(
                          Icons.security,
                          color: _bankPrivacyEnabled ? BrutalColors.textDark : BrutalColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BANK PRIVACY (FLAG_SECURE)',
                              style: BrutalTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _bankPrivacyEnabled
                                  ? 'App screen is blanked in app drawer & screenshots blocked'
                                  : 'Disabled: App preview is visible in app switcher',
                              style: BrutalTypography.bodySmall.copyWith(
                                color: BrutalColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _bankPrivacyEnabled,
                        activeTrackColor: BrutalColors.cyan,
                        activeThumbColor: BrutalColors.textDark,
                        onChanged: _toggleBankPrivacy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: BrutalColors.borderDim, height: 1),
                  const SizedBox(height: 14),

                  // 2. Runtime Notification & Background Alarms Permission
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _notifPermissionGranted ? BrutalColors.lime : BrutalColors.orange,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: Icon(
                          _notifPermissionGranted ? Icons.check_circle_outline : Icons.notification_important_outlined,
                          color: BrutalColors.textDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RUNTIME NOTIFICATION STATUS',
                              style: BrutalTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _notifPermissionGranted
                                  ? 'Authorized: Exact alarms & tray notifications active'
                                  : 'Pending: Tap button to grant Android/iOS notification permission',
                              style: BrutalTypography.bodySmall.copyWith(
                                color: BrutalColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      BrutalChip(
                        label: _notifPermissionGranted ? 'VERIFIED' : 'GRANT',
                        backgroundColor: _notifPermissionGranted ? BrutalColors.lime : BrutalColors.primaryYellow,
                        textColor: BrutalColors.textDark,
                        borderColor: BrutalColors.border,
                        shadowOffset: 2.0,
                        onTap: _requestNotificationPermission,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: BrutalColors.surfaceElevated,
                      border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: BrutalColors.primaryYellow),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Battery Tip: On Samsung/Xiaomi, set battery to "Unrestricted" so alarms ring even when the app is closed.',
                            style: BrutalTypography.bodySmall.copyWith(
                              fontSize: 10.5,
                              color: BrutalColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Options
            Text('VAULT SECURITY', style: BrutalTypography.label),
            const SizedBox(height: 10),
            _buildSettingTile(
              title: 'Change Password',
              subtitle: 'Update your access key',
              icon: Icons.key_outlined,
              onTap: _showChangePasswordDialog,
            ),
            _buildSettingTile(
              title: 'Export Ledger Data',
              subtitle: 'Download complete statement in CSV/PDF format',
              icon: Icons.file_download_outlined,
              onTap: () => BrutalToast.showSuccess(context, 'GENERATING EXPORT FILE...'),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            Text('ACCOUNT MANAGEMENT', style: BrutalTypography.label.copyWith(color: BrutalColors.red)),
            const SizedBox(height: 10),
            BrutalButton(
              text: 'LOGOUT FROM SYSTEM',
              backgroundColor: BrutalColors.surfaceElevated,
              textColor: BrutalColors.textPrimary,
              height: 48,
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 12),
            BrutalButton(
              text: 'TERMINATE ACCOUNT & PURGE DATA',
              backgroundColor: BrutalColors.red,
              textColor: BrutalColors.textPrimary,
              height: 48,
              onPressed: _handlePurgeAccount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(String code, String label) {
    final isSelected = _selectedCurrency == code;
    return BrutalChip(
      label: label,
      backgroundColor: isSelected ? BrutalColors.cyan : BrutalColors.surfaceElevated,
      textColor: isSelected ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSelected ? 3.0 : 0.0,
      onTap: () => _handleCurrencyChange(code),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowOffset: 3.0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: BrutalColors.primaryYellow, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: BrutalColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
