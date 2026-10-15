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
import '../../../../core/widgets/brutal_progress_bar.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final currency = authState.user?.currencySymbol ?? '₹';

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'ACCOUNTS VAULT',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            onPressed: () => context.push('/add-account'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bank Accounts section
            _buildSectionHeader('BANK ACCOUNTS (1)', BrutalColors.cyan),
            const SizedBox(height: 10),
            _buildAccountCard(
              title: 'HDFC Salaried Account',
              subtitle: 'HDFC Bank • Last 4: 4821',
              balance: 425000.0,
              currency: currency,
              accentColor: BrutalColors.cyan,
              type: 'BANK',
            ),
            const SizedBox(height: 20),

            // Cash Wallets section
            _buildSectionHeader('CASH WALLETS (1)', BrutalColors.lime),
            const SizedBox(height: 10),
            _buildAccountCard(
              title: 'Physical Cash Vault',
              subtitle: 'Safe Box & Pocket Wallet',
              balance: 24500.0,
              currency: currency,
              accentColor: BrutalColors.lime,
              type: 'CASH',
            ),
            const SizedBox(height: 20),

            // Credit Cards section
            _buildSectionHeader('CREDIT CARDS (1)', BrutalColors.hotPink),
            const SizedBox(height: 10),
            BrutalCard(
              backgroundColor: BrutalColors.surface,
              borderColor: BrutalColors.border,
              shadowColor: BrutalColors.hotPink,
              shadowOffset: 5.0,
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
                      Text('•9920', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Infinia Metal Card', style: BrutalTypography.headingSmall),
                  Text('HDFC Bank • Limit: ₹5,00,000', style: BrutalTypography.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OUTSTANDING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                          Text(
                            CurrencyFormatter.format(48500.0, symbol: currency, showDecimals: false),
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
                  const SizedBox(height: 6),
                  Text('UTILIZATION: 9.7% • DUE 22ND OF MONTH', style: BrutalTypography.sticker.copyWith(fontSize: 10, color: BrutalColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loans section
            _buildSectionHeader('LOANS & LIABILITIES (1)', BrutalColors.orange),
            const SizedBox(height: 10),
            BrutalCard(
              backgroundColor: BrutalColors.surface,
              borderColor: BrutalColors.border,
              shadowColor: BrutalColors.orange,
              shadowOffset: 5.0,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BrutalChip(
                        label: 'AUTO LOAN',
                        backgroundColor: BrutalColors.orange,
                        textColor: BrutalColors.textDark,
                        shadowOffset: 0,
                      ),
                      Text('SBI BANK', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Vehicle Loan #49281', style: BrutalTypography.headingSmall),
                  Text('Principal: ₹5,00,000 @ 8.4% • 36 Months Tenure', style: BrutalTypography.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('REMAINING', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                      Text(
                        CurrencyFormatter.format(356300.0, symbol: currency, showDecimals: false),
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
                  BrutalButton(
                    text: 'MARK EMI PAID (₹14,500)',
                    height: 42,
                    backgroundColor: BrutalColors.surfaceElevated,
                    textColor: BrutalColors.primaryYellow,
                    onPressed: () {},
                  ),
                ],
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

  Widget _buildAccountCard({
    required String title,
    required String subtitle,
    required double balance,
    required String currency,
    required Color accentColor,
    required String type,
  }) {
    return BrutalCard(
      backgroundColor: BrutalColors.surface,
      borderColor: BrutalColors.border,
      shadowColor: accentColor,
      shadowOffset: 5.0,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrutalChip(
                  label: type,
                  backgroundColor: accentColor,
                  textColor: BrutalColors.textDark,
                  shadowOffset: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
                const SizedBox(height: 6),
                Text(title, style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textMuted)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(balance, symbol: currency, showDecimals: false),
            style: BrutalTypography.amountMedium,
          ),
        ],
      ),
    );
  }
}
