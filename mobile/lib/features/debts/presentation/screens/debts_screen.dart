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
import '../../../../core/storage/secure_storage_service.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _selectedTab = 'BORROWED'; // BORROWED (To Pay) or LENT (To Receive)

  List<Map<String, dynamic>> _debts = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final list = await SecureStorageService.getDebts();
    if (!mounted) return;
    setState(() {
      _debts = list;
    });
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
          Text('Remaining: ₹${debt['remainingAmount']}', style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: paymentController,
            keyboardType: TextInputType.number,
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
      onConfirm: () {
        final paidAmt = double.tryParse(paymentController.text.trim()) ?? 0.0;
        if (paidAmt > 0) {
          final currentRemaining = (debt['remainingAmount'] as num?)?.toDouble() ?? 0.0;
          final newRemaining = (currentRemaining - paidAmt).clamp(0.0, double.infinity);
          debt['remainingAmount'] = newRemaining;
          if (newRemaining == 0.0) {
            debt['status'] = 'SETTLED';
          } else {
            debt['status'] = 'PARTIALLY_PAID';
          }
          SecureStorageService.saveDebts(_debts);
          setState(() {});
          BrutalToast.showSuccess(context, 'PAYMENT LOGGED SUCCESSFULLY');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currency = authState.user?.currencySymbol ?? '₹';

    final filtered = _debts.where((d) => d['type'] == _selectedTab).toList();

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'PEOPLE LEDGER',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            onPressed: () async {
              await context.push('/add-debt');
              _loadDebts();
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

            // Debts List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 48, color: BrutalColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _debts.isEmpty ? 'NO DEBT RECORDS YET' : 'NO ${_selectedTab == 'BORROWED' ? 'PAYABLES' : 'RECEIVABLES'} FOUND',
                              style: BrutalTypography.headingSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _debts.isEmpty
                                  ? 'Tap the + button to track money you owe or are owed.'
                                  : 'Switch between tabs or add a new record.',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                debt['person'],
                                style: BrutalTypography.headingSmall,
                              ),
                              BrutalChip(
                                label: debt['status'],
                                backgroundColor: isSettled ? BrutalColors.green : accent,
                                textColor: BrutalColors.textDark,
                                shadowOffset: 0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            debt['notes'],
                            style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ORIGINAL', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                                  Text(
                                    CurrencyFormatter.format(debt['originalAmount'], symbol: currency, showDecimals: false),
                                    style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.textSecondary),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('REMAINING', style: BrutalTypography.sticker.copyWith(color: accent)),
                                  Text(
                                    CurrencyFormatter.format(debt['remainingAmount'], symbol: currency, showDecimals: false),
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
                              Text('DUE DATE: ${debt['dueDate']}', style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted)),
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
          ],
        ),
      ),
    );
  }
}
