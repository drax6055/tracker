import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'ALL'; // ALL, EXPENSE, INCOME, TRANSFER
  final _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> _demoTransactions = [
    {
      'title': 'Salary Credit',
      'type': 'INCOME',
      'category': 'Salary',
      'account': 'HDFC Salaried',
      'date': '14 Oct 2026, 10:30 AM',
      'timestamp': DateTime(2026, 10, 14, 10, 30),
      'amount': 125000.0,
      'color': BrutalColors.green,
    },
    {
      'title': 'Whole Foods Groceries',
      'type': 'EXPENSE',
      'category': 'Food & Dining',
      'account': 'Infinia Metal',
      'date': '13 Oct 2026, 8:15 PM',
      'timestamp': DateTime(2026, 10, 13, 20, 15),
      'amount': 3450.0,
      'color': BrutalColors.red,
    },
    {
      'title': 'ATM Cash Withdrawal',
      'type': 'TRANSFER',
      'category': 'Transfer',
      'account': 'HDFC -> Cash Vault',
      'date': '12 Oct 2026, 4:00 PM',
      'timestamp': DateTime(2026, 10, 12, 16, 0),
      'amount': 10000.0,
      'color': BrutalColors.cyan,
    },
    {
      'title': 'Uber Airport Taxi',
      'type': 'EXPENSE',
      'category': 'Travel',
      'account': 'Cash Vault',
      'date': '12 Oct 2026, 2:45 PM',
      'timestamp': DateTime(2026, 10, 12, 14, 45),
      'amount': 850.0,
      'color': BrutalColors.red,
    },
    {
      'title': 'Freelance Web Design',
      'type': 'INCOME',
      'category': 'Freelance',
      'account': 'HDFC Salaried',
      'date': '11 Oct 2026, 6:30 PM',
      'timestamp': DateTime(2026, 10, 11, 18, 30),
      'amount': 45000.0,
      'color': BrutalColors.green,
    },
    {
      'title': 'Auto Loan Monthly EMI',
      'type': 'EXPENSE',
      'category': 'Loan EMI',
      'account': 'HDFC Salaried',
      'date': '10 Oct 2026, 9:00 AM',
      'timestamp': DateTime(2026, 10, 10, 9, 0),
      'amount': 14500.0,
      'color': BrutalColors.orange,
    },
  ];

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(2026, 10, 1),
            end: DateTime(2026, 10, 15),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currency = authState.user?.currencySymbol ?? '₹';

    final filtered = _demoTransactions.where((item) {
      if (_selectedFilter != 'ALL' && item['type'] != _selectedFilter) return false;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final title = (item['title'] as String).toLowerCase();
        final category = (item['category'] as String).toLowerCase();
        if (!title.contains(query) && !category.contains(query)) return false;
      }
      if (_selectedDateRange != null) {
        final txDate = item['timestamp'] as DateTime;
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'LEDGER LOGS',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDateRange != null ? BrutalColors.primaryYellow : BrutalColors.textPrimary,
              size: 26,
            ),
            tooltip: 'Filter Date Range',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            onPressed: () => context.push('/add-transaction'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter chips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BrutalColors.border, width: 2.5)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                    cursorColor: BrutalColors.primaryYellow,
                    decoration: InputDecoration(
                      hintText: 'SEARCH TRANSACTIONS...',
                      prefixIcon: const Icon(Icons.search, color: BrutalColors.textPrimary),
                      filled: true,
                      fillColor: BrutalColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFilterChip('ALL', BrutalColors.primaryYellow),
                      const SizedBox(width: 8),
                      _buildFilterChip('EXPENSE', BrutalColors.red),
                      const SizedBox(width: 8),
                      _buildFilterChip('INCOME', BrutalColors.green),
                      const SizedBox(width: 8),
                      _buildFilterChip('TRANSFER', BrutalColors.cyan),
                    ],
                  ),
                  if (_selectedDateRange != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceElevated,
                        border: Border.all(color: BrutalColors.primaryYellow, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: BrutalColors.primaryYellow,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.date_range, size: 16, color: BrutalColors.primaryYellow),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('dd MMM').format(_selectedDateRange!.start).toUpperCase()} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end).toUpperCase()}',
                                style: BrutalTypography.sticker.copyWith(
                                  color: BrutalColors.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedDateRange = null),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: BrutalColors.red,
                                border: Border.all(color: BrutalColors.border, width: 1.5),
                              ),
                              child: const Icon(Icons.close, size: 14, color: BrutalColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Transactions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isIncome = item['type'] == 'INCOME';
                  final isTransfer = item['type'] == 'TRANSFER';
                  final prefix = isIncome ? '+' : isTransfer ? '⇄ ' : '-';
                  final amountColor = isIncome
                      ? BrutalColors.green
                      : isTransfer
                          ? BrutalColors.cyan
                          : BrutalColors.red;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: BrutalCard(
                      backgroundColor: BrutalColors.surface,
                      borderColor: BrutalColors.border,
                      shadowOffset: 4.0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: amountColor,
                              border: Border.all(color: BrutalColors.border, width: 2.0),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward
                                  : isTransfer
                                      ? Icons.swap_horiz
                                      : Icons.arrow_upward,
                              color: BrutalColors.textDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item['category']} • ${item['account']}',
                                  style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                                ),
                                Text(
                                  item['date'],
                                  style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$prefix${CurrencyFormatter.format(item['amount'], symbol: currency, showDecimals: false)}',
                            style: BrutalTypography.amountSmall.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, Color accent) {
    final isSelected = _selectedFilter == label;
    return BrutalChip(
      label: label,
      backgroundColor: isSelected ? accent : BrutalColors.surfaceElevated,
      textColor: isSelected ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSelected ? 3.0 : 0.0,
      onTap: () => setState(() => _selectedFilter = label),
    );
  }
}
