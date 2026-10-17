import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/reminder_notification_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../../../../core/widgets/brutal_toggle.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  String _selectedType = 'BANK'; // BANK, CASH, CREDIT_CARD, LOAN
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _digitsController = TextEditingController();
  final _limitController = TextEditingController();
  final _emiAmountController = TextEditingController();
  final _emiDueDayController = TextEditingController();
  bool _includeInNetWorth = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    _digitsController.dispose();
    _limitController.dispose();
    _emiAmountController.dispose();
    _emiDueDayController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(String currency) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      BrutalToast.showError(context, 'ACCOUNT NAME IS REQUIRED');
      return;
    }

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final bankName = _bankNameController.text.trim();
    final digits = _digitsController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiAmountController.text.trim()) ?? 0.0;
    final dueDay = int.tryParse(_emiDueDayController.text.trim());

    setState(() => _isSaving = true);

    try {
      // Build dynamic subtitle & subtext based on category
      String subtitle;
      String? subtext;

      switch (_selectedType) {
        case 'BANK':
          final bankPart = bankName.isNotEmpty ? bankName : 'Bank Account';
          final digitsPart = digits.isNotEmpty ? ' • Last 4: $digits' : '';
          subtitle = '$bankPart$digitsPart';
          break;

        case 'CASH':
          subtitle = bankName.isNotEmpty ? bankName : 'Physical Cash & Wallet';
          break;

        case 'CREDIT_CARD':
          final cardBank = bankName.isNotEmpty ? bankName : 'Credit Card';
          if (limit > 0) {
            subtitle = '$cardBank • Limit: ${CurrencyFormatter.format(limit, symbol: currency, showDecimals: false)}';
            final util = limit > 0 ? ((balance / limit) * 100).toStringAsFixed(1) : '0';
            subtext = 'UTILIZATION: $util%';
          } else if (digits.isNotEmpty) {
            subtitle = '$cardBank • Last 4: $digits';
          } else {
            subtitle = '$cardBank • Revolving Credit';
          }
          break;

        case 'LOAN':
          final lender = bankName.isNotEmpty ? bankName : 'Loan Account';
          final duePart = (dueDay != null && dueDay > 0 && dueDay <= 31) ? ' • Due ${dueDay}th' : '';
          if (emi > 0) {
            subtitle = '$lender • EMI: ${CurrencyFormatter.format(emi, symbol: currency, showDecimals: false)}/mo$duePart';
            final repaid = (limit > balance) ? (limit - balance) : 0.0;
            final pct = limit > 0 ? ((repaid / limit) * 100).toStringAsFixed(1) : '0';
            subtext = 'REPAID: $pct% • DUE ${dueDay ?? 10}TH OF MONTH';
          } else {
            subtitle = '$lender • Liability$duePart';
          }
          break;

        default:
          subtitle = bankName.isNotEmpty ? bankName : 'Active Account';
      }

      final existing = await SecureStorageService.getAccounts();
      final newAccId = 'acc_${DateTime.now().millisecondsSinceEpoch}';

      existing.add({
        'id': newAccId,
        'title': name,
        'subtitle': subtitle,
        'balance': balance,
        'type': _selectedType,
        'digits': digits.isNotEmpty
            ? digits
            : (_selectedType == 'CASH'
                ? 'WAL'
                : (_selectedType == 'LOAN' ? 'LOAN' : 'ACC')),
        'creditLimit': limit > 0 ? limit : null,
        'emiAmount': emi > 0 ? emi : null,
        'emiDueDay': (dueDay != null && dueDay > 0 && dueDay <= 31) ? dueDay : null,
        'isClosed': false,
        'includeInNetWorth': _includeInNetWorth,
        'subtext': subtext,
      });

      await SecureStorageService.saveAccounts(existing);

      // Schedule monthly recurring EMI / Bill reminder notification
      if (_selectedType == 'LOAN' && dueDay != null && dueDay > 0 && dueDay <= 31 && emi > 0) {
        final notifId = (newAccId.hashCode.abs() % 100000) + 1000;
        await ReminderNotificationService().scheduleEmiReminder(
          notificationId: notifId,
          loanTitle: name,
          emiAmount: emi,
          dueDay: dueDay,
          currency: currency,
        );
      } else if (_selectedType == 'CREDIT_CARD' && dueDay != null && dueDay > 0 && dueDay <= 31) {
        final notifId = (newAccId.hashCode.abs() % 100000) + 2000;
        await ReminderNotificationService().scheduleCreditCardReminder(
          notificationId: notifId,
          cardTitle: name,
          outstandingAmount: balance > 0 ? balance : (emi > 0 ? emi : 0.0),
          dueDay: dueDay,
          currency: currency,
        );
      }

      if (mounted) {
        BrutalToast.showSuccess(context, 'ACCOUNT ADDED TO VAULT');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        BrutalToast.showError(context, 'ERROR SAVING ACCOUNT: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currency = auth.user?.currencySymbol ?? '₹';

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: const BrutalAppBar(
        title: 'CREATE NEW ACCOUNT',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector Chips (2x2 Grid so all 4 options including LOAN are 100% visible)
              Text('SELECT ACCOUNT TYPE', style: BrutalTypography.label),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(width: cardWidth, child: _buildTypeCard('BANK', 'BANK ACCOUNT', Icons.account_balance, BrutalColors.cyan)),
                      SizedBox(width: cardWidth, child: _buildTypeCard('CASH', 'CASH WALLET', Icons.account_balance_wallet, BrutalColors.lime)),
                      SizedBox(width: cardWidth, child: _buildTypeCard('CREDIT_CARD', 'CREDIT CARD', Icons.credit_card, BrutalColors.hotPink)),
                      SizedBox(width: cardWidth, child: _buildTypeCard('LOAN', 'LOAN / DEBT', Icons.handshake, BrutalColors.orange)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              BrutalCard(
                backgroundColor: BrutalColors.surface,
                borderColor: BrutalColors.border,
                shadowColor: _getTypeColor(_selectedType),
                shadowOffset: 6.0,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Account Name
                    BrutalTextField(
                      controller: _nameController,
                      label: 'Account Label / Nickname',
                      hintText: _selectedType == 'BANK'
                          ? 'e.g. HDFC Salary Vault'
                          : (_selectedType == 'CASH'
                              ? 'e.g. Daily Pocket Cash'
                              : (_selectedType == 'CREDIT_CARD'
                                  ? 'e.g. Infinia Metal Card'
                                  : 'e.g. Car Loan #49281')),
                    ),
                    const SizedBox(height: 16),

                    // Bank / Lender Institution Name
                    if (_selectedType != 'CASH') ...[
                      BrutalTextField(
                        controller: _bankNameController,
                        label: _selectedType == 'LOAN'
                            ? 'Lender Bank / Institution'
                            : 'Bank / Card Issuer',
                        hintText: 'e.g. HDFC Bank, SBI, ICICI',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Last 4 Digits
                    if (_selectedType == 'BANK' || _selectedType == 'CREDIT_CARD') ...[
                      BrutalTextField(
                        controller: _digitsController,
                        label: 'Last 4 Digits / Identifier',
                        hintText: 'e.g. 4821',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Balance field
                    BrutalTextField(
                      controller: _balanceController,
                      label: _selectedType == 'LOAN'
                          ? 'Remaining Principal / Balance'
                          : _selectedType == 'CREDIT_CARD'
                              ? 'Current Outstanding Balance'
                              : 'Current Balance',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Center(
                        widthFactor: 1,
                        child: Text(
                          currency,
                          style: BrutalTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Credit Limit (for credit cards)
                    if (_selectedType == 'CREDIT_CARD') ...[
                      BrutalTextField(
                        controller: _limitController,
                        label: 'Total Credit Limit',
                        hintText: '500000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Text(
                            currency,
                            style: BrutalTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalTextField(
                        controller: _emiDueDayController,
                        label: 'Bill / Payment Due Day of Month (1 - 31)',
                        hintText: 'e.g. 5, 15, 22',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.calendar_month_outlined,
                          color: BrutalColors.hotPink,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalTextField(
                        controller: _emiAmountController,
                        label: 'Monthly Minimum / EMI Amount (Optional)',
                        hintText: 'e.g. 5000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Text(
                            currency,
                            style: BrutalTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Monthly EMI & Total Principal (for loans)
                    if (_selectedType == 'LOAN') ...[
                      BrutalTextField(
                        controller: _limitController,
                        label: 'Total Loan Principal (Borrowed Amount)',
                        hintText: '500000',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Text(
                            currency,
                            style: BrutalTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalTextField(
                        controller: _emiAmountController,
                        label: 'Monthly EMI Amount',
                        hintText: '14500',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Text(
                            currency,
                            style: BrutalTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalTextField(
                        controller: _emiDueDayController,
                        label: 'EMI Due Day of Month (1 - 31)',
                        hintText: 'e.g. 5, 10, 25',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.calendar_month_outlined,
                          color: BrutalColors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Include in net worth toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.borderDim, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'INCLUDE IN NET WORTH',
                                  style: BrutalTypography.label.copyWith(fontSize: 12),
                                ),
                              ),
                              BrutalToggle(
                                value: _includeInNetWorth,
                                onChanged: (val) => setState(() => _includeInNetWorth = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _includeInNetWorth
                                ? 'Account balance directly factors into your Net Worth calculation.'
                                : 'Account balance will be tracked separately and EXCLUDED from Net Worth.',
                            style: BrutalTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: _includeInNetWorth ? BrutalColors.textSecondary : BrutalColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    BrutalButton(
                      text: _isSaving ? 'CREATING ACCOUNT...' : '+ SAVE ACCOUNT TO VAULT',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 52,
                      isLoading: _isSaving,
                      onPressed: () => _handleSubmit(currency),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'BANK':
        return BrutalColors.cyan;
      case 'CASH':
        return BrutalColors.lime;
      case 'CREDIT_CARD':
        return BrutalColors.hotPink;
      case 'LOAN':
        return BrutalColors.orange;
      default:
        return BrutalColors.primaryYellow;
    }
  }

  Widget _buildTypeCard(String type, String label, IconData icon, Color accent) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: BrutalCard(
        backgroundColor: isSelected ? accent : BrutalColors.surfaceElevated,
        borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
        shadowColor: isSelected ? BrutalColors.border : Colors.transparent,
        shadowOffset: isSelected ? 3.0 : 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? BrutalColors.textDark : BrutalColors.textPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: BrutalTypography.sticker.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? BrutalColors.textDark : BrutalColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
