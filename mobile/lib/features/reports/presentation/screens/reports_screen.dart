import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/features/auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
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
      setState(() {
        _selectedDateRange = picked;
        _selectedRange = 'CUSTOM';
      });
    }
  }

  Future<void> _handleExportPdf({bool openPreview = false}) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      BrutalToast.showSuccess(context, 'GENERATING AUDIT PDF REPORT...');
      final auth = ref.read(authControllerProvider);
      final user = auth.user;
      final period = _selectedDateRange != null
          ? '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
          : (_selectedRange == 'WEEK'
              ? 'CURRENT WEEK'
              : (_selectedRange == 'YEAR' ? 'YEAR 2026' : 'OCTOBER 2026'));

      if (openPreview) {
        await PdfReportService.openPrintPreview(
          userName: user?.name ?? 'Bruce Wayne',
          userEmail: user?.email ?? 'bruce@wayne.corp',
          currencySymbol: user?.currencySymbol ?? '₹',
          period: period,
        );
      } else {
        await PdfReportService.exportAndDownloadPdf(
          userName: user?.name ?? 'Bruce Wayne',
          userEmail: user?.email ?? 'bruce@wayne.corp',
          currencySymbol: user?.currencySymbol ?? '₹',
          period: period,
        );
      }

      if (mounted) {
        BrutalToast.showSuccess(context, 'PDF REPORT READY');
      }
    } catch (e) {
      if (mounted) {
        BrutalToast.showError(context, 'COULD NOT GENERATE PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

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
                Text('EXPORT FINANCIAL REPORT', style: BrutalTypography.headingMedium),
                const SizedBox(height: 8),
                Text('Download or preview your formal financial statement PDF.', style: BrutalTypography.bodyMedium),
                const SizedBox(height: 20),
                BrutalButton(
                  text: 'DOWNLOAD PDF STATEMENT',
                  backgroundColor: BrutalColors.primaryYellow,
                  textColor: BrutalColors.textDark,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleExportPdf(openPreview: false);
                  },
                ),
                const SizedBox(height: 12),
                BrutalButton(
                  text: 'PRINT / PDF PREVIEW',
                  backgroundColor: BrutalColors.cyan,
                  textColor: BrutalColors.textDark,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleExportPdf(openPreview: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
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
                      child: BarChart(
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
                      ),
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
                    SizedBox(
                      height: 160,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 36,
                                sections: [
                                  PieChartSectionData(color: BrutalColors.primaryYellow, value: 35, title: '35%', radius: 36, titleStyle: BrutalTypography.sticker),
                                  PieChartSectionData(color: BrutalColors.hotPink, value: 25, title: '25%', radius: 36, titleStyle: BrutalTypography.sticker),
                                  PieChartSectionData(color: BrutalColors.cyan, value: 20, title: '20%', radius: 36, titleStyle: BrutalTypography.sticker),
                                  PieChartSectionData(color: BrutalColors.lime, value: 12, title: '12%', radius: 36, titleStyle: BrutalTypography.sticker),
                                  PieChartSectionData(color: BrutalColors.orange, value: 8, title: '8%', radius: 36, titleStyle: BrutalTypography.sticker),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem('Food & Groceries', BrutalColors.primaryYellow),
                              _buildLegendItem('Rent & Bills', BrutalColors.hotPink),
                              _buildLegendItem('Travel & Commute', BrutalColors.cyan),
                              _buildLegendItem('Shopping & Tech', BrutalColors.lime),
                              _buildLegendItem('Entertainment', BrutalColors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    Text('DAILY SPENDING TREND', style: BrutalTypography.headingSmall),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: LineChart(
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
                            border: const Border(
                              bottom: BorderSide(color: BrutalColors.border, width: 2.0),
                            ),
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
                              isCurved: false, // Strict brutalist angular lines
                              color: BrutalColors.lime,
                              barWidth: 3.5,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: BrutalColors.green,
          width: 14,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          toY: y2,
          color: BrutalColors.red,
          width: 14,
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
          Text(
            label,
            style: BrutalTypography.bodySmall.copyWith(
              fontSize: 12,
              color: BrutalColors.textPrimary,
              fontWeight: FontWeight.w600,
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
