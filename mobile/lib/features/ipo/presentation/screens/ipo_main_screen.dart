import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/finapi_ipo_service.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/ipo_controller.dart';
import '../widgets/ipo_exit_dialog.dart';
import 'add_edit_ipo_screen.dart';

class IpoMainScreen extends ConsumerStatefulWidget {
  const IpoMainScreen({super.key});

  @override
  ConsumerState<IpoMainScreen> createState() => _IpoMainScreenState();
}

class _IpoMainScreenState extends ConsumerState<IpoMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 state
  String _bidsStatusFilter = 'ALL';
  final _bidsSearchController = TextEditingController();

  // Tab 2 state
  List<Map<String, dynamic>> _marketIpos = [];
  bool _isLoadingMarket = false;
  String _marketFilter = 'ALL';
  final _marketSearchController = TextEditingController();

  // Tab 3 state
  String _selectedFy = '2026-2027';
  String _selectedApplicant = 'ALL';
  Map<String, dynamic>? _caReportData;
  bool _isLoadingCaReport = false;

  final List<String> _fyList = ['2026-2027', '2025-2026', '2024-2025'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _marketIpos.isEmpty) {
        _loadMarketFeed();
      } else if (_tabController.index == 2) {
        _loadCaReport();
      }
      setState(() {});
    });

    Future.microtask(() {
      ref.read(ipoProvider.notifier).loadIpos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bidsSearchController.dispose();
    _marketSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketFeed({bool forceRefresh = false}) async {
    setState(() => _isLoadingMarket = true);
    final data = await FinApiIpoService().fetchMarketIpos(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _marketIpos = data;
        _isLoadingMarket = false;
      });
    }
  }

  Future<void> _loadCaReport() async {
    setState(() => _isLoadingCaReport = true);
    final data = await CloudSyncService().fetchCaReport(
      fy: _selectedFy,
      applicant: _selectedApplicant == 'ALL' ? null : _selectedApplicant,
    );
    if (mounted) {
      setState(() {
        _caReportData = data;
        _isLoadingCaReport = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) BrutalToast.showError(context, 'COULD NOT OPEN REGISTRAR LINK');
    }
  }

  void _confirmDelete(String id, String name) {
    BrutalDialog.show(
      context: context,
      title: 'DISCARD IPO APPLICATION?',
      content: Text(
        'Delete "$name"? This action cannot be reversed.',
        style: const TextStyle(color: BrutalColors.textSecondary, height: 1.4),
      ),
      confirmText: 'DELETE IPO',
      confirmColor: BrutalColors.red,
      cancelText: 'CANCEL',
      onConfirm: () async {
        await ref.read(ipoProvider.notifier).deleteIpo(id);
        if (mounted) BrutalToast.showSuccess(context, 'IPO APPLICATION REMOVED');
      },
    );
  }

  void _showStatusSwitcher(Map<String, dynamic> ipo) {
    final currentStatus = ipo['status'] ?? 'BLOCKED';

    showModalBottomSheet(
      context: context,
      backgroundColor: BrutalColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.border, width: 2.5),
        borderRadius: BorderRadius.zero,
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('UPDATE IPO APPLICATION STATUS', style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow)),
              const SizedBox(height: 12),
              ...['BLOCKED', 'ALLOTTED', 'NOT_ALLOTTED'].map((s) {
                final isCurrent = currentStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BrutalButton(
                    text: s.replaceAll('_', ' '),
                    backgroundColor: isCurrent ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
                    textColor: isCurrent ? BrutalColors.textDark : BrutalColors.textPrimary,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final updated = Map<String, dynamic>.from(ipo);
                      updated['status'] = s;
                      if (s == 'ALLOTTED') {
                        final appliedLots = (ipo['appliedLots'] as num?)?.toInt() ?? 1;
                        final sharesPerLot = (ipo['sharesPerLot'] as num?)?.toInt() ?? 1;
                        final bidPrice = (ipo['bidPrice'] as num?)?.toDouble() ?? 0.0;
                        updated['allottedLots'] = appliedLots;
                        updated['allottedShares'] = appliedLots * sharesPerLot;
                        updated['allottedAmount'] = appliedLots * sharesPerLot * bidPrice;
                        updated['refundAmount'] = 0.0;
                      } else if (s == 'NOT_ALLOTTED') {
                        updated['allottedLots'] = 0;
                        updated['allottedShares'] = 0;
                        updated['allottedAmount'] = 0.0;
                        updated['refundAmount'] = (ipo['totalAmountBlocked'] as num?)?.toDouble() ?? 0.0;
                      }
                      await ref.read(ipoProvider.notifier).updateIpo(updated);
                      if (mounted) BrutalToast.showSuccess(context, 'STATUS UPDATED TO $s');
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _exportCaReportCsv() {
    final ipos = ref.read(ipoProvider);
    final exited = ipos.where((i) => i['status'] == 'EXITED').toList();

    if (exited.isEmpty) {
      BrutalToast.showError(context, 'NO EXITED IPOS AVAILABLE TO EXPORT');
      return;
    }

    final headers = [
      'Company Name',
      'Symbol',
      'Applicant',
      'PAN',
      'Broker',
      'Allotment Date',
      'Exit Date',
      'Shares',
      'Buy Price',
      'Sell Price',
      'Gross Cost',
      'Gross Sale',
      'DP Charges',
      'STT Charges',
      'Net Gain',
      'Gain Type (Section)',
      'Financial Year'
    ];

    final rows = exited.map((i) {
      final shares = (i['exitShares'] ?? i['allottedShares'] ?? 0).toString();
      final buyPrice = (i['bidPrice'] ?? 0).toString();
      final sellPrice = (i['exitPrice'] ?? 0).toString();
      final grossCost = ((double.tryParse(buyPrice) ?? 0) * (int.tryParse(shares) ?? 0)).toStringAsFixed(2);
      final grossSale = (i['grossProceeds'] ?? 0).toString();
      final dp = (i['dpCharges'] ?? 15.93).toString();
      final stt = (i['sttCharges'] ?? 0).toString();
      final netGain = (i['netGain'] ?? 0).toString();
      final gainType = i['gainType'] == 'LTCG' ? 'LTCG (u/s 112A)' : 'STCG (u/s 111A)';

      return [
        '"${i['companyName'] ?? ''}"',
        '"${i['symbol'] ?? ''}"',
        '"${i['applicantName'] ?? 'Self'}"',
        '"${i['pan'] ?? ''}"',
        '"${i['dematBroker'] ?? ''}"',
        '"${i['allotmentDate'] ?? ''}"',
        '"${i['exitDate'] ?? ''}"',
        shares,
        buyPrice,
        sellPrice,
        grossCost,
        grossSale,
        dp,
        stt,
        netGain,
        '"$gainType"',
        '"${i['financialYear'] ?? _selectedFy}"'
      ].join(',');
    }).toList();

    final csvContent = [headers.join(','), ...rows].join('\n');
    Clipboard.setData(ClipboardData(text: csvContent));
    BrutalToast.showSuccess(context, 'CSV COPIED TO CLIPBOARD (READY TO PASTE IN EXCEL)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: 'IPO MANAGEMENT // TAX AUDIT',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: BrutalColors.primaryYellow, size: 28),
            tooltip: 'Track New IPO',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditIpoScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: BrutalColors.primaryYellow,
              foregroundColor: BrutalColors.textDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.zero,
              ),
              icon: const Icon(Icons.add_chart, size: 20),
              label: Text(
                '+ TRACK BID',
                style: BrutalTypography.sticker.copyWith(
                  color: BrutalColors.textDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditIpoScreen()),
                );
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Neo-Brutalist Top Tabs Strip
            Container(
              decoration: const BoxDecoration(
                color: BrutalColors.surface,
                border: Border(bottom: BorderSide(color: BrutalColors.border, width: 2.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: BrutalColors.primaryYellow,
                indicatorWeight: 4.0,
                labelColor: BrutalColors.primaryYellow,
                unselectedLabelColor: BrutalColors.textSecondary,
                labelStyle: BrutalTypography.sticker.copyWith(fontWeight: FontWeight.w900),
                tabs: const [
                  Tab(text: 'MY BIDS'),
                  Tab(text: 'MARKET FEED (LIVE)'),
                  Tab(text: 'CA TAX REPORT'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyBidsTab(),
                  _buildMarketFeedTab(),
                  _buildCaReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: MY BIDS
  // ===========================================================================
  Widget _buildMyBidsTab() {
    final allIpos = ref.watch(ipoProvider);

    final filtered = allIpos.where((i) {
      if (_bidsStatusFilter != 'ALL') {
        if (_bidsStatusFilter == 'SME') {
          if ((i['ipoType'] ?? '').toString().toUpperCase() != 'SME') return false;
        } else if (i['status'] != _bidsStatusFilter) {
          return false;
        }
      }
      if (_bidsSearchController.text.isNotEmpty) {
        final q = _bidsSearchController.text.toLowerCase();
        final company = (i['companyName'] ?? '').toString().toLowerCase();
        final symbol = (i['symbol'] ?? '').toString().toLowerCase();
        final applicant = (i['applicantName'] ?? '').toString().toLowerCase();
        if (!company.contains(q) && !symbol.contains(q) && !applicant.contains(q)) return false;
      }
      return true;
    }).toList();

    // Sizing Stats
    double totalBlocked = 0.0;
    double totalRealizedGain = 0.0;
    int allottedCount = 0;
    int totalDecidedCount = 0;

    for (final i in allIpos) {
      if (i['status'] == 'BLOCKED') {
        totalBlocked += (i['totalAmountBlocked'] as num?)?.toDouble() ?? 0.0;
      }
      if (i['status'] == 'EXITED') {
        totalRealizedGain += (i['netGain'] as num?)?.toDouble() ?? 0.0;
      }
      if (i['status'] == 'ALLOTTED' || i['status'] == 'EXITED') {
        allottedCount++;
        totalDecidedCount++;
      } else if (i['status'] == 'NOT_ALLOTTED') {
        totalDecidedCount++;
      }
    }

    final allotmentPct = totalDecidedCount > 0 ? ((allottedCount / totalDecidedCount) * 100).round() : 0;

    return RefreshIndicator(
      color: BrutalColors.primaryYellow,
      backgroundColor: BrutalColors.surface,
      onRefresh: () => ref.read(ipoProvider.notifier).loadIpos(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Sizing Stats Bar
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'TOTAL BLOCKED',
                  value: '₹${NumberFormat('#,##,##0').format(totalBlocked)}',
                  accent: BrutalColors.primaryYellow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'REALIZED GAIN',
                  value: '${totalRealizedGain >= 0 ? '+' : ''}₹${NumberFormat('#,##,##0').format(totalRealizedGain)}',
                  accent: totalRealizedGain >= 0 ? BrutalColors.lime : BrutalColors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'ALLOTMENT %',
                  value: '$allotmentPct%',
                  accent: BrutalColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search & Filter Strip
          TextField(
            controller: _bidsSearchController,
            onChanged: (_) => setState(() {}),
            style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
            cursorColor: BrutalColors.primaryYellow,
            decoration: InputDecoration(
              hintText: 'SEARCH BY COMPANY, SYMBOL, OR APPLICANT...',
              hintStyle: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: BrutalColors.textPrimary),
              filled: true,
              fillColor: BrutalColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('ALL'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('BLOCKED'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('ALLOTTED'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('NOT_ALLOTTED'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('EXITED'),
                const SizedBox(width: 6),
                _buildStatusFilterChip('SME'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Applications List
          if (filtered.isEmpty)
            _buildEmptyBidsState()
          else
            ...filtered.map((ipo) => _buildIpoBidCard(ipo)),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BrutalColors.surfaceCard,
        border: Border.all(color: accent, width: 2.0),
        boxShadow: [
          BoxShadow(color: accent, offset: const Offset(2.5, 2.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BrutalTypography.sticker.copyWith(fontSize: 9, color: BrutalColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BrutalTypography.headingSmall.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label) {
    final isSel = _bidsStatusFilter == label;
    return BrutalChip(
      label: label.replaceAll('_', ' '),
      backgroundColor: isSel ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
      textColor: isSel ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSel ? 2.0 : 0.0,
      onTap: () => setState(() => _bidsStatusFilter = label),
    );
  }

  Widget _buildIpoBidCard(Map<String, dynamic> ipo) {
    final id = (ipo['id'] ?? ipo['_id'] ?? '').toString();
    final company = (ipo['companyName'] ?? 'Untitled IPO').toString();
    final symbol = (ipo['symbol'] ?? '').toString();
    final status = (ipo['status'] ?? 'BLOCKED').toString();
    final type = (ipo['ipoType'] ?? 'MAINBOARD').toString();
    final applicant = (ipo['applicantName'] ?? 'Self').toString();
    final broker = (ipo['dematBroker'] ?? 'Zerodha').toString();
    final pan = (ipo['pan'] ?? '').toString();
    final lots = (ipo['appliedLots'] ?? 1);
    final sharesPerLot = (ipo['sharesPerLot'] ?? 1);
    final bidPrice = (ipo['bidPrice'] ?? 0);
    final totalBlocked = (ipo['totalAmountBlocked'] ?? 0);
    final registrar = (ipo['registrar'] ?? 'Link Intime').toString();
    final registrarUrl = (ipo['registrarUrl'] ?? FinApiIpoService.getRegistrarUrl(registrar, symbol)).toString();

    Color statusColor = BrutalColors.primaryYellow;
    if (status == 'ALLOTTED') statusColor = BrutalColors.lime;
    if (status == 'NOT_ALLOTTED') statusColor = BrutalColors.red;
    if (status == 'EXITED') statusColor = BrutalColors.cyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: BrutalColors.surfaceCard,
        border: Border.all(color: statusColor, width: 2.0),
        boxShadow: [
          BoxShadow(color: statusColor, offset: const Offset(3.5, 3.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: BrutalColors.surfaceElevated,
              border: const Border(bottom: BorderSide(color: BrutalColors.border, width: 1.5)),
            ),
            child: Row(
              children: [
                if (symbol.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrutalColors.primaryYellow,
                      border: Border.all(color: Colors.black, width: 1.0),
                    ),
                    child: Text(
                      symbol,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (type == 'SME') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade300,
                      border: Border.all(color: Colors.black, width: 1.0),
                    ),
                    child: const Text(
                      'SME',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutalTypography.headingSmall.copyWith(fontSize: 15),
                  ),
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    border: Border.all(color: Colors.black, width: 1.0),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Applicant & Demat Profile
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: BrutalColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$applicant · $broker',
                      style: BrutalTypography.bodyMedium.copyWith(
                        color: BrutalColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pan.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('($pan)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Numbers Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('APPLICATION SIZING', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '$lots Lot(s) × $sharesPerLot sh @ ₹$bidPrice',
                          style: BrutalTypography.bodyMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('BLOCKED FUNDS', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,##0').format(totalBlocked)}',
                          style: BrutalTypography.headingSmall.copyWith(
                            fontSize: 16,
                            color: BrutalColors.primaryYellow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // If Exited: Show P&L ribbon
                if (status == 'EXITED') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (ipo['netGain'] ?? 0) >= 0 ? const Color(0xFF142918) : const Color(0xFF2C1414),
                      border: Border.all(
                        color: (ipo['netGain'] ?? 0) >= 0 ? BrutalColors.lime : BrutalColors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SOLD @ ₹${ipo['exitPrice'] ?? 0} (${ipo['gainType'] ?? 'STCG'})',
                          style: BrutalTypography.sticker.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${(ipo['netGain'] ?? 0) >= 0 ? '+' : ''}₹${NumberFormat('#,##,##0.00').format(ipo['netGain'] ?? 0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: (ipo['netGain'] ?? 0) >= 0 ? BrutalColors.lime : BrutalColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceElevated,
              border: Border(top: BorderSide(color: BrutalColors.borderDim, width: 1.0)),
            ),
            child: Row(
              children: [
                // Registrar Lookup
                InkWell(
                  onTap: () => _launchUrl(registrarUrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrutalColors.surfaceCard,
                      border: Border.all(color: BrutalColors.border, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new, size: 12, color: BrutalColors.primaryYellow),
                        const SizedBox(width: 4),
                        Text('CHECK ALLOTMENT', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.primaryYellow)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Status switcher
                InkWell(
                  onTap: () => _showStatusSwitcher(ipo),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrutalColors.surfaceCard,
                      border: Border.all(color: BrutalColors.border, width: 1.0),
                    ),
                    child: Text('STATUS', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 6),

                // Record Exit (if allotted)
                if (status == 'ALLOTTED') ...[
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => IpoExitDialog(
                          ipo: ipo,
                          onConfirm: (price, shares, date) {
                            ref.read(ipoProvider.notifier).recordExit(
                                  id,
                                  exitPrice: price,
                                  exitShares: shares,
                                  exitDate: date,
                                );
                            BrutalToast.showSuccess(context, 'EXIT RECORDED & P&L SAVED');
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BrutalColors.lime,
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      child: const Text('RECORD EXIT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  ),
                ],

                const Spacer(),

                // Edit
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: BrutalColors.textSecondary),
                  tooltip: 'Edit Bid',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditIpoScreen(existingIpo: ipo),
                      ),
                    );
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: BrutalColors.red),
                  tooltip: 'Delete Bid',
                  onPressed: () => _confirmDelete(id, company),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBidsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: BrutalColors.primaryYellow,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(Icons.account_balance_outlined, size: 36, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text('NO IPO BIDS TRACKED', style: BrutalTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Switch to MARKET FEED tab to browse live Indian IPOs with one-tap bid tracking, or track custom applications.',
              textAlign: TextAlign.center,
              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
            ),
            const SizedBox(height: 20),
            BrutalButton(
              text: 'EXPLORE LIVE MARKET IPOS',
              backgroundColor: BrutalColors.primaryYellow,
              textColor: BrutalColors.textDark,
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: LIVE MARKET FEED (FROM FINAPI)
  // ===========================================================================
  Widget _buildMarketFeedTab() {
    final filtered = _marketIpos.where((i) {
      if (_marketFilter != 'ALL') {
        if (_marketFilter == 'SME') {
          if ((i['type'] ?? '').toString().toUpperCase() != 'SME') return false;
        } else if (i['status'] != _marketFilter) {
          return false;
        }
      }
      if (_marketSearchController.text.isNotEmpty) {
        final q = _marketSearchController.text.toLowerCase();
        final name = (i['name'] ?? '').toString().toLowerCase();
        final sym = (i['symbol'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !sym.contains(q)) return false;
      }
      return true;
    }).toList();

    return RefreshIndicator(
      color: BrutalColors.primaryYellow,
      backgroundColor: BrutalColors.surface,
      onRefresh: () => _loadMarketFeed(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrutalColors.surfaceCard,
              border: Border.all(color: BrutalColors.cyan, width: 2.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: BrutalColors.cyan, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LIVE INDIAN MARKET FEED (FINAPI)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.cyan)),
                      const SizedBox(height: 2),
                      Text('Live & upcoming Mainboard and SME issues with real-time price bands and cut-offs.', style: BrutalTypography.bodyMedium.copyWith(fontSize: 12, color: BrutalColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search & Filter
          TextField(
            controller: _marketSearchController,
            onChanged: (_) => setState(() {}),
            style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
            cursorColor: BrutalColors.primaryYellow,
            decoration: InputDecoration(
              hintText: 'SEARCH MARKET IPOS...',
              hintStyle: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: BrutalColors.textPrimary),
              filled: true,
              fillColor: BrutalColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMarketFilterChip('ALL'),
                const SizedBox(width: 6),
                _buildMarketFilterChip('LIVE'),
                const SizedBox(width: 6),
                _buildMarketFilterChip('UPCOMING'),
                const SizedBox(width: 6),
                _buildMarketFilterChip('CLOSED'),
                const SizedBox(width: 6),
                _buildMarketFilterChip('SME'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingMarket)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: BrutalColors.primaryYellow),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('NO MARKET IPOS MATCHING FILTER', style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary)),
              ),
            )
          else
            ...filtered.map((item) => _buildMarketIpoCard(item)),
        ],
      ),
    );
  }

  Widget _buildMarketFilterChip(String label) {
    final isSel = _marketFilter == label;
    return BrutalChip(
      label: label,
      backgroundColor: isSel ? BrutalColors.cyan : BrutalColors.surfaceElevated,
      textColor: isSel ? BrutalColors.textDark : BrutalColors.textSecondary,
      borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
      shadowOffset: isSel ? 2.0 : 0.0,
      onTap: () => setState(() => _marketFilter = label),
    );
  }

  Widget _buildMarketIpoCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? 'IPO').toString();
    final symbol = (item['symbol'] ?? '').toString();
    final status = (item['status'] ?? 'LIVE').toString().toUpperCase();
    final type = (item['type'] ?? 'MAINBOARD').toString();
    final priceRange = (item['priceRange'] ?? '').toString();
    final lotSize = (item['lotSize'] ?? 1);
    final cutOffPrice = (item['cutOffPrice'] ?? 0.0);
    final minInvestment = (lotSize as int) * (cutOffPrice as num).toDouble();
    final startDate = (item['startDate'] ?? '').toString();
    final endDate = (item['endDate'] ?? '').toString();
    final gmp = (item['gmp'] as num?)?.toDouble() ?? 0.0;
    final expGain = (item['expectedListingGain'] as num?)?.toDouble() ?? 0.0;

    Color statusBadgeColor = BrutalColors.lime;
    if (status == 'UPCOMING') statusBadgeColor = BrutalColors.primaryYellow;
    if (status == 'CLOSED') statusBadgeColor = BrutalColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: BrutalColors.surfaceCard,
        border: Border.all(color: BrutalColors.border, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(3.0, 3.0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceElevated,
              border: Border(bottom: BorderSide(color: BrutalColors.border, width: 1.5)),
            ),
            child: Row(
              children: [
                if (symbol.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: BrutalColors.primaryYellow,
                    child: Text(
                      symbol,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (type == 'SME') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.purple.shade300,
                    child: const Text('SME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutalTypography.headingSmall.copyWith(fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: statusBadgeColor,
                  child: Text(
                    status,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // Details Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRICE BAND', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(priceRange.isEmpty ? '₹$cutOffPrice' : priceRange, style: BrutalTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('MIN RETAIL (1 LOT)', style: BrutalTypography.sticker.copyWith(fontSize: 9.5, color: BrutalColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          minInvestment > 0 ? '₹${NumberFormat('#,##,##0').format(minInvestment)}' : '$lotSize Shares',
                          style: BrutalTypography.headingSmall.copyWith(fontSize: 15, color: BrutalColors.primaryYellow),
                        ),
                      ],
                    ),
                  ],
                ),
                if (startDate.isNotEmpty || endDate.isNotEmpty || gmp > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (startDate.isNotEmpty || endDate.isNotEmpty)
                        Text(
                          'Issue: $startDate – $endDate',
                          style: TextStyle(fontSize: 11, color: BrutalColors.textSecondary),
                        ),
                      if (gmp > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF142918),
                            border: Border.all(color: BrutalColors.lime, width: 1.0),
                          ),
                          child: Text(
                            'GMP: +₹$gmp (${expGain.toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BrutalColors.lime),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // One-Tap Apply Action
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceElevated,
              border: Border(top: BorderSide(color: BrutalColors.borderDim, width: 1.0)),
            ),
            child: BrutalButton(
              text: '+ ONE-TAP TRACK / APPLY',
              backgroundColor: BrutalColors.primaryYellow,
              textColor: BrutalColors.textDark,
              height: 40,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditIpoScreen(prefillMarketIpo: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CA TAX REPORT
  // ===========================================================================
  Widget _buildCaReportTab() {
    final ipos = ref.watch(ipoProvider);

    // Extract unique applicants
    final applicants = {'ALL', ...ipos.map((i) => (i['applicantName'] ?? 'Self').toString())}.toList();

    // Local calculation fallback if backend report is still loading
    final targetFy = _selectedFy;
    final relevantIpos = ipos.where((i) {
      if (i['financialYear'] != targetFy && i['status'] != 'EXITED') return false;
      if (_selectedApplicant != 'ALL' && i['applicantName'] != _selectedApplicant) return false;
      return true;
    }).toList();

    final exited = relevantIpos.where((i) => i['status'] == 'EXITED').toList();

    double grossSales = 0.0;
    double grossCost = 0.0;
    double totalDp = 0.0;
    double totalStt = 0.0;
    double netStcg = 0.0;
    double netLtcg = 0.0;

    for (final e in exited) {
      final buy = (e['exitShares'] ?? 0) * (e['bidPrice'] ?? 0);
      grossCost += (buy as num).toDouble();
      grossSales += (e['grossProceeds'] as num?)?.toDouble() ?? 0.0;
      totalDp += (e['dpCharges'] as num?)?.toDouble() ?? 15.93;
      totalStt += (e['sttCharges'] as num?)?.toDouble() ?? 0.0;
      final gain = (e['netGain'] as num?)?.toDouble() ?? 0.0;
      if (e['gainType'] == 'LTCG') {
        netLtcg += gain;
      } else {
        netStcg += gain;
      }
    }

    final estimatedTax = (netStcg > 0 ? netStcg * 0.20 : 0.0) +
        (netLtcg > 125000 ? (netLtcg - 125000) * 0.125 : 0.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // FY and Applicant Selectors
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrutalColors.surface,
            border: Border.all(color: BrutalColors.border, width: 2.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FINANCIAL YEAR', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceCard,
                        border: Border.all(color: BrutalColors.border, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFy,
                          isExpanded: true,
                          dropdownColor: BrutalColors.surfaceElevated,
                          style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.primaryYellow, fontWeight: FontWeight.bold),
                          items: _fyList.map((fy) => DropdownMenuItem(value: fy, child: Text('FY $fy'))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedFy = val);
                              _loadCaReport();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APPLICANT / PAN', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceCard,
                        border: Border.all(color: BrutalColors.border, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedApplicant,
                          isExpanded: true,
                          dropdownColor: BrutalColors.surfaceElevated,
                          style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                          items: applicants.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedApplicant = val);
                              _loadCaReport();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingCaReport) ...[
          const LinearProgressIndicator(color: BrutalColors.primaryYellow, backgroundColor: BrutalColors.surface, minHeight: 3),
          const SizedBox(height: 12),
        ],

        // Hero Tax Summary Box (CA Grade)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BrutalColors.surfaceCard,
            border: Border.all(color: BrutalColors.lime, width: 2.5),
            boxShadow: const [
              BoxShadow(color: BrutalColors.lime, offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CA TAX LIABILITY ESTIMATE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.lime)),
                  Text('FY $_selectedFy', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##,##0').format(estimatedTax)}',
                style: BrutalTypography.headingLarge.copyWith(
                  color: BrutalColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculated u/s 111A (STCG @ 20%) & u/s 112A (LTCG @ 12.5% over ₹1.25L exemption)',
                style: TextStyle(fontSize: 11, color: BrutalColors.textSecondary),
              ),
              const Divider(color: BrutalColors.border, thickness: 1.5, height: 20),

              // Detail Grid
              Row(
                children: [
                  Expanded(
                    child: _buildCaLineItem(
                      label: 'NET STCG (≤ 1 YR)',
                      amount: '₹${NumberFormat('#,##,##0').format(netStcg)}',
                      color: netStcg >= 0 ? BrutalColors.lime : BrutalColors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCaLineItem(
                      label: 'NET LTCG (> 1 YR)',
                      amount: '₹${NumberFormat('#,##,##0').format(netLtcg)}',
                      color: netLtcg >= 0 ? BrutalColors.cyan : BrutalColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCaLineItem(
                      label: 'GROSS TURNOVER',
                      amount: '₹${NumberFormat('#,##,##0').format(grossSales)}',
                      color: BrutalColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCaLineItem(
                      label: 'EXPENSES DEDUCTED',
                      amount: '₹${NumberFormat('#,##,##0').format(totalDp + totalStt)}',
                      color: BrutalColors.primaryYellow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Share & Export Toolbar
        Row(
          children: [
            Expanded(
              child: BrutalButton(
                text: 'COPY CA SUMMARY',
                backgroundColor: BrutalColors.primaryYellow,
                textColor: BrutalColors.textDark,
                height: 44,
                onPressed: () {
                  final text = _caReportData?['caShareableText'] ??
                      '''*ANNUAL IPO TAX REPORT // FY $_selectedFy*
Applicant: $_selectedApplicant
Net STCG (u/s 111A @ 20%): ₹${NumberFormat('#,##,##0').format(netStcg)}
Net LTCG (u/s 112A @ 12.5%): ₹${NumberFormat('#,##,##0').format(netLtcg)}
Total Estimated Tax: ₹${NumberFormat('#,##,##0').format(estimatedTax)}
Purchase Cost: ₹${NumberFormat('#,##,##0').format(grossCost)}
Gross Turnover: ₹${NumberFormat('#,##,##0').format(grossSales)}
Deductible Charges (DP+STT): ₹${NumberFormat('#,##,##0').format(totalDp + totalStt)}
Generated via Ledger Track App''';
                  Clipboard.setData(ClipboardData(text: text));
                  BrutalToast.showSuccess(context, 'CA AUDIT SUMMARY COPIED (WHATSAPP READY)');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BrutalButton(
                text: 'EXPORT CSV / EXCEL',
                backgroundColor: BrutalColors.surfaceElevated,
                textColor: BrutalColors.textPrimary,
                height: 44,
                onPressed: _exportCaReportCsv,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Realized Trades Breakdown List
        Text('REALIZED EXITS (SCHEDULE FOR AUDIT)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow)),
        const SizedBox(height: 8),

        if (exited.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BrutalColors.surface,
              border: Border.all(color: BrutalColors.border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              'NO REALIZED EXITS RECORDED FOR FY $_selectedFy',
              style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
            ),
          )
        else
          ...exited.map((e) {
            final company = (e['companyName'] ?? 'IPO').toString();
            final symbol = (e['symbol'] ?? '').toString();
            final net = (e['netGain'] as num?)?.toDouble() ?? 0.0;
            final isProf = net >= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrutalColors.surfaceCard,
                border: Border.all(color: isProf ? BrutalColors.lime : BrutalColors.red, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol.isNotEmpty ? '$company ($symbol)' : company,
                        style: BrutalTypography.headingSmall.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e['exitShares']} sh @ ₹${e['exitPrice']} · Sold on ${e['exitDate'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 11, color: BrutalColors.textSecondary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isProf ? '+' : ''}₹${NumberFormat('#,##,##0').format(net)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isProf ? BrutalColors.lime : BrutalColors.red,
                        ),
                      ),
                      Text(
                        e['gainType'] ?? 'STCG',
                        style: TextStyle(fontSize: 10, color: BrutalColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCaLineItem({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BrutalColors.surfaceElevated,
        border: Border.all(color: BrutalColors.borderDim, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: BrutalColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
