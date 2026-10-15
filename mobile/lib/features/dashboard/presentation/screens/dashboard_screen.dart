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
import '../../../../core/widgets/brutal_toast.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Demo / local state representations until full backend sync
  final double netWorth = 845200.0;
  final double thisMonthIncome = 125000.0;
  final double thisMonthExpense = 48500.0;
  final double toPay = 18000.0;
  final double toReceive = 35000.0;

  bool _isMasked = false;
  List<Map<String, dynamic>> _vaultAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadVaultAccounts();
  }

  Future<void> _loadVaultAccounts() async {
    final accs = await SecureStorageService.getAccounts();
    if (!mounted) return;
    setState(() {
      _vaultAccounts = accs;
    });
  }

  String _formatAmount(double amount, String currency, {bool showDecimals = true}) {
    if (_isMasked) return '$currency ***';
    return CurrencyFormatter.format(amount, symbol: currency, showDecimals: showDecimals);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final currency = user?.currencySymbol ?? '₹';
    final savings = thisMonthIncome - thisMonthExpense;
    final savingsRate = (thisMonthIncome > 0) ? (savings / thisMonthIncome * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'LEDGER // ${user?.name ?? "OPERATOR"}',
        actions: [
          IconButton(
            icon: Icon(
              _isMasked ? Icons.visibility_off : Icons.visibility,
              color: _isMasked ? BrutalColors.primaryYellow : BrutalColors.textPrimary,
            ),
            tooltip: _isMasked ? 'Show Figures' : 'Hide Figures (***)',
            onPressed: () {
              setState(() => _isMasked = !_isMasked);
              BrutalToast.showInfo(
                context,
                _isMasked
                    ? 'SAFETY MODE: FIGURES MASKED (***)'
                    : 'SAFETY MODE: FIGURES VISIBLE',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: BrutalColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: BrutalColors.primaryYellow,
          backgroundColor: BrutalColors.surface,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Net Worth Card
                BrutalCard(
                  backgroundColor: BrutalColors.surface,
                  borderColor: BrutalColors.border,
                  shadowColor: BrutalColors.primaryYellow,
                  shadowOffset: 6.0,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('NET WORTH', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                          InkWell(
                            onTap: () => setState(() => _isMasked = !_isMasked),
                            child: BrutalChip(
                              label: _isMasked ? '🔒 *** MASKED' : '👁️ VISIBLE',
                              backgroundColor: _isMasked ? BrutalColors.primaryYellow : BrutalColors.lime,
                              textColor: BrutalColors.textDark,
                              shadowOffset: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatAmount(netWorth, currency),
                          style: BrutalTypography.amountHero.copyWith(
                            fontSize: 40,
                            color: BrutalColors.primaryYellow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: BrutalColors.borderDim, thickness: 1.5),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAssetLiabPill('ASSETS', 1250000, BrutalColors.green, currency),
                          _buildAssetLiabPill('LIABILITIES', 404800, BrutalColors.red, currency),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. This-Month Income, Expense, Savings Cards
                Row(
                  children: [
                    Expanded(
                      child: BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.green,
                        shadowOffset: 4.0,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('INFLOW', style: BrutalTypography.sticker.copyWith(color: BrutalColors.green)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatAmount(thisMonthIncome, currency, showDecimals: false),
                                style: BrutalTypography.amountMedium.copyWith(color: BrutalColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.red,
                        shadowOffset: 4.0,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('OUTFLOW', style: BrutalTypography.sticker.copyWith(color: BrutalColors.red)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatAmount(thisMonthExpense, currency, showDecimals: false),
                                style: BrutalTypography.amountMedium.copyWith(color: BrutalColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.cyan,
                        shadowOffset: 4.0,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('SAVINGS', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _isMasked ? '***%' : '$savingsRate%',
                                style: BrutalTypography.amountMedium.copyWith(color: BrutalColors.primaryYellow),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. To Pay & To Receive Summary Strips
                Row(
                  children: [
                    Expanded(
                      child: BrutalCard(
                        backgroundColor: BrutalColors.surfaceElevated,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.orange,
                        shadowOffset: 4.0,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: BrutalColors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TO PAY', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                                  Text(
                                    _formatAmount(toPay, currency, showDecimals: false),
                                    style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.orange),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrutalCard(
                        backgroundColor: BrutalColors.surfaceElevated,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.lime,
                        shadowOffset: 4.0,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_downward, color: BrutalColors.lime, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('RECEIVABLE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
                                  Text(
                                    _formatAmount(toReceive, currency, showDecimals: false),
                                    style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.lime),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Accounts Strip (Horizontal Scroll)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ACCOUNTS', style: BrutalTypography.headingMedium),
                    GestureDetector(
                      onTap: () async {
                        await context.push('/accounts');
                        _loadVaultAccounts();
                      },
                      child: Text(
                        'VIEW ALL (${_vaultAccounts.length}) →',
                        style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_vaultAccounts.isEmpty)
                  GestureDetector(
                    onTap: () async {
                      await context.push('/accounts');
                      _loadVaultAccounts();
                    },
                    child: Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: BrutalColors.surface,
                        border: Border.all(color: BrutalColors.border, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: BrutalColors.border, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, color: BrutalColors.primaryYellow, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            '+ ADD YOUR FIRST VAULT ACCOUNT',
                            style: BrutalTypography.sticker.copyWith(
                              color: BrutalColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 128,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _vaultAccounts.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final acc = _vaultAccounts[idx];
                        final type = (acc['type'] ?? 'BANK').toString();
                        Color accent = BrutalColors.cyan;
                        if (type == 'CASH') accent = BrutalColors.lime;
                        if (type == 'CREDIT_CARD') accent = BrutalColors.hotPink;
                        if (type == 'LOAN') accent = BrutalColors.orange;
                        return _buildHorizontalAccountCard(
                          name: (acc['title'] ?? 'Account').toString(),
                          type: type,
                          balance: (acc['balance'] as num?)?.toDouble() ?? 0.0,
                          digits: (acc['digits'] ?? '').toString(),
                          accent: accent,
                          currency: currency,
                          subtext: acc['subtext']?.toString(),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // 5. Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT LEDGER', style: BrutalTypography.headingMedium),
                    GestureDetector(
                      onTap: () => context.push('/transactions'),
                      child: Text(
                        'VIEW ALL →',
                        style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildTransactionTile(
                  title: 'Salary Deposit',
                  category: 'Income',
                  account: 'HDFC Salaried',
                  date: 'Today, 10:30 AM',
                  amount: 125000.0,
                  isIncome: true,
                  currency: currency,
                ),
                _buildTransactionTile(
                  title: 'Whole Foods Grocery',
                  category: 'Food',
                  account: 'Infinia Metal',
                  date: 'Yesterday, 8:15 PM',
                  amount: 3450.0,
                  isIncome: false,
                  currency: currency,
                ),
                _buildTransactionTile(
                  title: 'Uber Ride - Airport',
                  category: 'Travel',
                  account: 'Cash Vault',
                  date: '12 Oct, 2:45 PM',
                  amount: 850.0,
                  isIncome: false,
                  currency: currency,
                ),
                _buildTransactionTile(
                  title: 'Car Loan Monthly EMI',
                  category: 'Loan EMI',
                  account: 'HDFC Salaried',
                  date: '10 Oct, 9:00 AM',
                  amount: 14500.0,
                  isIncome: false,
                  currency: currency,
                ),

                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          ),
        ),
      ),
      // Neo-brutalist Big Square Quick-Add FAB
      floatingActionButton: GestureDetector(
        onTap: () => _showQuickAddModal(context),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: BrutalColors.primaryYellow,
            border: Border.all(color: BrutalColors.border, width: 3.0),
            boxShadow: const [
              BoxShadow(
                color: BrutalColors.border,
                offset: Offset(4.0, 4.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 34, color: BrutalColors.textDark),
        ),
      ),
    );
  }

  Widget _buildAssetLiabPill(String label, double val, Color color, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BrutalTypography.sticker.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          _formatAmount(val, currency, showDecimals: false),
          style: BrutalTypography.amountSmall.copyWith(color: BrutalColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildHorizontalAccountCard({
    required String name,
    required String type,
    required double balance,
    required String digits,
    required Color accent,
    required String currency,
    String? subtext,
  }) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowColor: accent,
        shadowOffset: 4.0,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BrutalChip(
                  label: type,
                  backgroundColor: accent,
                  textColor: BrutalColors.textDark,
                  shadowOffset: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
                Text('•$digits', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textMuted)),
              ],
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAmount(balance, currency, showDecimals: false),
                  style: BrutalTypography.amountMedium.copyWith(fontSize: 16),
                ),
                if (subtext != null)
                  Text(
                    subtext,
                    style: BrutalTypography.sticker.copyWith(fontSize: 9, color: accent),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile({
    required String title,
    required String category,
    required String account,
    required String date,
    required double amount,
    required bool isIncome,
    required String currency,
  }) {
    final amountColor = isIncome ? BrutalColors.green : BrutalColors.red;
    final prefix = isIncome ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: BrutalCard(
        backgroundColor: BrutalColors.surface,
        borderColor: BrutalColors.border,
        shadowOffset: 3.0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIncome ? BrutalColors.green : BrutalColors.surfaceElevated,
                border: Border.all(color: BrutalColors.border, width: 2.0),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                color: isIncome ? BrutalColors.textDark : BrutalColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutalTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$category • $account • $date',
                    style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isMasked ? '$prefix$currency ***' : '$prefix${CurrencyFormatter.format(amount, symbol: currency, showDecimals: false)}',
              style: BrutalTypography.amountSmall.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrutalColors.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 3.0),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('QUICK ACTIONS', style: BrutalTypography.headingMedium),
                const SizedBox(height: 16),
                BrutalButton(
                  text: '+ NEW EXPENSE / INCOME',
                  backgroundColor: BrutalColors.primaryYellow,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction');
                  },
                ),
                const SizedBox(height: 12),
                BrutalButton(
                  text: 'TRANSFER (ACCOUNT TO ACCOUNT)',
                  backgroundColor: BrutalColors.cyan,
                  textColor: BrutalColors.textDark,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/add-transaction');
                  },
                ),
                const SizedBox(height: 12),
                BrutalButton(
                  text: 'RECORD DEBT (BORROW / LEND)',
                  backgroundColor: BrutalColors.lime,
                  textColor: BrutalColors.textDark,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/add-debt');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
