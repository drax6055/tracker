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
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

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
    String selectedType = account.type;
    bool includeInNetWorth = account.includeInNetWorth;

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
                    ],
                    if (selectedType == 'LOAN') ...[
                      BrutalTextField(
                        controller: emiController,
                        label: 'MONTHLY EMI AMOUNT',
                        hintText: '14500',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                        if (newTitle.isEmpty) {
                          BrutalToast.showError(ctx, 'Account name cannot be empty');
                          return;
                        }

                        setState(() {
                          account.title = newTitle;
                          account.subtitle = newSubtitle;
                          account.balance = newBalance;
                          account.type = selectedType;
                          account.creditLimit = newLimit;
                          account.emiAmount = newEmi;
                          account.includeInNetWorth = includeInNetWorth;
                          if (selectedType == 'BANK') account.accentColor = BrutalColors.cyan;
                          if (selectedType == 'CASH') account.accentColor = BrutalColors.lime;
                          if (selectedType == 'CREDIT_CARD') account.accentColor = BrutalColors.hotPink;
                          if (selectedType == 'LOAN') account.accentColor = BrutalColors.orange;
                        });
                        _saveAccounts();

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

  Widget _buildLoanItem(AccountItem acc, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowColor: BrutalColors.orange,
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
                      label: 'LOAN',
                      backgroundColor: BrutalColors.orange,
                      textColor: BrutalColors.textDark,
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
                Text(acc.digits, style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
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
                    Text('REMAINING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                    Text(
                      CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.orange),
                    ),
                  ],
                ),
                if (acc.emiAmount != null && acc.emiAmount! > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('MONTHLY EMI', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                      Text(
                        '${CurrencyFormatter.format(acc.emiAmount!, symbol: currency, showDecimals: false)}/mo',
                        style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.cyan),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const BrutalProgressBar(
              value: 0.28,
              height: 12,
              fillColor: BrutalColors.orange,
            ),
            if (acc.subtext != null) ...[
              const SizedBox(height: 6),
              Text(acc.subtext!, style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted)),
            ],
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
}
