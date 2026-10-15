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
import '../../../../core/storage/secure_storage_service.dart';
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

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final list = await SecureStorageService.getTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = list;
    });
  }

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

    final filtered = _transactions.where((item) {
      if (_selectedFilter != 'ALL' && item['type'] != _selectedFilter) return false;
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final title = (item['title'] ?? '').toString().toLowerCase();
        final category = (item['category'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !category.contains(query)) return false;
      }
      if (_selectedDateRange != null && item['timestamp'] != null) {
        DateTime? txDate;
        if (item['timestamp'] is DateTime) {
          txDate = item['timestamp'] as DateTime;
        } else {
          txDate = DateTime.tryParse(item['timestamp'].toString());
        }
        if (txDate != null) {
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
          if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
        }
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
            onPressed: () async {
              await context.push('/add-transaction');
              _loadTransactions();
            },
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
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 48, color: BrutalColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _transactions.isEmpty ? 'NO TRANSACTIONS RECORDED YET' : 'NO TRANSACTIONS MATCH FILTER',
                              style: BrutalTypography.headingSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _transactions.isEmpty
                                  ? 'Tap the + button above to log your first ledger entry.'
                                  : 'Try adjusting your search or date filters.',
                              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
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
                            '$prefix${CurrencyFormatter.format((item['amount'] as num?)?.toDouble() ?? 0.0, symbol: currency, showDecimals: false)}',
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
