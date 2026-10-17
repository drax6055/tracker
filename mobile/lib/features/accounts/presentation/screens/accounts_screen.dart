import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_progress_bar.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../../../../core/widgets/brutal_toggle.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/services/reminder_notification_service.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ledger_app/features/transactions/presentation/controllers/transactions_controller.dart';

class AccountItem {
  String id;
  String title;
  String subtitle;
  double balance;
  String type; // BANK, CASH, CREDIT_CARD, LOAN
  Color accentColor;
  String digits;
  String? subtext;
  double? creditLimit;
  double? emiAmount;
  int? emiDueDay;
  bool isClosed;
  bool includeInNetWorth;

  AccountItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.balance,
    required this.type,
    required this.accentColor,
    required this.digits,
    this.subtext,
    this.creditLimit,
    this.emiAmount,
    this.emiDueDay,
    this.isClosed = false,
    this.includeInNetWorth = true,
  });
}

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  List<AccountItem> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final rawList = await SecureStorageService.getAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = rawList.map((m) {
        final type = (m['type'] ?? 'BANK').toString();
        Color accent = BrutalColors.cyan;
        if (type == 'CASH') accent = BrutalColors.lime;
        if (type == 'CREDIT_CARD') accent = BrutalColors.hotPink;
        if (type == 'LOAN') accent = BrutalColors.orange;
        return AccountItem(
          id: (m['id'] ?? 'acc_${DateTime.now().millisecondsSinceEpoch}').toString(),
          title: (m['title'] ?? 'Account').toString(),
          subtitle: (m['subtitle'] ?? '').toString(),
          balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
          type: type,
          accentColor: accent,
          digits: (m['digits'] ?? '').toString(),
          subtext: m['subtext']?.toString(),
          creditLimit: (m['creditLimit'] as num?)?.toDouble(),
          emiAmount: (m['emiAmount'] as num?)?.toDouble(),
          emiDueDay: (m['emiDueDay'] as num?)?.toInt(),
          isClosed: m['isClosed'] == true,
          includeInNetWorth: m['includeInNetWorth'] != false,
        );
      }).toList();
    });
  }

  void _saveAccounts() {
    final list = _accounts.map((a) => {
      'id': a.id,
      'title': a.title,
      'subtitle': a.subtitle,
      'balance': a.balance,
      'type': a.type,
      'digits': a.digits,
      'subtext': a.subtext,
      'creditLimit': a.creditLimit,
      'emiAmount': a.emiAmount,
      'emiDueDay': a.emiDueDay,
      'isClosed': a.isClosed,
      'includeInNetWorth': a.includeInNetWorth,
    }).toList();
    SecureStorageService.saveAccounts(list);
  }

  Future<void> _navigateToAddAccount() async {
    await context.push('/add-account');
    _loadAccounts();
  }

  void _showEditAccountDialog(AccountItem account) {
    final titleController = TextEditingController(text: account.title);
    final subtitleController = TextEditingController(text: account.subtitle);
    final balanceController = TextEditingController(text: account.balance.toStringAsFixed(0));
    final limitController = TextEditingController(
      text: account.creditLimit != null ? account.creditLimit!.toStringAsFixed(0) : '',
    );
    final emiController = TextEditingController(
      text: account.emiAmount != null ? account.emiAmount!.toStringAsFixed(0) : '',
    );
    final dueDayController = TextEditingController(
      text: account.emiDueDay != null ? account.emiDueDay.toString() : '',
    );
    String selectedType = account.type;
    bool includeInNetWorth = account.includeInNetWorth;
    bool isClosed = account.isClosed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('EDIT VAULT ACCOUNT', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: titleController,
                      label: 'ACCOUNT NAME',
                      hintText: 'e.g., Primary Salary Bank',
                    ),
                    const SizedBox(height: 12),
                    BrutalTextField(
                      controller: subtitleController,
                      label: 'INSTITUTION / DETAILS',
                      hintText: 'e.g., Chase Bank • Last 4: 1234',
                    ),
                    const SizedBox(height: 12),
                    BrutalTextField(
                      controller: balanceController,
                      label: selectedType == 'LOAN'
                          ? 'REMAINING PRINCIPAL'
                          : selectedType == 'CREDIT_CARD'
                              ? 'CURRENT OUTSTANDING'
                              : 'CURRENT BALANCE',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    if (selectedType == 'CREDIT_CARD') ...[
                      BrutalTextField(
                        controller: limitController,
                        label: 'CREDIT LIMIT',
                        hintText: '500000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      BrutalTextField(
                        controller: dueDayController,
                        label: 'BILL DUE DAY OF MONTH (1 - 31)',
                        hintText: 'e.g., 5, 15, 22',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      BrutalTextField(
                        controller: emiController,
                        label: 'MONTHLY MINIMUM / EMI AMOUNT (OPTIONAL)',
                        hintText: '5000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (selectedType == 'LOAN') ...[
                      BrutalTextField(
                        controller: limitController,
                        label: 'TOTAL LOAN PRINCIPAL',
                        hintText: '500000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      BrutalTextField(
                        controller: emiController,
                        label: 'MONTHLY EMI AMOUNT',
                        hintText: '14500',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      BrutalTextField(
                        controller: dueDayController,
                        label: 'EMI DUE DAY OF MONTH (1 - 31)',
                        hintText: 'e.g., 5 or 10',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isClosed ? BrutalColors.lime.withValues(alpha: 0.12) : BrutalColors.surfaceElevated,
                          border: Border.all(
                            color: isClosed ? BrutalColors.lime : BrutalColors.borderDim,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LOAN STATUS', style: BrutalTypography.label.copyWith(fontSize: 11)),
                                Text(
                                  isClosed ? 'CLOSED / PAID OFF' : 'ACTIVE LOAN',
                                  style: BrutalTypography.sticker.copyWith(
                                    color: isClosed ? BrutalColors.lime : BrutalColors.orange,
                                  ),
                                ),
                              ],
                            ),
                            BrutalToggle(
                              value: isClosed,
                              onChanged: (val) => setModalState(() {
                                isClosed = val;
                                if (val) {
                                  balanceController.text = '0';
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Include in net worth toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('INCLUDE IN NET WORTH', style: BrutalTypography.label.copyWith(fontSize: 12)),
                          BrutalToggle(
                            value: includeInNetWorth,
                            onChanged: (val) => setModalState(() => includeInNetWorth = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('ACCOUNT CATEGORY', style: BrutalTypography.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['BANK', 'CASH', 'CREDIT_CARD', 'LOAN'].map((t) {
                        final isSel = selectedType == t;
                        Color c = BrutalColors.cyan;
                        if (t == 'CASH') c = BrutalColors.lime;
                        if (t == 'CREDIT_CARD') c = BrutalColors.hotPink;
                        if (t == 'LOAN') c = BrutalColors.orange;

                        return BrutalChip(
                          label: t.replaceAll('_', ' '),
                          backgroundColor: isSel ? c : BrutalColors.surfaceElevated,
                          textColor: isSel ? BrutalColors.textDark : BrutalColors.textPrimary,
                          borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
                          shadowOffset: isSel ? 2 : 0,
                          onTap: () {
                            setModalState(() => selectedType = t);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    BrutalButton(
                      text: 'SAVE CHANGES',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 48,
                      onPressed: () {
                        final newTitle = titleController.text.trim();
                        final newSubtitle = subtitleController.text.trim();
                        final newBalance = double.tryParse(balanceController.text.trim()) ?? account.balance;
                        final newLimit = double.tryParse(limitController.text.trim());
                        final newEmi = double.tryParse(emiController.text.trim());
                        final newDueDay = int.tryParse(dueDayController.text.trim());
                        final authState = ref.read(authControllerProvider);
                        final currency = authState.user?.currencySymbol ?? '₹';

                        if (newTitle.isEmpty) {
                          BrutalToast.showError(ctx, 'Account name cannot be empty');
                          return;
                        }

                        setState(() {
                          account.title = newTitle;
                          account.subtitle = newSubtitle;
                          account.balance = isClosed ? 0.0 : newBalance;
                          account.type = selectedType;
                          account.creditLimit = newLimit;
                          account.emiAmount = newEmi;
                          account.emiDueDay = newDueDay;
                          account.isClosed = isClosed;
                          account.includeInNetWorth = includeInNetWorth;
                          if (selectedType == 'BANK') account.accentColor = BrutalColors.cyan;
                          if (selectedType == 'CASH') account.accentColor = BrutalColors.lime;
                          if (selectedType == 'CREDIT_CARD') {
                            account.accentColor = BrutalColors.hotPink;
                            if (newLimit != null && newLimit > 0) {
                              final util = ((account.balance / newLimit) * 100).toStringAsFixed(1);
                              account.subtext = 'UTILIZATION: $util%';
                            }
                          }
                          if (selectedType == 'LOAN') {
                            account.accentColor = isClosed ? BrutalColors.lime : BrutalColors.orange;
                            if (isClosed) {
                              account.subtext = 'PAID OFF & CLOSED';
                            } else if (newLimit != null && newLimit > 0) {
                              final repaid = (newLimit > account.balance) ? (newLimit - account.balance) : 0.0;
                              final pct = ((repaid / newLimit) * 100).toStringAsFixed(1);
                              account.subtext = 'REPAID: $pct%';
                            }
                          }
                        });
                        _saveAccounts();

                        // Manage EMI / Bill reminder notification
                        final loanNotifId = (account.id.hashCode.abs() % 100000) + 1000;
                        final cardNotifId = (account.id.hashCode.abs() % 100000) + 2000;

                        if (selectedType == 'LOAN' && !isClosed && newDueDay != null && newDueDay > 0 && newDueDay <= 31 && (newEmi ?? 0) > 0) {
                          ReminderNotificationService().scheduleEmiReminder(
                            notificationId: loanNotifId,
                            loanTitle: newTitle,
                            emiAmount: newEmi!,
                            dueDay: newDueDay,
                            currency: currency,
                          );
                        } else {
                          ReminderNotificationService().cancelNotification(loanNotifId);
                        }

                        if (selectedType == 'CREDIT_CARD' && newDueDay != null && newDueDay > 0 && newDueDay <= 31) {
                          ReminderNotificationService().scheduleCreditCardReminder(
                            notificationId: cardNotifId,
                            cardTitle: newTitle,
                            outstandingAmount: account.balance > 0 ? account.balance : (newEmi ?? 0.0),
                            dueDay: newDueDay,
                            currency: currency,
                          );
                        } else {
                          ReminderNotificationService().cancelNotification(cardNotifId);
                        }

                        Navigator.pop(ctx);
                        BrutalToast.showSuccess(context, 'VAULT ACCOUNT UPDATED');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(AccountItem account) {
    BrutalDialog.show(
      context: context,
      title: 'DELETE VAULT ACCOUNT?',
      content: Text(
        'Are you sure you want to delete "${account.title}"? Associated ledger statistics will be detached.',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'DELETE ACCOUNT',
      confirmColor: BrutalColors.red,
      onConfirm: () {
        setState(() {
          _accounts.removeWhere((a) => a.id == account.id);
        });
        _saveAccounts();
        BrutalToast.showWarning(context, '${account.title.toUpperCase()} PURGED FROM VAULT');
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currency = authState.user?.currencySymbol ?? '₹';

    final bankAccounts = _accounts.where((a) => a.type == 'BANK').toList();
    final cashWallets = _accounts.where((a) => a.type == 'CASH').toList();
    final creditCards = _accounts.where((a) => a.type == 'CREDIT_CARD').toList();
    final loans = _accounts.where((a) => a.type == 'LOAN').toList();

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'ACCOUNTS VAULT',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            tooltip: 'Add New Account',
            onPressed: _navigateToAddAccount,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bank Accounts section
            if (bankAccounts.isNotEmpty) ...[
              _buildSectionHeader('BANK ACCOUNTS (${bankAccounts.length})', BrutalColors.cyan),
              const SizedBox(height: 10),
              ...bankAccounts.map((acc) => _buildAccountCard(acc, currency)),
              const SizedBox(height: 20),
            ],

            // Cash Wallets section
            if (cashWallets.isNotEmpty) ...[
              _buildSectionHeader('CASH WALLETS (${cashWallets.length})', BrutalColors.lime),
              const SizedBox(height: 10),
              ...cashWallets.map((acc) => _buildAccountCard(acc, currency)),
              const SizedBox(height: 20),
            ],

            // Credit Cards section
            if (creditCards.isNotEmpty) ...[
              _buildSectionHeader('CREDIT CARDS (${creditCards.length})', BrutalColors.hotPink),
              const SizedBox(height: 10),
              ...creditCards.map((acc) => _buildCreditCardItem(acc, currency)),
              const SizedBox(height: 20),
            ],

            // Loans section
            if (loans.isNotEmpty) ...[
              _buildSectionHeader('LOANS & LIABILITIES (${loans.length})', BrutalColors.orange),
              const SizedBox(height: 10),
              ...loans.map((acc) => _buildLoanItem(acc, currency)),
              const SizedBox(height: 20),
            ],

            if (_accounts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 48, color: BrutalColors.textMuted),
                      const SizedBox(height: 12),
                      Text('NO ACCOUNTS IN VAULT', style: BrutalTypography.headingSmall),
                      const SizedBox(height: 16),
                      BrutalButton(
                        text: '+ ADD FIRST ACCOUNT',
                        height: 44,
                        backgroundColor: BrutalColors.primaryYellow,
                        textColor: BrutalColors.textDark,
                        onPressed: _navigateToAddAccount,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accent) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: accent),
        const SizedBox(width: 8),
        Text(title, style: BrutalTypography.label.copyWith(color: BrutalColors.textPrimary)),
      ],
    );
  }

  Widget _buildAccountCard(AccountItem acc, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowColor: acc.accentColor,
        shadowOffset: 4.0,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BrutalChip(
                            label: acc.type,
                            backgroundColor: acc.accentColor,
                            textColor: BrutalColors.textDark,
                            shadowOffset: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          ),
                          if (!acc.includeInNetWorth) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: BrutalColors.surfaceElevated,
                                border: Border.all(color: BrutalColors.orange, width: 1.5),
                              ),
                              child: Text(
                                'NOT IN NET WORTH',
                                style: BrutalTypography.sticker.copyWith(fontSize: 9, color: BrutalColors.orange),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(acc.title, style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      Text(acc.subtitle, style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textMuted)),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                  style: BrutalTypography.amountMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: BrutalColors.borderDim, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: BrutalColors.cyan),
                  label: Text('EDIT', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                  onPressed: () => _showEditAccountDialog(acc),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: BrutalColors.red),
                  label: Text('DELETE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                  onPressed: () => _confirmDeleteAccount(acc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(AccountItem acc, String currency) {
    final limit = acc.creditLimit ?? (acc.balance > 0 ? (acc.balance + 451500.0) : 500000.0);
    final available = (limit - acc.balance).clamp(0.0, double.infinity);
    final progress = limit > 0 ? (acc.balance / limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowColor: BrutalColors.hotPink,
        shadowOffset: 4.0,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const BrutalChip(
                      label: 'CREDIT CARD',
                      backgroundColor: BrutalColors.hotPink,
                      textColor: BrutalColors.textPrimary,
                      shadowOffset: 0,
                    ),
                    if (!acc.includeInNetWorth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.orange, width: 1.5),
                        ),
                        child: Text(
                          'NOT IN NET WORTH',
                          style: BrutalTypography.sticker.copyWith(fontSize: 9, color: BrutalColors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('•${acc.digits}', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(acc.title, style: BrutalTypography.headingSmall),
            Text(acc.subtitle, style: BrutalTypography.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OUTSTANDING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                    Text(
                      CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.red),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('AVAILABLE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.lime)),
                    Text(
                      CurrencyFormatter.format(available, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.lime),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            BrutalProgressBar(
              value: progress,
              height: 12,
              fillColor: BrutalColors.hotPink,
            ),
            if (acc.subtext != null) ...[
              const SizedBox(height: 6),
              Text(acc.subtext!, style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted)),
            ],
            // Due date & Bill reminder banner
            if (acc.emiDueDay != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BrutalColors.surfaceElevated,
                  border: Border.all(color: BrutalColors.hotPink, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 14, color: BrutalColors.hotPink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'BILL / EMI DUE ON ${acc.emiDueDay}${_getOrdinalSuffix(acc.emiDueDay!)} • LIMIT: ${CurrencyFormatter.format(limit, symbol: currency, showDecimals: false)}',
                        style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.hotPink),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: BrutalColors.hotPink,
                      child: Text(
                        'REMINDER ACTIVE',
                        style: BrutalTypography.sticker.copyWith(fontSize: 8, color: BrutalColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BrutalButton(
                    text: 'PAY BILL / EMI',
                    backgroundColor: BrutalColors.hotPink,
                    textColor: BrutalColors.textPrimary,
                    height: 38,
                    onPressed: () => _handlePayCreditCard(acc, currency),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BrutalButton(
                    text: 'CLEAR BALANCE',
                    backgroundColor: BrutalColors.surfaceElevated,
                    textColor: BrutalColors.lime,
                    borderColor: BrutalColors.lime,
                    height: 38,
                    onPressed: () => _handleSettleCreditCard(acc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Divider(color: BrutalColors.borderDim, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: BrutalColors.cyan),
                  label: Text('EDIT', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                  onPressed: () => _showEditAccountDialog(acc),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: BrutalColors.red),
                  label: Text('DELETE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                  onPressed: () => _confirmDeleteAccount(acc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayCreditCard(AccountItem acc, String currency) {
    final defaultAmount = acc.balance > 0
        ? acc.balance
        : (acc.emiAmount != null && acc.emiAmount! > 0 ? acc.emiAmount! : 5000.0);
    final amountController = TextEditingController(text: defaultAmount.toStringAsFixed(0));

    // Eligible source accounts (BANK and CASH)
    final paymentSources = _accounts.where((a) => (a.type == 'BANK' || a.type == 'CASH') && a.id != acc.id).toList();
    AccountItem? selectedSource = paymentSources.isNotEmpty ? paymentSources.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
            final remainingAfter = (acc.balance - enteredAmount).clamp(0.0, double.infinity);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PAY CREDIT CARD BILL / EMI', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recording card payment for "${acc.title}" will reduce its outstanding balance, restore available credit, and debit your bank/cash vault.',
                      style: BrutalTypography.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: amountController,
                      label: 'PAYMENT AMOUNT ($currency)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Balance preview card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OUTSTANDING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                              Text(
                                CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                                style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.red),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: BrutalColors.textMuted, size: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('AFTER PAYMENT', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                              Text(
                                CurrencyFormatter.format(remainingAfter, symbol: currency, showDecimals: false),
                                style: BrutalTypography.bodyMedium.copyWith(
                                  color: remainingAfter == 0 ? BrutalColors.lime : BrutalColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('DEDUCT FROM VAULT ACCOUNT (OPTIONAL)', style: BrutalTypography.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...paymentSources.map((source) {
                          final isSel = selectedSource?.id == source.id;
                          return BrutalChip(
                            label: '${source.title} (${CurrencyFormatter.format(source.balance, symbol: currency, showDecimals: false)})',
                            backgroundColor: isSel ? BrutalColors.cyan : BrutalColors.surfaceElevated,
                            textColor: isSel ? BrutalColors.textDark : BrutalColors.textPrimary,
                            borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
                            shadowOffset: isSel ? 2 : 0,
                            onTap: () => setModalState(() => selectedSource = isSel ? null : source),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BrutalButton(
                      text: remainingAfter == 0 ? 'PAY IN FULL & CLEAR CARD' : 'CONFIRM BILL PAYMENT',
                      backgroundColor: BrutalColors.hotPink,
                      textColor: BrutalColors.textPrimary,
                      height: 48,
                      onPressed: () async {
                        final payAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (payAmount <= 0) {
                          BrutalToast.showError(ctx, 'Please enter a valid payment amount');
                          return;
                        }

                        setState(() {
                          acc.balance = (acc.balance - payAmount).clamp(0.0, double.infinity);
                          if (acc.creditLimit != null && acc.creditLimit! > 0) {
                            final util = ((acc.balance / acc.creditLimit!) * 100).toStringAsFixed(1);
                            acc.subtext = 'UTILIZATION: $util%';
                          }
                          if (selectedSource != null) {
                            selectedSource!.balance -= payAmount;
                          }
                        });

                        _saveAccounts();

                        // Add transaction
                        if (selectedSource != null) {
                          final now = DateTime.now();
                          final tx = {
                            'id': 'tx_${now.millisecondsSinceEpoch}',
                            'title': 'Card Payment: ${acc.title}',
                            'type': 'EXPENSE',
                            'category': 'Bills',
                            'account': selectedSource!.title,
                            'date': '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                            'timestamp': now.toIso8601String(),
                            'amount': payAmount,
                            'note': 'Credit card bill payment for ${acc.title}',
                          };
                          await ref.read(transactionsProvider.notifier).addTransaction(tx);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        BrutalToast.showSuccess(
                          context,
                          'CARD PAYMENT: ${CurrencyFormatter.format(payAmount, symbol: currency, showDecimals: false)} RECORDED',
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSettleCreditCard(AccountItem acc) {
    BrutalDialog.show(
      context: context,
      title: 'CLEAR CARD BALANCE?',
      content: Text(
        'Are you sure you want to mark "${acc.title}" as fully settled? Outstanding balance will be reset to 0.',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'SETTLE TO ZERO',
      confirmColor: BrutalColors.lime,
      onConfirm: () {
        setState(() {
          acc.balance = 0.0;
          if (acc.creditLimit != null && acc.creditLimit! > 0) {
            acc.subtext = 'UTILIZATION: 0.0%';
          }
        });
        _saveAccounts();

        if (mounted) {
          BrutalToast.showSuccess(context, 'CARD BALANCE SETTLED TO ZERO');
        }
      },
    );
  }

  Widget _buildLoanItem(AccountItem acc, String currency) {
    final isClosed = acc.isClosed || acc.balance <= 0.0;
    // Total loan borrowed / principal (uses creditLimit field or fallback calculation)
    final totalLoan = (acc.creditLimit != null && acc.creditLimit! > 0)
        ? acc.creditLimit!
        : (acc.balance > 0 ? (acc.balance / 0.7126) : 0.0);
    final repaid = isClosed ? totalLoan : ((totalLoan > acc.balance) ? (totalLoan - acc.balance) : 0.0);
    final progress = isClosed ? 1.0 : (totalLoan > 0 ? (repaid / totalLoan).clamp(0.0, 1.0) : 0.0);
    final repaidPct = (progress * 100).toStringAsFixed(1);
    final remainingPct = ((1.0 - progress) * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: isClosed ? BrutalColors.lime : BrutalColors.border,
        shadowColor: isClosed ? BrutalColors.lime : BrutalColors.orange,
        shadowOffset: 4.0,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    BrutalChip(
                      label: isClosed ? 'LOAN • CLOSED' : 'LOAN',
                      backgroundColor: isClosed ? BrutalColors.lime : BrutalColors.orange,
                      textColor: BrutalColors.textDark,
                      shadowOffset: 0,
                    ),
                    if (isClosed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrutalColors.lime.withValues(alpha: 0.15),
                          border: Border.all(color: BrutalColors.lime, width: 1.5),
                        ),
                        child: Text(
                          'PAID OFF',
                          style: BrutalTypography.sticker.copyWith(fontSize: 9, color: BrutalColors.lime),
                        ),
                      ),
                    ] else if (!acc.includeInNetWorth) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.orange, width: 1.5),
                        ),
                        child: Text(
                          'NOT IN NET WORTH',
                          style: BrutalTypography.sticker.copyWith(fontSize: 9, color: BrutalColors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(acc.digits, style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(acc.title, style: BrutalTypography.headingSmall),
            Text(acc.subtitle, style: BrutalTypography.bodySmall),

            // Due date & EMI reminder banner
            if (!isClosed && (acc.emiDueDay != null || acc.emiAmount != null)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BrutalColors.surfaceElevated,
                  border: Border.all(color: BrutalColors.primaryYellow, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 14, color: BrutalColors.primaryYellow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        acc.emiDueDay != null
                            ? 'EMI DUE ON ${acc.emiDueDay}${_getOrdinalSuffix(acc.emiDueDay!)} • ${acc.emiAmount != null ? CurrencyFormatter.format(acc.emiAmount!, symbol: currency, showDecimals: false) : ""}/MO'
                            : 'EMI: ${CurrencyFormatter.format(acc.emiAmount ?? 0, symbol: currency, showDecimals: false)}/MO',
                        style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.primaryYellow),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: BrutalColors.primaryYellow,
                      child: Text(
                        'REMINDER ACTIVE',
                        style: BrutalTypography.sticker.copyWith(fontSize: 8, color: BrutalColors.textDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isClosed ? 'STATUS' : 'REMAINING ($remainingPct%)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                    Text(
                      isClosed ? 'ZERO BALANCE' : CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: isClosed ? BrutalColors.lime : BrutalColors.orange),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('REPAID ($repaidPct%)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.lime)),
                    Text(
                      CurrencyFormatter.format(repaid, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.lime),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            BrutalProgressBar(
              value: progress,
              height: 12,
              fillColor: isClosed ? BrutalColors.lime : BrutalColors.orange,
            ),
            if (acc.subtext != null) ...[
              const SizedBox(height: 6),
              Text(acc.subtext!, style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted)),
            ],

            // Action Buttons
            const SizedBox(height: 12),
            if (!isClosed) ...[
              Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      text: 'RECORD EMI PAID',
                      backgroundColor: BrutalColors.lime,
                      textColor: BrutalColors.textDark,
                      height: 38,
                      onPressed: () => _handlePayEmi(acc, currency),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BrutalButton(
                      text: 'CLOSE LOAN',
                      backgroundColor: BrutalColors.surfaceElevated,
                      textColor: BrutalColors.orange,
                      borderColor: BrutalColors.orange,
                      height: 38,
                      onPressed: () => _handleCloseLoan(acc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      text: 'RE-OPEN LOAN',
                      backgroundColor: BrutalColors.surfaceElevated,
                      textColor: BrutalColors.textPrimary,
                      borderColor: BrutalColors.borderDim,
                      height: 36,
                      onPressed: () => _handleReopenLoan(acc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const Divider(color: BrutalColors.borderDim, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: BrutalColors.cyan),
                  label: Text('EDIT', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                  onPressed: () => _showEditAccountDialog(acc),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: BrutalColors.red),
                  label: Text('DELETE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                  onPressed: () => _confirmDeleteAccount(acc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePayEmi(AccountItem acc, String currency) {
    final defaultAmount = (acc.emiAmount != null && acc.emiAmount! > 0)
        ? acc.emiAmount!
        : (acc.balance > 0 ? (acc.balance > 15000 ? 15000.0 : acc.balance) : 0.0);
    final amountController = TextEditingController(text: defaultAmount.toStringAsFixed(0));

    // Eligible source accounts (BANK and CASH)
    final paymentSources = _accounts.where((a) => (a.type == 'BANK' || a.type == 'CASH') && a.id != acc.id).toList();
    AccountItem? selectedSource = paymentSources.isNotEmpty ? paymentSources.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
            final remainingAfter = (acc.balance - enteredAmount).clamp(0.0, double.infinity);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RECORD EMI PAYMENT', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recording EMI for "${acc.title}" will reduce its remaining principal and optionally debit your bank/cash ledger.',
                      style: BrutalTypography.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: amountController,
                      label: 'EMI AMOUNT TO PAY ($currency)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Balance preview card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CURRENT BALANCE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                              Text(
                                CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                                style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.orange),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: BrutalColors.textMuted, size: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('AFTER PAYMENT', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                              Text(
                                CurrencyFormatter.format(remainingAfter, symbol: currency, showDecimals: false),
                                style: BrutalTypography.bodyMedium.copyWith(
                                  color: remainingAfter == 0 ? BrutalColors.lime : BrutalColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('DEDUCT FROM VAULT ACCOUNT (OPTIONAL)', style: BrutalTypography.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...paymentSources.map((source) {
                          final isSel = selectedSource?.id == source.id;
                          return BrutalChip(
                            label: '${source.title} (${CurrencyFormatter.format(source.balance, symbol: currency, showDecimals: false)})',
                            backgroundColor: isSel ? BrutalColors.cyan : BrutalColors.surfaceElevated,
                            textColor: isSel ? BrutalColors.textDark : BrutalColors.textPrimary,
                            borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
                            shadowOffset: isSel ? 2 : 0,
                            onTap: () => setModalState(() => selectedSource = isSel ? null : source),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BrutalButton(
                      text: remainingAfter == 0 ? 'PAY EMI & CLOSE LOAN' : 'CONFIRM EMI PAYMENT',
                      backgroundColor: BrutalColors.lime,
                      textColor: BrutalColors.textDark,
                      height: 48,
                      onPressed: () async {
                        final payAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (payAmount <= 0) {
                          BrutalToast.showError(ctx, 'Please enter a valid EMI payment amount');
                          return;
                        }

                        setState(() {
                          acc.balance = (acc.balance - payAmount).clamp(0.0, double.infinity);
                          if (acc.balance == 0.0) {
                            acc.isClosed = true;
                            acc.subtext = 'PAID OFF & CLOSED';
                          } else if (acc.creditLimit != null && acc.creditLimit! > 0) {
                            final repaid = acc.creditLimit! - acc.balance;
                            final pct = ((repaid / acc.creditLimit!) * 100).toStringAsFixed(1);
                            acc.subtext = 'REPAID: $pct%';
                          }
                          if (selectedSource != null) {
                            selectedSource!.balance -= payAmount;
                          }
                        });

                        _saveAccounts();

                        // If paid from a source account, add an expense transaction
                        if (selectedSource != null) {
                          final now = DateTime.now();
                          final tx = {
                            'id': 'tx_${now.millisecondsSinceEpoch}',
                            'title': 'EMI Paid: ${acc.title}',
                            'type': 'EXPENSE',
                            'category': 'EMI & Loans',
                            'account': selectedSource!.title,
                            'date': '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                            'timestamp': now.toIso8601String(),
                            'amount': payAmount,
                            'note': 'Monthly EMI payment for ${acc.title}',
                          };
                          await ref.read(transactionsProvider.notifier).addTransaction(tx);
                        }

                        // If closed, cancel reminder notification
                        if (acc.isClosed) {
                          final notifId = (acc.id.hashCode.abs() % 100000) + 1000;
                          await ReminderNotificationService().cancelNotification(notifId);
                        }

                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        if (acc.isClosed) {
                          BrutalToast.showSuccess(context, '🎉 LOAN FULLY SETTLED & CLOSED!');
                        } else {
                          BrutalToast.showSuccess(
                            context,
                            'EMI PAID: ${CurrencyFormatter.format(payAmount, symbol: currency, showDecimals: false)} RECORDED',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCloseLoan(AccountItem acc) {
    BrutalDialog.show(
      context: context,
      title: 'CLOSE / SETTLE LOAN?',
      content: Text(
        'Are you sure you want to mark "${acc.title}" as closed? The remaining principal will be set to 0 and all scheduled EMI reminders will be cancelled.',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'CLOSE LOAN',
      confirmColor: BrutalColors.orange,
      onConfirm: () async {
        setState(() {
          acc.isClosed = true;
          acc.balance = 0.0;
          acc.subtext = 'PAID OFF & CLOSED';
        });
        _saveAccounts();

        final notifId = (acc.id.hashCode.abs() % 100000) + 1000;
        await ReminderNotificationService().cancelNotification(notifId);

        if (mounted) {
          BrutalToast.showSuccess(context, 'LOAN MARKED AS CLOSED & PAID OFF');
        }
      },
    );
  }

  void _handleReopenLoan(AccountItem acc) {
    final balanceController = TextEditingController(
      text: (acc.creditLimit != null && acc.creditLimit! > 0)
          ? (acc.creditLimit! * 0.25).toStringAsFixed(0)
          : '50000',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RE-OPEN LOAN', style: BrutalTypography.headingSmall),
                  IconButton(
                    icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BrutalTextField(
                controller: balanceController,
                label: 'REMAINING PRINCIPAL BALANCE',
                hintText: '50000',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              BrutalButton(
                text: 'CONFIRM RE-OPEN',
                backgroundColor: BrutalColors.primaryYellow,
                textColor: BrutalColors.textDark,
                height: 48,
                onPressed: () {
                  final newBal = double.tryParse(balanceController.text.trim()) ?? 10000.0;
                  setState(() {
                    acc.isClosed = false;
                    acc.balance = newBal;
                    if (acc.creditLimit != null && acc.creditLimit! > 0) {
                      final repaid = (acc.creditLimit! > newBal) ? (acc.creditLimit! - newBal) : 0.0;
                      final pct = ((repaid / acc.creditLimit!) * 100).toStringAsFixed(1);
                      acc.subtext = 'REPAID: $pct%';
                    }
                  });
                  _saveAccounts();

                  // Reschedule EMI reminder if settings exist
                  if (acc.emiDueDay != null && (acc.emiAmount ?? 0) > 0) {
                    final authState = ref.read(authControllerProvider);
                    final currency = authState.user?.currencySymbol ?? '₹';
                    final notifId = (acc.id.hashCode.abs() % 100000) + 1000;
                    ReminderNotificationService().scheduleEmiReminder(
                      notificationId: notifId,
                      loanTitle: acc.title,
                      emiAmount: acc.emiAmount!,
                      dueDay: acc.emiDueDay!,
                      currency: currency,
                    );
                  }

                  Navigator.pop(ctx);
                  BrutalToast.showSuccess(context, 'LOAN RE-OPENED AS ACTIVE');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
