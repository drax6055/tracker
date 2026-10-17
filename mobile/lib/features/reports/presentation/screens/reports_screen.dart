import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ledger_app/features/transactions/presentation/controllers/transactions_controller.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_toast.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedRange = 'MONTH'; // WEEK, MONTH, YEAR, CUSTOM
  DateTimeRange? _selectedDateRange;
  bool _isGeneratingPdf = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isDemo = false;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final txs = await SecureStorageService.getTransactions();
    final demo = await SecureStorageService.isCurrentUserDemo();
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _isDemo = demo;
      _isLoading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
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
      setState(() {
        _selectedDateRange = picked;
        _selectedRange = 'CUSTOM';
      });
    }
  }

  /// Performs the actual PDF export / preview once the ad reward is earned.
  Future<void> _handleExportPdf({bool openPreview = false}) async {
    if (_isGeneratingPdf) return;
    if (mounted) setState(() => _isGeneratingPdf = true);

    try {
      if (mounted) BrutalToast.showSuccess(context, 'GENERATING AUDIT PDF REPORT...');
      final auth = ref.read(authControllerProvider);
      final user = auth.user;
      final period = _selectedDateRange != null
          ? '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
          : (_selectedRange == 'WEEK'
              ? 'CURRENT WEEK'
              : (_selectedRange == 'YEAR' ? 'YEAR ${DateTime.now().year}' : 'THIS MONTH'));

      if (openPreview) {
        await PdfReportService.openPrintPreview(
          userName: user?.name ?? 'Operator',
          userEmail: user?.email ?? '',
          currencySymbol: user?.currencySymbol ?? '₹',
          period: period,
        );
      } else {
        await PdfReportService.exportAndDownloadPdf(
          userName: user?.name ?? 'Operator',
          userEmail: user?.email ?? '',
          currencySymbol: user?.currencySymbol ?? '₹',
          period: period,
        );
      }

      if (mounted) BrutalToast.showSuccess(context, openPreview ? 'REPORT PREVIEW READY' : 'PDF SAVED SUCCESSFULLY');
    } catch (e) {
      if (mounted) BrutalToast.showError(context, 'COULD NOT GENERATE PDF: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ─── Ad-wall dialog ──────────────────────────────────────────────────────────

  /// Shows the support dialog, then simulates a rewarded video ad.
  /// On reward earned → automatically triggers [onAdRewarded].
  void _showAdWallDialog({
    required bool openPreview,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _AdWallDialog(
        openPreview: openPreview,
        onAdRewarded: () {
          // Dialog closes itself, then we run the action
          _handleExportPdf(openPreview: openPreview);
        },
      ),
    );
  }

  // ─── Bottom-sheet export options ─────────────────────────────────────────────

  void _showExportOptionsModal() {
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
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BrutalColors.primaryYellow,
                        border: Border.all(color: BrutalColors.border, width: 2),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: BrutalColors.textDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPORT FINANCIAL REPORT', style: BrutalTypography.headingSmall),
                          Text(
                            'A short ad supports this free app.',
                            style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Download option
                _ExportOptionTile(
                  icon: Icons.download_rounded,
                  title: 'DOWNLOAD PDF',
                  subtitle: 'Save report to your device',
                  accentColor: BrutalColors.primaryYellow,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAdWallDialog(openPreview: false);
                  },
                ),
                const SizedBox(height: 10),
                // Preview option
                _ExportOptionTile(
                  icon: Icons.preview_rounded,
                  title: 'PREVIEW / PRINT',
                  subtitle: 'Open report in PDF viewer',
                  accentColor: BrutalColors.cyan,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAdWallDialog(openPreview: true);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_transactions.isEmpty) return [];
    if (_selectedDateRange != null) {
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      return _transactions.where((t) {
        final rawTs = t['timestamp'];
        DateTime? dt;
        if (rawTs is DateTime) {
          dt = rawTs;
        } else if (rawTs != null) {
          dt = DateTime.tryParse(rawTs.toString());
        }
        if (dt == null) return true;
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) && dt.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(transactionsProvider, (_, next) => _loadReportData());

    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final currency = user?.currencySymbol ?? '₹';

    final activeTxs = _filteredTransactions;
    final hasNoData = !_isDemo && activeTxs.isEmpty;

    // Aggregate metrics
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    final Map<String, double> categoryExpenses = {};
    final List<Map<String, dynamic>> expenseTxs = [];

    for (final t in activeTxs) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = (t['type'] ?? 'EXPENSE').toString();
      if (type == 'INCOME') {
        totalIncome += amt;
      } else if (type == 'EXPENSE') {
        totalExpense += amt;
        final cat = (t['category'] ?? 'General').toString();
        categoryExpenses[cat] = (categoryExpenses[cat] ?? 0.0) + amt;
        expenseTxs.add(t);
      }
    }

    final netSavings = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'FINANCIAL INTELLIGENCE',
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BrutalColors.primaryYellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter Range chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRangeChip('WEEK', 'THIS WEEK'),
                          const SizedBox(width: 8),
                          _buildRangeChip('MONTH', 'THIS MONTH'),
                          const SizedBox(width: 8),
                          _buildRangeChip('YEAR', 'THIS YEAR'),
                          const SizedBox(width: 8),
                          BrutalChip(
                            label: '📅 CUSTOM DATES',
                            backgroundColor: _selectedRange == 'CUSTOM' ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
                            textColor: _selectedRange == 'CUSTOM' ? BrutalColors.textDark : BrutalColors.textSecondary,
                            borderColor: _selectedRange == 'CUSTOM' ? BrutalColors.border : BrutalColors.borderDim,
                            shadowOffset: _selectedRange == 'CUSTOM' ? 3.0 : 0.0,
                            onTap: _pickDateRange,
                          ),
                        ],
                      ),
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
                                  'FILTER: ${DateFormat('dd MMM').format(_selectedDateRange!.start).toUpperCase()} — ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end).toUpperCase()}',
                                  style: BrutalTypography.sticker.copyWith(
                                    color: BrutalColors.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedDateRange = null;
                                _selectedRange = 'MONTH';
                              }),
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
                    const SizedBox(height: 20),

                    // Empty State for clean real accounts with zero entries
                    if (hasNoData) ...[
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: BrutalColors.surface,
                          border: Border.all(color: BrutalColors.border, width: 3.0),
                          boxShadow: const [
                            BoxShadow(color: BrutalColors.primaryYellow, offset: Offset(5, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.insights, size: 54, color: BrutalColors.primaryYellow),
                            const SizedBox(height: 16),
                            Text(
                              'NO FINANCIAL INTELLIGENCE DATA YET',
                              style: BrutalTypography.headingSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Log your daily income and expense transactions in the ledger to automatically generate real-time cashflow analytics, category spending breakdowns, and AI-ready audit curves.',
                              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            BrutalButton(
                              text: '+ RECORD YOUR FIRST ENTRY',
                              backgroundColor: BrutalColors.primaryYellow,
                              textColor: BrutalColors.textDark,
                              height: 48,
                              onPressed: () async {
                                await context.push('/add-transaction');
                                _loadReportData();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      // Dynamic Summary Stat Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricMiniCard('TOTAL INFLOW', totalIncome, BrutalColors.green, currency),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricMiniCard('TOTAL OUTFLOW', totalExpense, BrutalColors.red, currency),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceElevated,
                          border: Border.all(color: BrutalColors.border, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NET CASHFLOW', style: BrutalTypography.label),
                            Text(
                              '${netSavings >= 0 ? '+' : ''}${CurrencyFormatter.format(netSavings, symbol: currency)}',
                              style: BrutalTypography.headingSmall.copyWith(
                                color: netSavings >= 0 ? BrutalColors.green : BrutalColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Grouped Bar Chart: Income vs Expense
                      BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.primaryYellow,
                        shadowOffset: 5.0,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('INCOME VS EXPENSE', style: BrutalTypography.headingSmall),
                                Row(
                                  children: [
                                    Container(width: 10, height: 10, color: BrutalColors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'IN',
                                      style: BrutalTypography.sticker.copyWith(
                                        fontSize: 10,
                                        color: BrutalColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(width: 10, height: 10, color: BrutalColors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OUT',
                                      style: BrutalTypography.sticker.copyWith(
                                        fontSize: 10,
                                        color: BrutalColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 180,
                              child: _buildDynamicBarChart(totalIncome, totalExpense),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Category Breakdown Donut / Pie
                      BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.hotPink,
                        shadowOffset: 5.0,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EXPENSE BY CATEGORY', style: BrutalTypography.headingSmall),
                            const SizedBox(height: 16),
                            if (categoryExpenses.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'NO EXPENSES RECORDED IN THIS TIMEFRAME',
                                    style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
                                  ),
                                ),
                              )
                            else
                              _buildDynamicPieChart(categoryExpenses, totalExpense, currency),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Daily Spending Trend Line Chart
                      BrutalCard(
                        backgroundColor: BrutalColors.surface,
                        borderColor: BrutalColors.border,
                        shadowColor: BrutalColors.lime,
                        shadowOffset: 5.0,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SPENDING TREND', style: BrutalTypography.headingSmall),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 150,
                              child: _buildDynamicLineChart(expenseTxs),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Export button
                    BrutalButton(
                      text: 'EXPORT COMPREHENSIVE PDF REPORT',
                      backgroundColor: BrutalColors.primaryYellow,
                      textColor: BrutalColors.textDark,
                      height: 52,
                      isLoading: _isGeneratingPdf,
                      onPressed: _showExportOptionsModal,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricMiniCard(String label, double amount, Color accent, String currency) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrutalColors.surface,
        border: Border.all(color: BrutalColors.border, width: 2),
        boxShadow: [
          BoxShadow(color: accent, offset: const Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BrutalTypography.label.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount, symbol: currency, showDecimals: false),
            style: BrutalTypography.headingSmall.copyWith(color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBarChart(double totalIncome, double totalExpense) {
    if (_isDemo && _transactions.length >= 6) {
      // Demo dataset 5-month timeline for Bruce Wayne
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 140,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) {
                  const titles = ['JUN', 'JUL', 'AUG', 'SEP', 'OCT'];
                  if (val.toInt() < titles.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        titles[val.toInt()],
                        style: BrutalTypography.sticker.copyWith(
                          fontSize: 11,
                          color: BrutalColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: BrutalColors.border, width: 2.0),
            ),
          ),
          barGroups: [
            _makeGroupData(0, 95, 40),
            _makeGroupData(1, 110, 52),
            _makeGroupData(2, 85, 38),
            _makeGroupData(3, 130, 65),
            _makeGroupData(4, 125, 48),
          ],
        ),
      );
    }

    // Dynamic real data bar chart
    final inThousands = totalIncome / 1000;
    final outThousands = totalExpense / 1000;
    final maxVal = (inThousands > outThousands ? inThousands : outThousands).clamp(10.0, 100000.0) * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                if (val.toInt() == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('FLOW', style: BrutalTypography.sticker.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(bottom: BorderSide(color: BrutalColors.border, width: 2.0)),
        ),
        barGroups: [
          _makeGroupData(0, inThousands, outThousands),
        ],
      ),
    );
  }

  Widget _buildDynamicPieChart(Map<String, double> categoryExpenses, double totalExpense, String currency) {
    final colors = [
      BrutalColors.primaryYellow,
      BrutalColors.hotPink,
      BrutalColors.cyan,
      BrutalColors.lime,
      BrutalColors.orange,
      BrutalColors.purple,
      BrutalColors.green,
    ];

    final sorted = categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];

    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final color = colors[i % colors.length];
      final pct = totalExpense > 0 ? (entry.value / totalExpense * 100).round() : 0;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '$pct%',
          radius: 36,
          titleStyle: BrutalTypography.sticker.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );

      legends.add(_buildLegendItem('${entry.key} ($pct%)', color));
    }

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: legends,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLineChart(List<Map<String, dynamic>> expenseTxs) {
    if (_isDemo && expenseTxs.length >= 4) {
      return LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(bottom: BorderSide(color: BrutalColors.border, width: 2.0)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 1.2),
                FlSpot(1, 3.5),
                FlSpot(2, 0.8),
                FlSpot(3, 4.2),
                FlSpot(4, 2.1),
                FlSpot(5, 5.8),
                FlSpot(6, 3.4),
              ],
              isCurved: false,
              color: BrutalColors.lime,
              barWidth: 3.5,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      );
    }

    if (expenseTxs.isEmpty) {
      return Center(
        child: Text('NO SPENDING CURVE AVAILABLE', style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < expenseTxs.length; i++) {
      final amt = ((expenseTxs[i]['amount'] as num?)?.toDouble() ?? 0.0) / 1000;
      spots.add(FlSpot(i.toDouble(), amt));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(bottom: BorderSide(color: BrutalColors.border, width: 2.0)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: BrutalColors.lime,
            barWidth: 3.5,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barsSpace: 6,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: BrutalColors.green,
          width: 16,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          toY: y2,
          color: BrutalColors.red,
          width: 16,
          borderRadius: BorderRadius.zero,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: BrutalTypography.bodySmall.copyWith(
                fontSize: 11,
                color: BrutalColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChip(String range, String label) {
    final isSelected = _selectedRange == range;
    return BrutalChip(
      label: label,
      backgroundColor: isSelected ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
      textColor: isSelected ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSelected ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSelected ? 3.0 : 0.0,
      onTap: () => setState(() => _selectedRange = range),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Export Option Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BrutalColors.surfaceElevated,
          border: Border.all(color: BrutalColors.border, width: 2),
          boxShadow: [BoxShadow(color: accentColor, offset: const Offset(4, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BrutalTypography.label.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor,
                border: Border.all(color: BrutalColors.border, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, size: 14, color: BrutalColors.textDark),
                  SizedBox(width: 4),
                  Text('WATCH AD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BrutalColors.textDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ad-Wall Dialog (stateful — manages the simulated rewarded-video lifecycle)
// ═══════════════════════════════════════════════════════════════════════════════

enum _AdState { support, loading, playing, skipped, failed, rewarded }

class _AdWallDialog extends StatefulWidget {
  final bool openPreview;
  final VoidCallback onAdRewarded;

  const _AdWallDialog({required this.openPreview, required this.onAdRewarded});

  @override
  State<_AdWallDialog> createState() => _AdWallDialogState();
}

class _AdWallDialogState extends State<_AdWallDialog> with SingleTickerProviderStateMixin {
  _AdState _state = _AdState.support;
  int _countdown = 15;
  bool _canSkip = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  // ── Simulated ad lifecycle ───────────────────────────────────────────────────

  Future<void> _startAd() async {
    setState(() => _state = _AdState.loading);

    // If Google Mobile Ads SDK is initialized on this device, attempt real AdMob Rewarded Ad
    if (AdService.instance.isInitialized) {
      AdService.instance.showRewardedAd(
        onUserEarnedReward: () {
          if (!mounted) return;
          _progressController.stop();
          setState(() => _state = _AdState.rewarded);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            Navigator.of(context).pop();
            widget.onAdRewarded();
          });
        },
        onAdDismissedWithoutReward: () {
          if (!mounted) return;
          setState(() => _state = _AdState.skipped);
        },
        onAdFailed: (error) {
          debugPrint('[ReportsScreen] AdMob notice: $error. Falling back to in-app simulator.');
          if (!mounted) return;
          // Gracefully fall back to the interactive in-app player
          _runInAppSimulator();
        },
      );
      return;
    }

    // Direct in-app interactive simulation fallback
    await _runInAppSimulator();
  }

  Future<void> _runInAppSimulator() async {
    if (!mounted) return;
    setState(() => _state = _AdState.loading);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Phase 2: Playing
    setState(() {
      _state = _AdState.playing;
      _countdown = 15;
      _canSkip = false;
    });
    _progressController.forward(from: 0);

    // Tick countdown every second
    for (int i = 15; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (_state != _AdState.playing) return;
      setState(() {
        _countdown = i - 1;
        if (i <= 10) _canSkip = true; // Skip unlocks after 5 s
      });
    }
    if (!mounted) return;
    if (_state != _AdState.playing) return;

    // Phase 3: Reward earned
    _progressController.stop();
    setState(() => _state = _AdState.rewarded);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onAdRewarded();
  }

  void _skipAd() {
    _progressController.stop();
    setState(() => _state = _AdState.skipped);
  }

  void _closeDialog() => Navigator.of(context).pop();

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _state == _AdState.support || _state == _AdState.skipped || _state == _AdState.failed,
      child: Dialog(
        backgroundColor: BrutalColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: BrutalColors.border, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentState(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case _AdState.support:
        return _buildSupportScreen();
      case _AdState.loading:
        return _buildLoadingScreen();
      case _AdState.playing:
        return _buildPlayingScreen();
      case _AdState.skipped:
        return _buildSkippedScreen();
      case _AdState.failed:
        return _buildFailedScreen();
      case _AdState.rewarded:
        return _buildRewardedScreen();
    }
  }

  // ── Support / intro screen ───────────────────────────────────────────────────
  Widget _buildSupportScreen() {
    final actionLabel = widget.openPreview ? 'PREVIEW REPORT' : 'DOWNLOAD PDF';
    final actionIcon = widget.openPreview ? Icons.preview_rounded : Icons.download_rounded;

    return Column(
      key: const ValueKey('support'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon badge
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrutalColors.primaryYellow,
            border: Border.all(color: BrutalColors.border, width: 2.5),
            boxShadow: const [BoxShadow(color: BrutalColors.border, offset: Offset(4, 4))],
          ),
          child: const Icon(Icons.favorite_rounded, color: BrutalColors.textDark, size: 32),
        ),
        const SizedBox(height: 18),

        Text('SUPPORT LEDGER', style: BrutalTypography.headingSmall),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrutalColors.surfaceElevated,
            border: Border.all(color: BrutalColors.borderDim, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: BrutalColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A message from the developer',
                      style: BrutalTypography.label.copyWith(color: BrutalColors.cyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Ledger is built and maintained by a solo indie developer. '  
                'There are no subscription fees or paywalls — the app is completely free.\n\n'
                'To cover server hosting, storage, and ongoing development costs, '  
                'premium reports are supported by a short video ad. '  
                'Watching it takes only 15 seconds and directly helps keep this app alive. 🙏',
                style: BrutalTypography.bodySmall.copyWith(
                  color: BrutalColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Watch Ad CTA
        GestureDetector(
          onTap: _startAd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: BrutalColors.primaryYellow,
              border: Border.all(color: BrutalColors.border, width: 2.5),
              boxShadow: const [BoxShadow(color: BrutalColors.border, offset: Offset(4, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_filled, color: BrutalColors.textDark, size: 22),
                const SizedBox(width: 10),
                Text(
                  'WATCH AD TO $actionLabel',
                  style: BrutalTypography.label.copyWith(
                    color: BrutalColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(actionIcon, color: BrutalColors.textDark, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _closeDialog,
          child: Text(
            'NOT NOW',
            style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // ── Loading screen ───────────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const CircularProgressIndicator(
          color: BrutalColors.primaryYellow,
          strokeWidth: 3,
        ),
        const SizedBox(height: 20),
        Text('LOADING AD...', style: BrutalTypography.headingSmall),
        const SizedBox(height: 8),
        Text(
          'Please wait while we prepare your ad.',
          style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Playing screen ───────────────────────────────────────────────────────────
  Widget _buildPlayingScreen() {
    return Column(
      key: const ValueKey('playing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Simulated video placeholder
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: BrutalColors.background,
            border: Border.all(color: BrutalColors.border, width: 2.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated "video" shimmer
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline, color: BrutalColors.primaryYellow, size: 52),
                      const SizedBox(height: 8),
                      Text(
                        'AD PLAYING',
                        style: BrutalTypography.sticker.copyWith(
                          color: BrutalColors.primaryYellow,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Progress bar
                      SizedBox(
                        width: 160,
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: BrutalColors.surfaceElevated,
                          color: BrutalColors.primaryYellow,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Countdown badge top-right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: BrutalColors.surface,
                  child: Text(
                    '$_countdown s',
                    style: BrutalTypography.sticker.copyWith(
                      color: BrutalColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _canSkip
                    ? 'You can now skip the ad.'
                    : 'Please watch the full ad to unlock your report.',
                style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
              ),
            ),
            if (_canSkip)
              GestureDetector(
                onTap: _skipAd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BrutalColors.surfaceElevated,
                    border: Border.all(color: BrutalColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.skip_next, size: 16, color: BrutalColors.textPrimary),
                      const SizedBox(width: 4),
                      Text('SKIP', style: BrutalTypography.label.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Skipped screen ───────────────────────────────────────────────────────────
  Widget _buildSkippedScreen() {
    return Column(
      key: const ValueKey('skipped'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrutalColors.orange.withAlpha(40),
            border: Border.all(color: BrutalColors.orange, width: 2),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: BrutalColors.orange, size: 36),
        ),
        const SizedBox(height: 16),
        Text('AD WAS SKIPPED', style: BrutalTypography.headingSmall),
        const SizedBox(height: 10),
        Text(
          'The report is only unlocked after watching the full ad.\n\n'
          'Please try again and watch until the end to download or preview your financial report.',
          style: BrutalTypography.bodySmall.copyWith(
            color: BrutalColors.textSecondary,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() {
            _state = _AdState.support;
            _progressController.reset();
          }),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: BrutalColors.primaryYellow,
              border: Border.all(color: BrutalColors.border, width: 2.5),
              boxShadow: const [BoxShadow(color: BrutalColors.border, offset: Offset(3, 3))],
            ),
            child: Text(
              'TRY AGAIN',
              style: BrutalTypography.label.copyWith(
                color: BrutalColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _closeDialog,
          child: Text('CLOSE', style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary)),
        ),
      ],
    );
  }

  // ── Failed screen ────────────────────────────────────────────────────────────
  Widget _buildFailedScreen() {
    return Column(
      key: const ValueKey('failed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrutalColors.red.withAlpha(40),
            border: Border.all(color: BrutalColors.red, width: 2),
          ),
          child: const Icon(Icons.wifi_off_rounded, color: BrutalColors.red, size: 36),
        ),
        const SizedBox(height: 16),
        Text('AD NOT AVAILABLE', style: BrutalTypography.headingSmall),
        const SizedBox(height: 10),
        Text(
          'We could not load an ad right now. This may be due to your internet connection or ad availability in your region.\n\n'
          'Please try again in a moment.',
          style: BrutalTypography.bodySmall.copyWith(
            color: BrutalColors.textSecondary,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _startAd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: BrutalColors.primaryYellow,
              border: Border.all(color: BrutalColors.border, width: 2.5),
              boxShadow: const [BoxShadow(color: BrutalColors.border, offset: Offset(3, 3))],
            ),
            child: Text(
              'RETRY',
              style: BrutalTypography.label.copyWith(
                color: BrutalColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _closeDialog,
          child: Text('CLOSE', style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary)),
        ),
      ],
    );
  }

  // ── Rewarded screen ──────────────────────────────────────────────────────────
  Widget _buildRewardedScreen() {
    return Column(
      key: const ValueKey('rewarded'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrutalColors.green.withAlpha(40),
            border: Border.all(color: BrutalColors.green, width: 2.5),
          ),
          child: const Icon(Icons.check_circle_rounded, color: BrutalColors.green, size: 40),
        ),
        const SizedBox(height: 16),
        Text('THANK YOU! 🎉', style: BrutalTypography.headingSmall),
        const SizedBox(height: 8),
        Text(
          'Ad completed. Your report is being prepared...',
          style: BrutalTypography.bodySmall.copyWith(color: BrutalColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(
          color: BrutalColors.green,
          backgroundColor: BrutalColors.surfaceElevated,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
