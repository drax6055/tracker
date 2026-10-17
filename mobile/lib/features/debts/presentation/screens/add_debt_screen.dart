import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/brutal_colors.dart';
import '../../../../core/widgets/brutal_app_bar.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_text_field.dart';
import '../../../../core/widgets/brutal_toast.dart';
import '../controllers/debts_controller.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? debtToEdit;

  const AddDebtScreen({super.key, this.debtToEdit});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  String _selectedType = 'BORROWED'; // BORROWED (I have to pay) or LENT (I have to receive)
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool get isEditing => widget.debtToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      final d = widget.debtToEdit!;
      _selectedType = (d['type'] ?? 'BORROWED').toString().toUpperCase();
      _personController.text = (d['person'] ?? '').toString();
      _amountController.text = (d['originalAmount'] ?? '').toString();
      _dueDateController.text = (d['dueDate'] ?? '').toString();
      _notesController.text = (d['notes'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
        _dueDateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final person = _personController.text.trim();
    final amountText = _amountController.text.trim();

    if (person.isEmpty || amountText.isEmpty) {
      BrutalToast.showError(context, 'PERSON AND AMOUNT ARE REQUIRED');
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      BrutalToast.showError(context, 'AMOUNT MUST BE GREATER THAN ZERO');
      return;
    }

    final dueDate = _dueDateController.text.trim().isNotEmpty
        ? _dueDateController.text.trim()
        : DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 7)));
    final notes = _notesController.text.trim();

    if (isEditing) {
      final updated = Map<String, dynamic>.from(widget.debtToEdit!);
      final prevOriginal = (updated['originalAmount'] as num?)?.toDouble() ?? amount;
      final prevRemaining = (updated['remainingAmount'] as num?)?.toDouble() ?? amount;

      updated['person'] = person;
      updated['type'] = _selectedType;
      updated['originalAmount'] = amount;
      // Adjust remaining proportionally or clamp to new amount
      if (prevRemaining == prevOriginal || prevRemaining > amount) {
        updated['remainingAmount'] = amount;
      }
      updated['dueDate'] = dueDate;
      updated['notes'] = notes;

      await ref.read(debtsProvider.notifier).updateDebt(updated);
      if (mounted) {
        BrutalToast.showSuccess(context, 'PEOPLE ENTRY UPDATED');
        context.pop();
      }
    } else {
      final newDebt = {
        'id': 'debt_${DateTime.now().millisecondsSinceEpoch}',
        'person': person,
        'type': _selectedType,
        'originalAmount': amount,
        'remainingAmount': amount,
        'dueDate': dueDate,
        'status': 'PENDING',
        'notes': notes,
      };

      await ref.read(debtsProvider.notifier).addDebt(newDebt);
      if (mounted) {
        BrutalToast.showSuccess(context, 'DEBT ENTRY SAVED TO LEDGER');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _selectedType == 'BORROWED' ? BrutalColors.orange : BrutalColors.lime;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalAppBar(
        title: isEditing ? 'EDIT PEOPLE ENTRY' : 'NEW PEOPLE ENTRY',
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
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: AbsorbPointer(
                        child: BrutalTextField(
                          controller: _dueDateController,
                          label: 'Expected Due Date',
                          hintText: 'Tap to select due date...',
                          prefixIcon: const Icon(Icons.calendar_today, color: BrutalColors.textPrimary),
                        ),
                      ),
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
                      text: isEditing ? 'UPDATE ENTRY' : 'COMMIT TO LEDGER',
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
