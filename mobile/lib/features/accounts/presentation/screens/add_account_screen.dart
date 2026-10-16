import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
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
          if (emi > 0) {
            subtitle = '$lender • EMI: ${CurrencyFormatter.format(emi, symbol: currency, showDecimals: false)}/mo';
            subtext = 'MONTHLY EMI: ${CurrencyFormatter.format(emi, symbol: currency, showDecimals: false)}';
          } else {
            subtitle = '$lender • Liability';
          }
          break;

        default:
          subtitle = bankName.isNotEmpty ? bankName : 'Active Account';
      }

      final existing = await SecureStorageService.getAccounts();

      existing.add({
        'id': 'acc_${DateTime.now().millisecondsSinceEpoch}',
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
        'includeInNetWorth': _includeInNetWorth,
        'subtext': subtext,
      });

      await SecureStorageService.saveAccounts(existing);

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
              // Type Selector Chips
              Text('SELECT ACCOUNT TYPE', style: BrutalTypography.label),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeChip('BANK', 'BANK ACCOUNT', BrutalColors.cyan),
                    const SizedBox(width: 8),
                    _buildTypeChip('CASH', 'CASH WALLET', BrutalColors.lime),
                    const SizedBox(width: 8),
                    _buildTypeChip('CREDIT_CARD', 'CREDIT CARD', BrutalColors.hotPink),
                    const SizedBox(width: 8),
                    _buildTypeChip('LOAN', 'LOAN / DEBT', BrutalColors.orange),
                  ],
                ),
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
                    ],

                    // Monthly EMI (for loans)
                    if (_selectedType == 'LOAN') ...[
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

  Widget _buildTypeChip(String type, String label, Color accent) {
    final isSelected = _selectedType == type;
    return BrutalChip(
      label: label,
      backgroundColor: isSelected ? accent : BrutalColors.surfaceElevated,
      textColor: isSelected ? BrutalColors.textDark : BrutalColors.textPrimary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSelected ? 3.0 : 0.0,
      onTap: () => setState(() => _selectedType = type),
    );
  }
}
