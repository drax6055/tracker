import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  String _selectedType = 'BORROWED'; // BORROWED (I have to pay) or LENT (I have to receive)
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_personController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      BrutalToast.showError(context, 'PERSON AND AMOUNT ARE REQUIRED');
      return;
    }
    BrutalToast.showSuccess(context, 'DEBT ENTRY SAVED TO LEDGER');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _selectedType == 'BORROWED' ? BrutalColors.orange : BrutalColors.lime;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: const BrutalAppBar(
        title: 'NEW PEOPLE ENTRY',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BrutalButton(
                      text: 'BORROWED (I OWE)',
                      backgroundColor: _selectedType == 'BORROWED' ? BrutalColors.orange : BrutalColors.surfaceElevated,
                      textColor: _selectedType == 'BORROWED' ? BrutalColors.textDark : BrutalColors.textSecondary,
                      borderColor: _selectedType == 'BORROWED' ? BrutalColors.border : BrutalColors.borderDim,
                      height: 44,
                      onPressed: () => setState(() => _selectedType = 'BORROWED'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrutalButton(
                      text: 'LENT (THEY OWE)',
                      backgroundColor: _selectedType == 'LENT' ? BrutalColors.lime : BrutalColors.surfaceElevated,
                      textColor: _selectedType == 'LENT' ? BrutalColors.textDark : BrutalColors.textSecondary,
                      borderColor: _selectedType == 'LENT' ? BrutalColors.border : BrutalColors.borderDim,
                      height: 44,
                      onPressed: () => setState(() => _selectedType = 'LENT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              BrutalCard(
                backgroundColor: BrutalColors.surface,
                borderColor: BrutalColors.border,
                shadowColor: accent,
                shadowOffset: 6.0,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrutalTextField(
                      controller: _personController,
                      label: 'Person / Contact Name',
                      hintText: 'e.g. Peter Parker, Tony Stark',
                      prefixIcon: const Icon(Icons.person, color: BrutalColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: _amountController,
                      label: 'Amount (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.currency_rupee, color: BrutalColors.primaryYellow),
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: _dueDateController,
                      label: 'Expected Due Date',
                      hintText: 'e.g. 25 Oct 2026',
                      prefixIcon: const Icon(Icons.calendar_today, color: BrutalColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    BrutalTextField(
                      controller: _notesController,
                      label: 'Description / Purpose',
                      hintText: 'e.g. Office laptop expense split',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    BrutalButton(
                      text: 'COMMIT TO LEDGER',
                      backgroundColor: accent,
                      textColor: BrutalColors.textDark,
                      height: 52,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
