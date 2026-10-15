import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedAccount = 'HDFC Salaried';
  String _selectedDestination = 'Cash Vault';
  String _selectedCategory = 'Food & Dining';

  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _categories = [
    'Food & Dining',
    'Rent & Utilities',
    'Travel & Commute',
    'Shopping',
    'Health & Medical',
    'Entertainment',
    'Salary',
    'Freelance',
    'Investment',
    'Bills',
  ];

  final List<String> _customCategories = [];

  final List<String> _accounts = [
    'HDFC Salaried',
    'Cash Vault',
    'Infinia Metal',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final custom = await SecureStorageService.getCustomCategories();
    if (custom.isNotEmpty) {
      setState(() {
        _customCategories.addAll(custom);
        for (final c in custom) {
          if (!_categories.contains(c)) {
            _categories.add(c);
          }
        }
      });
    }
  }

  void _showAddCategoryDialog() {
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
                        Text('CUSTOM CATEGORIES', style: BrutalTypography.headingSmall),
                        IconButton(
                          icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BrutalTextField(
                      controller: catController,
                      label: 'NEW CATEGORY NAME',
                      hintText: 'e.g. Crypto & Stocks, Pet Care, Gym',
                    ),
                    const SizedBox(height: 14),
                    BrutalButton(
                      text: '+ ADD CATEGORY',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 44,
                      onPressed: () async {
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
                          _customCategories.add(val);
                          _selectedCategory = val;
                        });
                        SecureStorageService.saveCustomCategories(_customCategories);

                        catController.clear();
                        Navigator.pop(ctx);
                        BrutalToast.showSuccess(context, 'CATEGORY "$val" CREATED & SELECTED');
                      },
                    ),
                    if (_customCategories.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('YOUR CUSTOM CATEGORIES', style: BrutalTypography.label),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _customCategories.map((cat) {
                          return Container(
                            decoration: BoxDecoration(
                              color: BrutalColors.surfaceElevated,
                              border: Border.all(color: BrutalColors.border, width: 2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat, style: BrutalTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _categories.remove(cat);
                                      _customCategories.remove(cat);
                                      if (_selectedCategory == cat) {
                                        _selectedCategory = _categories.first;
                                      }
                                    });
                                    SecureStorageService.saveCustomCategories(_customCategories);
                                    setModalState(() {});
                                    BrutalToast.showWarning(context, 'Category "$cat" removed');
                                  },
                                  child: const Icon(Icons.close, size: 14, color: BrutalColors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_amountController.text.trim().isEmpty) {
      BrutalToast.showError(context, 'AMOUNT IS REQUIRED');
      return;
    }
    BrutalToast.showSuccess(context, 'TRANSACTION RECORDED');
    context.pop();
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
                            onTap: _showAddCategoryDialog,
                            child: Text(
                              '+ CUSTOM CATEGORY',
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
                            value: _selectedCategory,
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
                    Text(_selectedType == 'TRANSFER' ? 'TRANSFER FROM ACCOUNT' : 'PAYMENT ACCOUNT', style: BrutalTypography.label),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.border, width: 2.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAccount,
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
                            value: _selectedDestination,
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
