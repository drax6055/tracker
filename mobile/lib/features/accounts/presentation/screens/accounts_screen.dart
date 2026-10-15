import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AccountItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.balance,
    required this.type,
    required this.accentColor,
    required this.digits,
    this.subtext,
  });
}

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  late List<AccountItem> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = [
      AccountItem(
        id: 'acc_1',
        title: 'HDFC Salaried Account',
        subtitle: 'HDFC Bank • Last 4: 4821',
        balance: 425000.0,
        type: 'BANK',
        accentColor: BrutalColors.cyan,
        digits: '4821',
      ),
      AccountItem(
        id: 'acc_2',
        title: 'Physical Cash Vault',
        subtitle: 'Safe Box & Pocket Wallet',
        balance: 24500.0,
        type: 'CASH',
        accentColor: BrutalColors.lime,
        digits: 'WAL',
      ),
      AccountItem(
        id: 'acc_3',
        title: 'Infinia Metal Card',
        subtitle: 'HDFC Bank • Limit: ₹5,00,000',
        balance: 48500.0,
        type: 'CREDIT_CARD',
        accentColor: BrutalColors.hotPink,
        digits: '9920',
        subtext: 'UTILIZATION: 9.7% • DUE 22ND OF MONTH',
      ),
      AccountItem(
        id: 'acc_4',
        title: 'Vehicle Loan #49281',
        subtitle: 'Principal: ₹5,00,000 @ 8.4% • 36 Months',
        balance: 356300.0,
        type: 'LOAN',
        accentColor: BrutalColors.orange,
        digits: 'SBI',
        subtext: 'REMAINING: 28% • EMI ₹14,500',
      ),
    ];
  }

  void _showEditAccountDialog(AccountItem account) {
    final titleController = TextEditingController(text: account.title);
    final subtitleController = TextEditingController(text: account.subtitle);
    final balanceController = TextEditingController(text: account.balance.toStringAsFixed(0));
    String selectedType = account.type;

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
                      label: 'CURRENT BALANCE',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                        if (newTitle.isEmpty) {
                          BrutalToast.showError(ctx, 'Account name cannot be empty');
                          return;
                        }

                        setState(() {
                          account.title = newTitle;
                          account.subtitle = newSubtitle;
                          account.balance = newBalance;
                          account.type = selectedType;
                          if (selectedType == 'BANK') account.accentColor = BrutalColors.cyan;
                          if (selectedType == 'CASH') account.accentColor = BrutalColors.lime;
                          if (selectedType == 'CREDIT_CARD') account.accentColor = BrutalColors.hotPink;
                          if (selectedType == 'LOAN') account.accentColor = BrutalColors.orange;
                        });

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
        BrutalToast.showWarning(context, '${account.title.toUpperCase()} PURGED FROM VAULT');
      },
    );
  }

  void _showAddAccountDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'BANK';

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
                        Text('ADD NEW VAULT ACCOUNT', style: BrutalTypography.headingSmall),
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
                      hintText: 'e.g., Savings Account',
                    ),
                    const SizedBox(height: 12),
                    BrutalTextField(
                      controller: subtitleController,
                      label: 'INSTITUTION / DETAILS',
                      hintText: 'e.g., SBI • Last 4: 9012',
                    ),
                    const SizedBox(height: 12),
                    BrutalTextField(
                      controller: balanceController,
                      label: 'STARTING BALANCE',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      text: '+ CREATE ACCOUNT',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 48,
                      onPressed: () {
                        final title = titleController.text.trim();
                        final subtitle = subtitleController.text.trim();
                        final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;

                        if (title.isEmpty) {
                          BrutalToast.showError(ctx, 'Please enter an account name');
                          return;
                        }

                        Color c = BrutalColors.cyan;
                        if (selectedType == 'CASH') c = BrutalColors.lime;
                        if (selectedType == 'CREDIT_CARD') c = BrutalColors.hotPink;
                        if (selectedType == 'LOAN') c = BrutalColors.orange;

                        setState(() {
                          _accounts.add(
                            AccountItem(
                              id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              subtitle: subtitle.isNotEmpty ? subtitle : 'Active Account',
                              balance: balance,
                              type: selectedType,
                              accentColor: c,
                              digits: 'NEW',
                            ),
                          );
                        });

                        Navigator.pop(ctx);
                        BrutalToast.showSuccess(context, 'NEW VAULT ACCOUNT CREATED');
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
            onPressed: _showAddAccountDialog,
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
                        onPressed: _showAddAccountDialog,
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
                      BrutalChip(
                        label: acc.type,
                        backgroundColor: acc.accentColor,
                        textColor: BrutalColors.textDark,
                        shadowOffset: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                const BrutalChip(
                  label: 'CREDIT CARD',
                  backgroundColor: BrutalColors.hotPink,
                  textColor: BrutalColors.textPrimary,
                  shadowOffset: 0,
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
                      CurrencyFormatter.format(451500.0, symbol: currency, showDecimals: false),
                      style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.lime),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const BrutalProgressBar(
              value: 0.097,
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
                const BrutalChip(
                  label: 'LOAN',
                  backgroundColor: BrutalColors.orange,
                  textColor: BrutalColors.textDark,
                  shadowOffset: 0,
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
                Text('REMAINING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                Text(
                  CurrencyFormatter.format(acc.balance, symbol: currency, showDecimals: false),
                  style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.orange),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const BrutalProgressBar(
              value: 0.28,
              height: 12,
              fillColor: BrutalColors.orange,
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
}
