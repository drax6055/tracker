import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/finapi_ipo_service.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_chip.dart';
import '../../../../core/widgets/brutal_dialog.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/ipo_controller.dart';

class AddEditIpoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingIpo;
  final Map<String, dynamic>? prefillMarketIpo;

  const AddEditIpoScreen({
    super.key,
    this.existingIpo,
    this.prefillMarketIpo,
  });

  @override
  ConsumerState<AddEditIpoScreen> createState() => _AddEditIpoScreenState();
}

class _AddEditIpoScreenState extends ConsumerState<AddEditIpoScreen> {
  late TextEditingController _companyController;
  late TextEditingController _symbolController;
  late TextEditingController _applicantController;
  late TextEditingController _panController;
  late TextEditingController _bankController;
  late TextEditingController _upiController;
  late TextEditingController _sharesPerLotController;
  late TextEditingController _bidPriceController;
  late TextEditingController _gmpController;
  late TextEditingController _notesController;

  String _ipoType = 'MAINBOARD';
  String _category = 'RETAIL';
  String _broker = 'Zerodha';
  String _status = 'BLOCKED';
  String _registrar = 'Link Intime';
  int _appliedLots = 1;
  int _allottedLots = 0;
  DateTime? _allotmentDate;
  DateTime? _listingDate;
  bool _isSaving = false;

  final List<String> _brokers = [
    'Zerodha',
    'Groww',
    'Angel One',
    'Upstox',
    'HDFC Sky',
    'ICICI Direct',
    'Kotak Neo',
    'Other'
  ];

  final List<String> _registrars = [
    'Link Intime',
    'KFintech',
    'Bigshare Services',
    'Skyline Financial',
    'Cameo Corporate',
    'Other'
  ];

  final List<String> _categories = [
    'RETAIL',
    'sHNI',
    'bHNI',
    'EMPLOYEE',
    'SHAREHOLDER'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingIpo;
    final p = widget.prefillMarketIpo;

    final initialCompany = e?['companyName'] ?? p?['name'] ?? '';
    final initialSymbol = e?['symbol'] ?? p?['symbol'] ?? '';
    final initialLots = e?['appliedLots'] ?? 1;
    final initialSharesPerLot = e?['sharesPerLot'] ?? p?['lotSize'] ?? 1;
    final initialBidPrice = e?['bidPrice'] ?? p?['cutOffPrice'] ?? 0;
    final initialGmp = e?['gmp'] ?? p?['gmp'] ?? 0;

    _companyController = TextEditingController(text: initialCompany.toString());
    _symbolController = TextEditingController(text: initialSymbol.toString());
    _applicantController = TextEditingController(text: (e?['applicantName'] ?? 'Self').toString());
    _panController = TextEditingController(text: (e?['pan'] ?? '').toString());
    _bankController = TextEditingController(text: (e?['bankName'] ?? '').toString());
    _upiController = TextEditingController(text: (e?['upiId'] ?? '').toString());
    _sharesPerLotController = TextEditingController(text: initialSharesPerLot.toString());
    _bidPriceController = TextEditingController(text: initialBidPrice.toString());
    _gmpController = TextEditingController(text: initialGmp > 0 ? initialGmp.toString() : '');
    _notesController = TextEditingController(text: (e?['notes'] ?? '').toString());

    _ipoType = (e?['ipoType'] ?? p?['type'] ?? 'MAINBOARD').toString().toUpperCase();
    if (!_ipoType.contains('SME')) _ipoType = 'MAINBOARD';
    _category = (e?['category'] ?? 'RETAIL').toString();
    _broker = (e?['dematBroker'] ?? 'Zerodha').toString();
    if (!_brokers.contains(_broker)) _broker = 'Other';
    _status = (e?['status'] ?? 'BLOCKED').toString();
    _registrar = (e?['registrar'] ?? p?['registrar'] ?? 'Link Intime').toString();
    if (!_registrars.contains(_registrar)) _registrar = 'Link Intime';

    _appliedLots = (initialLots as num).toInt();
    if (_appliedLots < 1) _appliedLots = 1;
    _allottedLots = (e?['allottedLots'] as num?)?.toInt() ?? (_status == 'ALLOTTED' ? _appliedLots : 0);

    final rawAllotDate = e?['allotmentDate'] ?? p?['allotmentDate'];
    if (rawAllotDate != null && rawAllotDate.toString().isNotEmpty) {
      _allotmentDate = DateTime.tryParse(rawAllotDate.toString());
    }
    final rawListDate = e?['listingDate'] ?? p?['listingDate'];
    if (rawListDate != null && rawListDate.toString().isNotEmpty) {
      _listingDate = DateTime.tryParse(rawListDate.toString());
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _symbolController.dispose();
    _applicantController.dispose();
    _panController.dispose();
    _bankController.dispose();
    _upiController.dispose();
    _sharesPerLotController.dispose();
    _bidPriceController.dispose();
    _gmpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalBlocked {
    final sharesPerLot = int.tryParse(_sharesPerLotController.text) ?? 1;
    final price = double.tryParse(_bidPriceController.text) ?? 0.0;
    return _appliedLots * sharesPerLot * price;
  }

  Future<void> _saveIpo() async {
    final company = _companyController.text.trim();
    if (company.isEmpty) {
      BrutalToast.showError(context, 'PLEASE ENTER COMPANY NAME');
      return;
    }

    final price = double.tryParse(_bidPriceController.text) ?? 0.0;
    if (price <= 0) {
      BrutalToast.showError(context, 'PLEASE ENTER A VALID BID PRICE');
      return;
    }

    final sharesPerLot = int.tryParse(_sharesPerLotController.text) ?? 1;
    final isEditing = widget.existingIpo != null;
    final ipoId = widget.existingIpo?['id'] ??
        widget.existingIpo?['_id'] ??
        'ipo_${DateTime.now().millisecondsSinceEpoch}';

    final totalBlocked = _appliedLots * sharesPerLot * price;
    int finalAllottedLots = 0;
    int finalAllottedShares = 0;
    double finalAllottedAmount = 0.0;
    double finalRefundAmount = 0.0;

    if (_status == 'ALLOTTED') {
      finalAllottedLots = _allottedLots > 0 ? _allottedLots : _appliedLots;
      finalAllottedShares = finalAllottedLots * sharesPerLot;
      finalAllottedAmount = finalAllottedShares * price;
      finalRefundAmount = (totalBlocked - finalAllottedAmount).clamp(0, totalBlocked);
    } else if (_status == 'NOT_ALLOTTED') {
      finalRefundAmount = totalBlocked;
    }

    final registrarUrl = FinApiIpoService.getRegistrarUrl(_registrar, _symbolController.text.trim());

    final ipoData = {
      'id': ipoId,
      'companyName': company,
      'symbol': _symbolController.text.trim().toUpperCase(),
      'ipoType': _ipoType,
      'category': _category,
      'applicantName': _applicantController.text.trim().isEmpty ? 'Self' : _applicantController.text.trim(),
      'pan': _panController.text.trim().toUpperCase(),
      'dematBroker': _broker,
      'bankName': _bankController.text.trim(),
      'upiId': _upiController.text.trim(),
      'appliedLots': _appliedLots,
      'sharesPerLot': sharesPerLot,
      'bidPrice': price,
      'totalAmountBlocked': totalBlocked,
      'status': _status,
      'allottedLots': finalAllottedLots,
      'allottedShares': finalAllottedShares,
      'allottedAmount': finalAllottedAmount,
      'refundAmount': finalRefundAmount,
      'allotmentDate': _allotmentDate?.toIso8601String() ?? '',
      'listingDate': _listingDate?.toIso8601String() ?? '',
      'registrar': _registrar,
      'registrarUrl': registrarUrl,
      'gmp': double.tryParse(_gmpController.text) ?? 0.0,
      'notes': _notesController.text.trim(),
      'createdAt': widget.existingIpo?['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    setState(() => _isSaving = true);
    if (isEditing) {
      await ref.read(ipoProvider.notifier).updateIpo(ipoData);
      if (mounted) {
        BrutalToast.showSuccess(context, 'IPO APPLICATION UPDATED');
        context.pop();
      }
    } else {
      await ref.read(ipoProvider.notifier).addIpo(ipoData);
      if (mounted) {
        BrutalToast.showSuccess(context, 'IPO APPLICATION TRACKED');
        context.pop();
      }
    }
  }

  void _confirmDelete() {
    BrutalDialog.show(
      context: context,
      title: 'DISCARD IPO TRACKER?',
      content: const Text(
        'Delete this IPO application? This action cannot be reversed.',
        style: TextStyle(color: BrutalColors.textSecondary, height: 1.4),
      ),
      confirmText: 'DELETE IPO',
      confirmColor: BrutalColors.red,
      cancelText: 'CANCEL',
      onConfirm: () async {
        final id = (widget.existingIpo?['id'] ?? widget.existingIpo?['_id'] ?? '').toString();
        if (id.isNotEmpty) {
          await ref.read(ipoProvider.notifier).deleteIpo(id);
          if (mounted) {
            BrutalToast.showSuccess(context, 'IPO APPLICATION REMOVED');
            context.pop();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingIpo != null;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: isEditing ? 'EDIT IPO BID' : 'TRACK NEW IPO BID',
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: BrutalColors.red),
              tooltip: 'Delete IPO',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Blocked Hero Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrutalColors.surfaceCard,
                  border: Border.all(color: BrutalColors.primaryYellow, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: BrutalColors.primaryYellow, offset: Offset(4, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL ASBA FUNDS BLOCKED', style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${NumberFormat('#,##,##0').format(_totalBlocked)}',
                      style: BrutalTypography.headingLarge.copyWith(
                        color: BrutalColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_appliedLots Lot(s) × ${(int.tryParse(_sharesPerLotController.text) ?? 1)} Shares @ ₹${_bidPriceController.text}',
                      style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Company & Issue Type
              _buildSectionTitle('1. ISSUE DETAILS'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrutalColors.surface,
                  border: Border.all(color: BrutalColors.border, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'COMPANY NAME *',
                      controller: _companyController,
                      hint: 'e.g. Tata Technologies Limited',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'SYMBOL / TICKER',
                            controller: _symbolController,
                            hint: 'TATATECH',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ISSUE TYPE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildTypeChip('MAINBOARD'),
                                  const SizedBox(width: 6),
                                  _buildTypeChip('SME'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Applicant & Demat Details
              _buildSectionTitle('2. APPLICANT & DEMAT ACCOUNT'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrutalColors.surface,
                  border: Border.all(color: BrutalColors.border, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'APPLICANT NAME',
                      controller: _applicantController,
                      hint: 'Self / Father / Spouse',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'PAN CARD (FOR CA AUDIT)',
                            controller: _panController,
                            hint: 'ABCDE1234F',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BROKER / DP', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: BrutalColors.surfaceCard,
                                  border: Border.all(color: BrutalColors.border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _broker,
                                    isExpanded: true,
                                    dropdownColor: BrutalColors.surfaceElevated,
                                    style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                                    items: _brokers.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _broker = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'BANK NAME (ASBA)',
                            controller: _bankController,
                            hint: 'HDFC / SBI / ICICI',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'UPI ID (MANDATE)',
                            controller: _upiController,
                            hint: 'name@oksbi',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Bid Sizing & Category
              _buildSectionTitle('3. BID LOTS & PRICING'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrutalColors.surface,
                  border: Border.all(color: BrutalColors.border, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Applied Lots Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LOTS APPLIED', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('$_appliedLots Lot(s)', style: BrutalTypography.headingSmall),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: BrutalColors.surfaceElevated,
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              icon: const Icon(Icons.remove, color: BrutalColors.textPrimary),
                              onPressed: _appliedLots > 1
                                  ? () => setState(() => _appliedLots--)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: BrutalColors.primaryYellow,
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              icon: const Icon(Icons.add, color: BrutalColors.textDark),
                              onPressed: () => setState(() => _appliedLots++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: BrutalColors.borderDim, thickness: 1.0, height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'SHARES PER LOT',
                            controller: _sharesPerLotController,
                            keyboardType: TextInputType.number,
                            hint: '30',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'BID PRICE (₹ CUT-OFF)',
                            controller: _bidPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            hint: '500',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('INVESTOR CATEGORY', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((c) {
                          final isSel = _category == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: BrutalChip(
                              label: c,
                              backgroundColor: isSel ? BrutalColors.primaryYellow : BrutalColors.surfaceElevated,
                              textColor: isSel ? BrutalColors.textDark : BrutalColors.textSecondary,
                              borderColor: isSel ? BrutalColors.border : BrutalColors.borderDim,
                              shadowOffset: isSel ? 2.0 : 0.0,
                              onTap: () => setState(() => _category = c),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 4: Status, Allotment & Dates
              _buildSectionTitle('4. APPLICATION STATUS & DATES'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BrutalColors.surface,
                  border: Border.all(color: BrutalColors.border, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT STATUS', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('BLOCKED', BrutalColors.primaryYellow),
                        const SizedBox(width: 6),
                        _buildStatusChip('ALLOTTED', BrutalColors.lime),
                        const SizedBox(width: 6),
                        _buildStatusChip('NOT_ALLOTTED', BrutalColors.red),
                      ],
                    ),

                    if (_status == 'ALLOTTED') ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALLOTTED LOTS', style: BrutalTypography.sticker.copyWith(color: BrutalColors.lime)),
                              const SizedBox(height: 4),
                              Text('$_allottedLots of $_appliedLots Lots', style: BrutalTypography.bodyMedium),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: BrutalColors.surfaceElevated,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.white, width: 1.5),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                icon: const Icon(Icons.remove, color: BrutalColors.textPrimary),
                                onPressed: _allottedLots > 1
                                    ? () => setState(() => _allottedLots--)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: BrutalColors.lime,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.white, width: 1.5),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: BrutalColors.textDark),
                                onPressed: _allottedLots < _appliedLots
                                    ? () => setState(() => _allottedLots++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],

                    const Divider(color: BrutalColors.borderDim, thickness: 1.0, height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            label: 'ALLOTMENT DATE',
                            date: _allotmentDate,
                            onPick: (d) => setState(() => _allotmentDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePicker(
                            label: 'LISTING DATE',
                            date: _listingDate,
                            onPick: (d) => setState(() => _listingDate = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REGISTRAR (LOOKUP)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: BrutalColors.surfaceCard,
                                  border: Border.all(color: BrutalColors.border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _registrar,
                                    isExpanded: true,
                                    dropdownColor: BrutalColors.surfaceElevated,
                                    style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                                    items: _registrars.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _registrar = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'CURRENT GMP (₹)',
                            controller: _gmpController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            hint: '+120',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              BrutalButton(
                text: isEditing ? 'UPDATE IPO APPLICATION' : '+ TRACK IPO BID',
                isLoading: _isSaving,
                backgroundColor: BrutalColors.primaryYellow,
                textColor: BrutalColors.textDark,
                height: 52,
                onPressed: _isSaving ? null : _saveIpo,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: BrutalTypography.sticker.copyWith(
        color: BrutalColors.primaryYellow,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textMuted),
            filled: true,
            fillColor: BrutalColors.surfaceCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final isSel = _ipoType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ipoType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSel ? BrutalColors.primaryYellow : BrutalColors.surfaceCard,
            border: Border.all(color: isSel ? Colors.white : BrutalColors.borderDim, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: BrutalTypography.sticker.copyWith(
              color: isSel ? BrutalColors.textDark : BrutalColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final isSel = _status == status;
    final label = status.replaceAll('_', ' ');
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _status = status;
          if (status == 'ALLOTTED' && _allottedLots <= 0) {
            _allottedLots = _appliedLots;
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? color : BrutalColors.surfaceCard,
            border: Border.all(color: isSel ? Colors.white : BrutalColors.borderDim, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: BrutalTypography.sticker.copyWith(
              fontSize: 10.5,
              color: isSel ? BrutalColors.textDark : BrutalColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2022),
              lastDate: DateTime(2030),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: BrutalColors.surfaceCard,
              border: Border.all(color: BrutalColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'SELECT DATE',
                  style: BrutalTypography.bodyMedium.copyWith(
                    color: date != null ? BrutalColors.textPrimary : BrutalColors.textMuted,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 14, color: BrutalColors.primaryYellow),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
