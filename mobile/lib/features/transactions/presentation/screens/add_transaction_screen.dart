import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _selectedType = 'EXPENSE'; // EXPENSE, INCOME, TRANSFER
  String _selectedAccount = '';
  String _selectedDestination = '';
  String _selectedCategory = '';

  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  List<String> _categories = [];
  List<String> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await SecureStorageService.getCategories();
    final accsRaw = await SecureStorageService.getAccounts();
    final accNames = accsRaw.map((a) => (a['title'] ?? 'Account').toString()).toList();

    if (!mounted) return;
    setState(() {
      _categories = cats;
      _accounts = accNames;

      if (_categories.isNotEmpty && !_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }
      if (_accounts.isNotEmpty && !_accounts.contains(_selectedAccount)) {
        _selectedAccount = _accounts.first;
      }
      if (_accounts.length > 1 && !_accounts.contains(_selectedDestination)) {
        _selectedDestination = _accounts[1];
      }
    });
  }

  void _showManageCategoriesDialog() {
    final catController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
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
                        Text('MANAGE CATEGORIES', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BrutalTextField(
                      controller: catController,
                      label: 'ADD NEW CATEGORY',
                      hintText: 'e.g. Groceries, Gym, Crypto, Subscriptions',
                    ),
                    const SizedBox(height: 14),
                    BrutalButton(
                      text: '+ ADD CATEGORY',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 44,
                      onPressed: () {
                        final val = catController.text.trim();
                        if (val.isEmpty) {
                          BrutalToast.showError(ctx, 'Category name cannot be empty');
                          return;
                        }
                        if (_categories.contains(val)) {
                          BrutalToast.showError(ctx, 'Category already exists');
                          return;
                        }

                        setState(() {
                          _categories.add(val);
                          _selectedCategory = val;
                        });
                        SecureStorageService.saveCategories(_categories);

                        catController.clear();
                        setModalState(() {});
                        BrutalToast.showSuccess(context, 'CATEGORY "$val" ADDED & SELECTED');
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('ACTIVE CATEGORIES (${_categories.length})', style: BrutalTypography.label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        return Container(
                          decoration: BoxDecoration(
                            color: _selectedCategory == cat ? BrutalColors.primaryYellow.withAlpha(51) : BrutalColors.surfaceElevated,
                            border: Border.all(
                              color: _selectedCategory == cat ? BrutalColors.primaryYellow : BrutalColors.border,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat, style: BrutalTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  if (_categories.length <= 1) {
                                    BrutalToast.showWarning(context, 'At least 1 category must remain');
                                    return;
                                  }
                                  setState(() {
                                    _categories.remove(cat);
                                    if (_selectedCategory == cat) {
                                      _selectedCategory = _categories.first;
                                    }
                                  });
                                  SecureStorageService.saveCategories(_categories);
                                  setModalState(() {});
                                  BrutalToast.showWarning(context, 'Category "$cat" deleted');
                                },
                                child: const Icon(Icons.close, size: 14, color: BrutalColors.red),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String accountType = 'BANK';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
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
                        Text('MANAGE ACCOUNTS', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BrutalTextField(
                      controller: nameController,
                      label: 'NEW ACCOUNT NAME',
                      hintText: 'e.g. HDFC Salary, SBI Savings, Cash Wallet',
                    ),
                    const SizedBox(height: 12),
                    BrutalTextField(
                      controller: balanceController,
                      label: 'CURRENT BALANCE (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Text('ACCOUNT TYPE', style: BrutalTypography.label),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTypeChip('BANK', 'BANK', BrutalColors.cyan, accountType, (t) => setModalState(() => accountType = t)),
                        const SizedBox(width: 6),
                        _buildTypeChip('CASH', 'CASH', BrutalColors.lime, accountType, (t) => setModalState(() => accountType = t)),
                        const SizedBox(width: 6),
                        _buildTypeChip('CREDIT_CARD', 'CARD', BrutalColors.hotPink, accountType, (t) => setModalState(() => accountType = t)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BrutalButton(
                      text: '+ CREATE & SELECT ACCOUNT',
                      backgroundColor: BrutalColors.cyan,
                      textColor: BrutalColors.textDark,
                      height: 44,
                      onPressed: () async {
                        final val = nameController.text.trim();
                        if (val.isEmpty) {
                          BrutalToast.showError(ctx, 'Account name cannot be empty');
                          return;
                        }
                        if (_accounts.contains(val)) {
                          BrutalToast.showError(ctx, 'Account already exists');
                          return;
                        }

                        final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        final currentVault = await SecureStorageService.getAccounts();
                        currentVault.add({
                          'id': 'acc_${DateTime.now().millisecondsSinceEpoch}',
                          'title': val,
                          'subtitle': '$accountType Account',
                          'balance': bal,
                          'type': accountType,
                          'digits': 'NEW',
                        });
                        await SecureStorageService.saveAccounts(currentVault);

                        if (!mounted) return;
                        setState(() {
                          _accounts.add(val);
                          _selectedAccount = val;
                        });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        BrutalToast.showSuccess(context, 'ACCOUNT "$val" CREATED & SELECTED');
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('CURRENT VAULT ACCOUNTS (${_accounts.length})', style: BrutalTypography.label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _accounts.map((acc) {
                        return Container(
                          decoration: BoxDecoration(
                            color: _selectedAccount == acc ? BrutalColors.cyan.withAlpha(51) : BrutalColors.surfaceElevated,
                            border: Border.all(
                              color: _selectedAccount == acc ? BrutalColors.cyan : BrutalColors.border,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(acc, style: BrutalTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  if (_accounts.length <= 1) {
                                    BrutalToast.showWarning(context, 'At least 1 account must remain in vault');
                                    return;
                                  }
                                  final currentVault = await SecureStorageService.getAccounts();
                                  currentVault.removeWhere((a) => (a['title'] ?? '') == acc);
                                  await SecureStorageService.saveAccounts(currentVault);

                                  if (!mounted) return;
                                  setState(() {
                                    _accounts.remove(acc);
                                    if (_selectedAccount == acc) {
                                      _selectedAccount = _accounts.first;
                                    }
                                    if (_selectedDestination == acc) {
                                      _selectedDestination = _accounts.length > 1 ? _accounts[1] : _accounts.first;
                                    }
                                  });
                                  setModalState(() {});
                                  if (mounted) {
                                    BrutalToast.showWarning(context, 'Account "$acc" removed from vault');
                                  }
                                },
                                child: const Icon(Icons.close, size: 14, color: BrutalColors.red),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  Widget _buildTypeChip(String type, String label, Color color, String currentType, ValueChanged<String> onSelected) {
    final isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : BrutalColors.surfaceElevated,
            border: Border.all(color: BrutalColors.border, width: 2),
          ),
          child: Text(
            label,
            style: BrutalTypography.sticker.copyWith(
              color: isSelected ? BrutalColors.textDark : BrutalColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_amountController.text.trim().isEmpty) {
      BrutalToast.showError(context, 'AMOUNT IS REQUIRED');
      return;
    }
    if (_selectedType != 'TRANSFER' && (_categories.isEmpty || _selectedCategory.isEmpty)) {
      BrutalToast.showError(context, 'PLEASE ADD & SELECT A CATEGORY FIRST');
      return;
    }
    if (_accounts.isEmpty || _selectedAccount.isEmpty) {
      BrutalToast.showError(context, 'PLEASE ADD & SELECT AN ACCOUNT FIRST');
      return;
    }
    if (_selectedType == 'TRANSFER' && (_accounts.length < 2 || _selectedDestination.isEmpty)) {
      BrutalToast.showError(context, 'TRANSFER REQUIRES AT LEAST 2 VAULT ACCOUNTS');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy, h:mm a').format(now);
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_selectedType == 'TRANSFER' ? 'Transfer to $_selectedDestination' : _selectedCategory);

    final accountField = _selectedType == 'TRANSFER'
        ? '$_selectedAccount -> $_selectedDestination'
        : _selectedAccount;

    final newTx = {
      'id': 'tx_${now.millisecondsSinceEpoch}',
      'title': title,
      'type': _selectedType,
      'category': _selectedType == 'TRANSFER' ? 'Transfer' : _selectedCategory,
      'account': accountField,
      'date': dateStr,
      'timestamp': now.toIso8601String(),
      'amount': amount,
      'note': _noteController.text.trim(),
    };

    await SecureStorageService.addTransaction(newTx);

    if (mounted) {
      BrutalToast.showSuccess(context, 'TRANSACTION RECORDED');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _selectedType == 'INCOME'
        ? BrutalColors.green
        : _selectedType == 'TRANSFER'
            ? BrutalColors.cyan
            : BrutalColors.red;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: const BrutalAppBar(
        title: 'NEW LEDGER ENTRY',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector Chips
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton('EXPENSE', 'EXPENSE', BrutalColors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton('INCOME', 'INCOME', BrutalColors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeButton('TRANSFER', 'TRANSFER', BrutalColors.cyan),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              BrutalCard(
                backgroundColor: BrutalColors.surface,
                borderColor: BrutalColors.border,
                shadowColor: typeColor,
                shadowOffset: 6.0,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Field
                    BrutalTextField(
                      controller: _amountController,
                      label: 'Amount (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.currency_rupee, color: BrutalColors.primaryYellow),
                    ),
                    const SizedBox(height: 16),

                    BrutalTextField(
                      controller: _titleController,
                      label: 'Transaction Title',
                      hintText: 'e.g. Grocery store, Client payment',
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType != 'TRANSFER') ...[
                      // Category Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CATEGORY', style: BrutalTypography.label),
                          InkWell(
                            onTap: _showManageCategoriesDialog,
                            child: Text(
                              '+ MANAGE',
                              style: BrutalTypography.sticker.copyWith(
                                color: BrutalColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categories.contains(_selectedCategory) ? _selectedCategory : null,
                            hint: Text(
                              'TAP + MANAGE TO ADD CATEGORY',
                              style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            isExpanded: true,
                            dropdownColor: BrutalColors.surface,
                            icon: const Icon(Icons.arrow_drop_down, color: BrutalColors.textPrimary),
                            style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Source Account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType == 'TRANSFER' ? 'TRANSFER FROM ACCOUNT' : 'PAYMENT ACCOUNT',
                          style: BrutalTypography.label,
                        ),
                        InkWell(
                          onTap: _showAddAccountDialog,
                          child: Text(
                            '+ MANAGE',
                            style: BrutalTypography.sticker.copyWith(
                              color: BrutalColors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.border, width: 2.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _accounts.contains(_selectedAccount) ? _selectedAccount : null,
                          hint: Text(
                            'TAP + MANAGE TO ADD ACCOUNT',
                            style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          isExpanded: true,
                          dropdownColor: BrutalColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: BrutalColors.textPrimary),
                          style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                          items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAccount = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType == 'TRANSFER') ...[
                      // Destination Account
                      Text('TRANSFER TO ACCOUNT', style: BrutalTypography.label),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _accounts.contains(_selectedDestination) ? _selectedDestination : null,
                            hint: Text(
                              'TAP + MANAGE TO ADD ACCOUNT',
                              style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            isExpanded: true,
                            dropdownColor: BrutalColors.surface,
                            icon: const Icon(Icons.arrow_drop_down, color: BrutalColors.textPrimary),
                            style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                            items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDestination = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    BrutalTextField(
                      controller: _noteController,
                      label: 'Notes / Remarks (Optional)',
                      hintText: 'Add description or tags...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    BrutalButton(
                      text: 'RECORD TRANSACTION',
                      backgroundColor: typeColor,
                      textColor: _selectedType == 'EXPENSE' ? BrutalColors.textPrimary : BrutalColors.textDark,
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

  Widget _buildTypeButton(String type, String label, Color accent) {
    final isSelected = _selectedType == type;
    return BrutalButton(
      text: label,
      backgroundColor: isSelected ? accent : BrutalColors.surfaceElevated,
      textColor: isSelected
          ? (type == 'EXPENSE' ? BrutalColors.textPrimary : BrutalColors.textDark)
          : BrutalColors.textSecondary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      offset: isSelected ? 4.0 : 2.0,
      height: 44,
      onPressed: () => setState(() => _selectedType = type),
    );
  }
}
