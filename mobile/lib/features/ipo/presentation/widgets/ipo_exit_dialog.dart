import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/theme/brutal_typography.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_toast.dart';

class IpoExitDialog extends StatefulWidget {
  final Map<String, dynamic> ipo;
  final Function(double exitPrice, int exitShares, String exitDate) onConfirm;

  const IpoExitDialog({
    super.key,
    required this.ipo,
    required this.onConfirm,
  });

  @override
  State<IpoExitDialog> createState() => _IpoExitDialogState();
}

class _IpoExitDialogState extends State<IpoExitDialog> {
  late TextEditingController _exitPriceController;
  late TextEditingController _exitSharesController;
  late DateTime _selectedExitDate;

  @override
  void initState() {
    super.initState();
    final allottedShares = widget.ipo['allottedShares'] ??
        ((widget.ipo['allottedLots'] ?? widget.ipo['appliedLots'] ?? 1) *
            (widget.ipo['sharesPerLot'] ?? 1));
    _exitSharesController = TextEditingController(text: allottedShares.toString());
    _exitPriceController = TextEditingController(text: widget.ipo['bidPrice']?.toString() ?? '0');
    _selectedExitDate = DateTime.now();
  }

  @override
  void dispose() {
    _exitPriceController.dispose();
    _exitSharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.ipo['companyName'] ?? widget.ipo['symbol'] ?? 'IPO';
    final bidPrice = (widget.ipo['bidPrice'] as num?)?.toDouble() ?? 0.0;

    final exitPrice = double.tryParse(_exitPriceController.text) ?? 0.0;
    final exitShares = int.tryParse(_exitSharesController.text) ?? 0;

    final grossProceeds = exitPrice * exitShares;
    const dpCharges = 15.93;
    final sttCharges = grossProceeds > 0 ? (grossProceeds * 0.001) : 0.0;
    final buyCost = exitShares * bidPrice;
    final netGain = grossProceeds > 0 ? (grossProceeds - buyCost - dpCharges - sttCharges) : 0.0;
    final roiPct = buyCost > 0 ? (netGain / buyCost) * 100 : 0.0;
    final isProfit = netGain >= 0;

    return Dialog(
      backgroundColor: BrutalColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: BrutalColors.primaryYellow, width: 2.5),
        borderRadius: BorderRadius.zero,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECORD EXIT // P&L', style: BrutalTypography.sticker.copyWith(color: BrutalColors.primaryYellow)),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BrutalTypography.headingMedium.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: BrutalColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: BrutalColors.border, thickness: 1.5, height: 24),

              // Sell Price per share
              Text('SELL / EXIT PRICE PER SHARE (₹)', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _exitPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: BrutalTypography.headingSmall.copyWith(color: BrutalColors.primaryYellow),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: BrutalColors.primaryYellow, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: BrutalColors.surface,
                ),
              ),
              const SizedBox(height: 14),

              // Quantity of shares exited
              Text('SHARES SOLD', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _exitSharesController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: BrutalTypography.bodyLarge.copyWith(color: BrutalColors.textPrimary),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: BrutalColors.surface,
                ),
              ),
              const SizedBox(height: 14),

              // Sell Date Picker
              Text('SALE / EXIT DATE', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedExitDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _selectedExitDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: BrutalColors.surface,
                    border: Border.all(color: BrutalColors.border, width: 2.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedExitDate),
                        style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary),
                      ),
                      const Icon(Icons.calendar_today, size: 16, color: BrutalColors.primaryYellow),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calculated P&L Box (CA Grade)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isProfit ? const Color(0xFF142918) : const Color(0xFF2C1414),
                  border: Border.all(
                    color: isProfit ? BrutalColors.lime : BrutalColors.red,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GROSS SALE VALUE:', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                        Text('₹${grossProceeds.toStringAsFixed(2)}', style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PURCHASE COST:', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                        Text('₹${buyCost.toStringAsFixed(2)}', style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DEDUCTIONS (DP + STT):', style: BrutalTypography.sticker.copyWith(color: BrutalColors.textSecondary)),
                        Text('₹${(dpCharges + sttCharges).toStringAsFixed(2)}', style: BrutalTypography.bodyMedium.copyWith(color: BrutalColors.textSecondary)),
                      ],
                    ),
                    const Divider(color: BrutalColors.borderDim, thickness: 1.0, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isProfit ? 'NET REALIZED GAIN:' : 'NET REALIZED LOSS:',
                          style: BrutalTypography.sticker.copyWith(
                            color: isProfit ? BrutalColors.lime : BrutalColors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${isProfit ? '+' : ''}₹${netGain.toStringAsFixed(2)} (${roiPct.toStringAsFixed(1)}%)',
                          style: BrutalTypography.headingSmall.copyWith(
                            color: isProfit ? BrutalColors.lime : BrutalColors.red,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action buttons
              BrutalButton(
                text: 'CONFIRM EXIT & SAVE GAIN',
                backgroundColor: BrutalColors.primaryYellow,
                textColor: BrutalColors.textDark,
                onPressed: () {
                  if (exitPrice <= 0 || exitShares <= 0) {
                    BrutalToast.showError(context, 'PLEASE ENTER VALID PRICE AND SHARES');
                    return;
                  }
                  widget.onConfirm(
                    exitPrice,
                    exitShares,
                    _selectedExitDate.toIso8601String(),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

