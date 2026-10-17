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
import '../../../../core/widgets/brutal_toast.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ledger_app/features/debts/presentation/controllers/debts_controller.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _selectedTab = 'BORROWED'; // BORROWED (To Pay) or LENT (To Receive)

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(debtsProvider.notifier).loadDebts();
    });
  }

  void _confirmDelete(Map<String, dynamic> debt) {
    BrutalDialog.show(
      context: context,
      title: 'DELETE RECORD',
      content: Text(
        'Are you sure you want to delete the debt record for "${debt['person']}"?',
        style: BrutalTypography.bodyMedium,
      ),
      confirmText: 'DELETE',
      confirmColor: BrutalColors.red,
      onConfirm: () async {
        final id = (debt['id'] ?? '').toString();
        await ref.read(debtsProvider.notifier).deleteDebt(id);
        if (mounted) {
          BrutalToast.showSuccess(context, 'RECORD DELETED');
        }
      },
    );
  }

  void _showPartialPaymentDialog(Map<String, dynamic> debt) {
    final paymentController = TextEditingController();
    BrutalDialog.show(
      context: context,
      title: 'RECORD PAYMENT',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Person: ${debt['person']}', style: BrutalTypography.bodyMedium),
          Text(
            'Remaining: ₹${debt['remainingAmount']}',
            style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: paymentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: BrutalTypography.bodyMedium,
            cursorColor: BrutalColors.primaryYellow,
            decoration: const InputDecoration(
              hintText: 'Enter payment amount...',
              prefixIcon: Icon(Icons.currency_rupee, color: BrutalColors.textPrimary),
            ),
          ),
        ],
      ),
      confirmText: 'SETTLE AMOUNT',
      onConfirm: () async {
        final paidAmt = double.tryParse(paymentController.text.trim()) ?? 0.0;
        if (paidAmt > 0) {
          final id = (debt['id'] ?? '').toString();
          await ref.read(debtsProvider.notifier).recordPayment(id, paidAmt);
          if (mounted) {
            BrutalToast.showSuccess(context, 'PAYMENT LOGGED SUCCESSFULLY');
          }
        } else {
          if (mounted) {
            BrutalToast.showError(context, 'ENTER A VALID AMOUNT');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currency = authState.user?.currencySymbol ?? '₹';
    final allDebts = ref.watch(debtsProvider);

    final filtered = allDebts.where((d) => (d['type'] ?? 'BORROWED') == _selectedTab).toList();

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'PEOPLE LEDGER',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            onPressed: () {
              context.push('/add-debt');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Header Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BrutalColors.border, width: 2.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      text: 'I HAVE TO PAY',
                      backgroundColor: _selectedTab == 'BORROWED' ? BrutalColors.orange : BrutalColors.surfaceElevated,
                      textColor: _selectedTab == 'BORROWED' ? BrutalColors.textDark : BrutalColors.textSecondary,
                      borderColor: _selectedTab == 'BORROWED' ? BrutalColors.border : BrutalColors.borderDim,
                      height: 44,
                      onPressed: () => setState(() => _selectedTab = 'BORROWED'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrutalButton(
                      text: 'I HAVE TO RECEIVE',
                      backgroundColor: _selectedTab == 'LENT' ? BrutalColors.lime : BrutalColors.surfaceElevated,
                      textColor: _selectedTab == 'LENT' ? BrutalColors.textDark : BrutalColors.textSecondary,
                      borderColor: _selectedTab == 'LENT' ? BrutalColors.border : BrutalColors.borderDim,
                      height: 44,
                      onPressed: () => setState(() => _selectedTab = 'LENT'),
                    ),
                  ),
                ],
              ),
            ),

            // Debts List with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                color: BrutalColors.primaryYellow,
                backgroundColor: BrutalColors.surface,
                onRefresh: () async {
                  await ref.read(debtsProvider.notifier).loadDebts();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_alt_outlined, size: 48, color: BrutalColors.textSecondary),
                                    const SizedBox(height: 12),
                                    Text(
                                      allDebts.isEmpty
                                          ? 'NO DEBT RECORDS YET'
                                          : 'NO ${_selectedTab == 'BORROWED' ? 'PAYABLES' : 'RECEIVABLES'} FOUND',
                                      style: BrutalTypography.headingSmall,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      allDebts.isEmpty
                                          ? 'Tap the + button to track money you owe or are owed.'
                                          : 'Switch between tabs or tap + to add a record.',
                                      style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final debt = filtered[index];
                          final isSettled = debt['status'] == 'SETTLED';
                          final accent = _selectedTab == 'BORROWED' ? BrutalColors.orange : BrutalColors.lime;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: BrutalCard(
                              backgroundColor: BrutalColors.surface,
                              borderColor: BrutalColors.border,
                              shadowColor: accent,
                              shadowOffset: 4.0,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (debt['person'] ?? '').toString(),
                                          style: BrutalTypography.headingSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: BrutalColors.textSecondary),
                                        tooltip: 'Edit Record',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          context.push('/add-debt', extra: debt);
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: BrutalColors.red),
                                        tooltip: 'Delete Record',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDelete(debt),
                                      ),
                                      const SizedBox(width: 10),
                                      BrutalChip(
                                        label: (debt['status'] ?? 'PENDING').toString(),
                                        backgroundColor: isSettled ? BrutalColors.green : accent,
                                        textColor: BrutalColors.textDark,
                                        shadowOffset: 0,
                                      ),
                                    ],
                                  ),
                                  if ((debt['notes'] ?? '').toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      debt['notes'].toString(),
                                      style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ORIGINAL', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                                          Text(
                                            CurrencyFormatter.format(debt['originalAmount'] ?? 0, symbol: currency, showDecimals: false),
                                            style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('REMAINING', style: BrutalTypography.sticker.copyWith(color: accent)),
                                          Text(
                                            CurrencyFormatter.format(debt['remainingAmount'] ?? 0, symbol: currency, showDecimals: false),
                                            style: BrutalTypography.amountMedium.copyWith(color: accent),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'DUE DATE: ${debt['dueDate'] ?? 'N/A'}',
                                        style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted),
                                      ),
                                      if (!isSettled)
                                        BrutalButton(
                                          text: '+ RECORD PAYMENT',
                                          height: 36,
                                          backgroundColor: BrutalColors.surfaceElevated,
                                          textColor: BrutalColors.primaryYellow,
                                          onPressed: () => _showPartialPaymentDialog(debt),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
