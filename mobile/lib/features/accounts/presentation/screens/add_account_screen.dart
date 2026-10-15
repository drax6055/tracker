import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../../../../core/widgets/brutal_toggle.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  String _selectedType = 'BANK'; // BANK, CASH, CREDIT_CARD, LOAN
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _digitsController = TextEditingController();
  final _limitController = TextEditingController();
  final _emiAmountController = TextEditingController();
  bool _includeInNetWorth = true;

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

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      BrutalToast.showError(context, 'ACCOUNT NAME IS REQUIRED');
      return;
    }

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final bankName = _bankNameController.text.trim();
    final digits = _digitsController.text.trim();

    String subtitle = bankName.isNotEmpty ? bankName : 'Active Account';
    if (digits.isNotEmpty) subtitle += ' • Last 4: $digits';

    final existing = await SecureStorageService.getAccounts();
    existing.add({
      'id': 'acc_${DateTime.now().millisecondsSinceEpoch}',
      'title': name,
      'subtitle': subtitle,
      'balance': balance,
      'type': _selectedType,
      'digits': digits.isNotEmpty ? digits : 'ACC',
    });
    await SecureStorageService.saveAccounts(existing);

    if (mounted) {
      BrutalToast.showSuccess(context, 'ACCOUNT CREATED SUCCESSFULLY');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                shadowColor: BrutalColors.primaryYellow,
                shadowOffset: 6.0,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrutalTextField(
                      controller: _nameController,
                      label: 'Account Label / Nickname',
                      hintText: 'e.g. HDFC Salary Vault',
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType != 'CASH') ...[
                      BrutalTextField(
                        controller: _bankNameController,
                        label: _selectedType == 'LOAN' ? 'Lender Bank / Institution' : 'Bank Name',
                        hintText: 'e.g. HDFC Bank, SBI, ICICI',
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedType == 'BANK' || _selectedType == 'CREDIT_CARD') ...[
                      BrutalTextField(
                        controller: _digitsController,
                        label: 'Last 4 Digits',
                        hintText: 'e.g. 4821',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                    ],

                    BrutalTextField(
                      controller: _balanceController,
                      label: _selectedType == 'LOAN'
                          ? 'Remaining Loan Amount'
                          : _selectedType == 'CREDIT_CARD'
                              ? 'Current Outstanding Balance'
                              : 'Current Balance',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.currency_rupee, color: BrutalColors.textPrimary),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType == 'CREDIT_CARD') ...[
                      BrutalTextField(
                        controller: _limitController,
                        label: 'Total Credit Limit',
                        hintText: '500000',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.currency_rupee, color: BrutalColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedType == 'LOAN') ...[
                      BrutalTextField(
                        controller: _emiAmountController,
                        label: 'Monthly EMI Amount',
                        hintText: '14500',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.currency_rupee, color: BrutalColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Include in net worth toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('INCLUDE IN NET WORTH', style: BrutalTypography.label),
                        BrutalToggle(
                          value: _includeInNetWorth,
                          onChanged: (val) => setState(() => _includeInNetWorth = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    BrutalButton(
                      text: 'SAVE ACCOUNT',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 52,
                      onPressed: _handleSubmit,
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
