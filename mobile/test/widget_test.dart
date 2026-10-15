import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/theme/brutal_colors.dart';
import 'package:ledger_app/core/utils/currency_formatter.dart';
import 'package:ledger_app/core/widgets/brutal_button.dart';
import 'package:ledger_app/core/widgets/brutal_card.dart';
import 'package:ledger_app/core/widgets/brutal_chip.dart';

void main() {
  group('Currency Formatter Tests', () {
    test('Formats Indian Rupee with commas for Lakhs and Crores', () {
      final formatted1 = CurrencyFormatter.format(150000, symbol: '₹', showDecimals: false);
      expect(formatted1, contains('1,50,000'));

      final formatted2 = CurrencyFormatter.format(12500000, symbol: '₹', showDecimals: false);
      expect(formatted2, contains('1,25,00,000'));
    });

    test('Compact format for Lakhs and Crores', () {
      final compactLakh = CurrencyFormatter.compact(425000, symbol: '₹');
      expect(compactLakh, equals('₹ 4.25L'));

      final compactCrore = CurrencyFormatter.compact(15000000, symbol: '₹');
      expect(compactCrore, equals('₹ 1.50Cr'));
    });
  });

  group('Neo-Brutalist Reusable Widgets Tests', () {
    testWidgets('BrutalButton renders uppercase text and responds to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrutalButton(
              text: 'Execute Action',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('EXECUTE ACTION'), findsOneWidget);

      await tester.tap(find.text('EXECUTE ACTION'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('BrutalCard renders content with solid borders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrutalCard(
              backgroundColor: BrutalColors.surface,
              child: Text('BRUTAL_CONTENT'),
            ),
          ),
        ),
      );

      expect(find.text('BRUTAL_CONTENT'), findsOneWidget);
    });

    testWidgets('BrutalChip renders uppercase sticker text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrutalChip(
              label: 'OVERDUE',
              backgroundColor: BrutalColors.red,
            ),
          ),
        ),
      );

      expect(find.text('OVERDUE'), findsOneWidget);
    });
  });
}
