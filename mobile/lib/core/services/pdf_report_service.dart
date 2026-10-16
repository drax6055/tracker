import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../storage/secure_storage_service.dart';

class PdfReportService {
  PdfReportService._();

  /// Generates a comprehensive, neo-brutalist PDF financial report
  static Future<Uint8List> generateReportBytes({
    String userName = 'Bruce Wayne',
    String userEmail = 'bruce@wayne.corp',
    String currencySymbol = '₹',
    String period = 'OCTOBER 2026',
  }) async {
    // Load Unicode fonts that support the Indian Rupee symbol '₹' (U+20B9) and bullets '•' (U+2022)
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.notoSansRegular();
      fontBold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.robotoRegular();
        fontBold = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    final pdf = pw.Document(theme: theme);
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final String pdfCurrency = currencySymbol.trim().isEmpty ? '₹' : currencySymbol.trim();

    String formatAmt(num val) {
      try {
        final f = NumberFormat('#,##,##0.00');
        return '$pdfCurrency ${f.format(val)}';
      } catch (_) {
        return '$pdfCurrency ${val.toStringAsFixed(2)}';
      }
    }

    final accounts = await SecureStorageService.getAccounts();
    final transactions = await SecureStorageService.getTransactions();
    final debts = await SecureStorageService.getDebts();
    final isDemo = await SecureStorageService.isCurrentUserDemo();

    // Calculate dynamic financials
    double netWorth = 0.0;
    double totalAssets = 0.0;
    double totalLiabilities = 0.0;
    double totalInflow = 0.0;
    double totalOutflow = 0.0;

    if (isDemo && accounts.isEmpty && transactions.isEmpty) {
      netWorth = 845200.0;
      totalAssets = 1250000.0;
      totalLiabilities = 404800.0;
      totalInflow = 125000.0;
      totalOutflow = 48500.0;
    } else {
      for (final a in accounts) {
        if (a['includeInNetWorth'] == false) continue;
        final bal = (a['balance'] as num?)?.toDouble() ?? 0.0;
        final type = (a['type'] ?? 'BANK').toString().toUpperCase();
        if (type == 'LOAN' || type == 'CREDIT_CARD') {
          totalLiabilities += bal;
        } else {
          totalAssets += bal;
        }
      }

      for (final d in debts) {
        final rem = (d['remainingAmount'] as num?)?.toDouble() ?? 0.0;
        final type = (d['type'] ?? 'BORROWED').toString();
        if (type == 'BORROWED') {
          totalLiabilities += rem;
        } else if (type == 'LENT') {
          totalAssets += rem;
        }
      }

      netWorth = totalAssets - totalLiabilities;

      for (final t in transactions) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (t['type'] ?? 'EXPENSE').toString().toUpperCase();
        if (type == 'INCOME') {
          totalInflow += amt;
        } else if (type == 'EXPENSE') {
          totalOutflow += amt;
        }
      }
    }

    final netSavings = totalInflow - totalOutflow;
    final double savingsRate = totalInflow > 0
        ? ((netSavings / totalInflow) * 100).clamp(0.0, 100.0)
        : 0.0;

    // Group expenses by category
    final Map<String, double> catExpenses = {};
    for (final t in transactions) {
      if ((t['type'] ?? 'EXPENSE').toString().toUpperCase() == 'EXPENSE') {
        final cat = (t['category'] ?? 'General').toString();
        final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
        catExpenses[cat] = (catExpenses[cat] ?? 0.0) + amt;
      }
    }

    List<List<String>> categoryRows = [];
    if (isDemo && catExpenses.isEmpty) {
      categoryRows = [
        ['Food & Groceries', '35.0%', 'Primary Household', formatAmt(16975.00)],
        ['Rent & Utilities', '25.0%', 'Living Essentials', formatAmt(12125.00)],
        ['Travel & Commute', '20.0%', 'Fuel & Rideshare', formatAmt(9700.00)],
        ['Shopping & Gadgets', '12.0%', 'Discretionary', formatAmt(5820.00)],
        ['Entertainment', '8.0%', 'Dining Out / Movies', formatAmt(3880.00)],
      ];
    } else if (catExpenses.isEmpty) {
      categoryRows = [
        ['No expenses recorded yet', '0.0%', 'No transactions', formatAmt(0.00)],
      ];
    } else {
      categoryRows = catExpenses.entries.map((e) {
        final pct = totalOutflow > 0 ? (e.value / totalOutflow * 100).toStringAsFixed(1) : '0.0';
        return [
          e.key,
          '$pct%',
          'Audited Spend',
          formatAmt(e.value),
        ];
      }).toList();
    }

    // Clean Brutalist Palette
    const black = PdfColor.fromInt(0xFF000000);
    const white = PdfColor.fromInt(0xFFFFFFFF);
    const yellow = PdfColor.fromInt(0xFFFFE600);
    const greySurface = PdfColor.fromInt(0xFFF4F4F4);
    const green = PdfColor.fromInt(0xFF00C853);
    const red = PdfColor.fromInt(0xFFFF3366);
    const cyan = PdfColor.fromInt(0xFF00E5FF);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: black, width: 3),
            ),
          ),
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: yellow,
                    child: pw.Text(
                      'LEDGER // AUDIT INTELLIGENCE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: black,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'FINANCIAL STATEMENT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 22,
                      color: black,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('OPERATOR: ${userName.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('EMAIL: $userEmail', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('DATE: $nowFormatted', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: black, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CONFIDENTIAL // LEDGER PWA PROTOCOL // PAGE ${context.pageNumber} OF ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'VERIFIED BY LEDGER ENGINE',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: black),
              ),
            ],
          ),
        ),
        build: (context) => [
          // 1. Executive Summary Cards (Net worth, Inflow, Outflow, Savings)
          pw.Text('1. EXECUTIVE SUMMARY // $period', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildMetricBox('NET WORTH', formatAmt(netWorth), yellow, black, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('INFLOW (INCOME)', formatAmt(totalInflow), green, white, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('OUTFLOW (EXPENSE)', formatAmt(totalOutflow), red, white, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('SAVINGS RATE', '${savingsRate.toStringAsFixed(1)}%', cyan, black, flex: 1),
            ],
          ),
          pw.SizedBox(height: 20),

          // 2. Assets & Liabilities Balance
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: greySurface,
              border: pw.Border.all(color: black, width: 2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TOTAL ASSETS', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatAmt(totalAssets), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: green)),
                  ],
                ),
                pw.Container(width: 1.5, height: 30, color: black),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TOTAL LIABILITIES', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatAmt(totalLiabilities), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: red)),
                  ],
                ),
                pw.Container(width: 1.5, height: 30, color: black),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NET POSITION', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(formatAmt(netWorth), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: black)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // 3. Accounts Vault Status Table
          pw.Text('2. ACCOUNTS VAULT BREAKDOWN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: black, width: 1.5),
            headerDecoration: const pw.BoxDecoration(color: yellow),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: black),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['ACCOUNT NAME', 'TYPE', 'IDENTIFIER', 'STATUS / NOTE', 'BALANCE'],
            data: accounts.isEmpty
                ? [
                    ['No accounts created yet in vault', '-', '-', 'Active', formatAmt(0.00)]
                  ]
                : accounts.map((a) {
                    final bal = (a['balance'] as num?)?.toDouble() ?? 0.0;
                    return [
                      (a['title'] ?? 'Account').toString(),
                      (a['type'] ?? 'BANK').toString(),
                      (a['digits'] ?? '').toString().isNotEmpty ? '•••• ${a['digits']}' : 'VAULT',
                      (a['subtitle'] ?? 'Active').toString(),
                      formatAmt(bal),
                    ];
                  }).toList(),
          ),
          pw.SizedBox(height: 24),

          // 4. Category Spending Distribution
          pw.Text('3. MONTHLY EXPENSE BY CATEGORY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: black, width: 1.5),
            headerDecoration: const pw.BoxDecoration(color: black),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: white),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            headers: ['CATEGORY', 'PERCENTAGE', 'SHARE', 'ALLOCATED AMOUNT'],
            data: categoryRows,
          ),
          pw.SizedBox(height: 24),

          // 5. Recent Transaction Journal
          pw.Text('4. AUDIT JOURNAL // RECENT TRANSACTIONS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: black, width: 1.5),
            headerDecoration: const pw.BoxDecoration(color: greySurface),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: black),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            headers: ['DATE', 'TRANSACTION DESCRIPTION', 'CATEGORY', 'ACCOUNT', 'FLOW', 'AMOUNT'],
            data: transactions.isEmpty
                ? [
                    ['-', 'No transactions logged in this period', '-', '-', '-', formatAmt(0.00)]
                  ]
                : transactions.take(15).map((t) {
                    final type = (t['type'] ?? 'EXPENSE').toString();
                    final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
                    final prefix = type == 'INCOME' ? '+' : type == 'EXPENSE' ? '-' : '';
                    return [
                      (t['date'] ?? '').toString(),
                      (t['title'] ?? 'Entry').toString(),
                      (t['category'] ?? 'General').toString(),
                      (t['account'] ?? 'Vault').toString(),
                      type == 'INCOME' ? 'INFLOW' : type == 'EXPENSE' ? 'OUTFLOW' : 'TRANSFER',
                      '$prefix${formatAmt(amt)}',
                    ];
                  }).toList(),
          ),
          pw.SizedBox(height: 24),

          // 6. People Debts & Receivables
          pw.Text('5. COUNTERPARTY DEBTS & RECEIVABLES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: black, width: 1.5),
            headerDecoration: const pw.BoxDecoration(color: yellow),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: black),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            headers: ['COUNTERPARTY', 'TYPE', 'ORIGINAL LOAN', 'REMAINING DUE', 'DUE DATE', 'STATUS'],
            data: debts.isEmpty
                ? [
                    ['No debts or receivables recorded', '-', '-', '-', '-', 'None']
                  ]
                : debts.map((d) {
                    final orig = (d['originalAmount'] as num?)?.toDouble() ?? 0.0;
                    final rem = (d['remainingAmount'] as num?)?.toDouble() ?? 0.0;
                    final type = (d['type'] ?? 'BORROWED').toString();
                    return [
                      (d['person'] ?? 'Person').toString(),
                      type == 'LENT' ? 'LENT (TO RECEIVE)' : 'BORROWED (I OWE)',
                      formatAmt(orig),
                      formatAmt(rem),
                      (d['dueDate'] ?? '').toString(),
                      (d['status'] ?? 'ACTIVE').toString(),
                    ];
                  }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Directly triggers file download or print layout preview across web & mobile
  static Future<void> exportAndDownloadPdf({
    String userName = 'Bruce Wayne',
    String userEmail = 'bruce@wayne.corp',
    String currencySymbol = '₹',
    String period = 'OCTOBER 2026',
  }) async {
    final bytes = await generateReportBytes(
      userName: userName,
      userEmail: userEmail,
      currencySymbol: currencySymbol,
      period: period,
    );

    final filename = 'LEDGER_Financial_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    // Share / download directly
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }

  /// Opens the interactive print / PDF preview sheet
  static Future<void> openPrintPreview({
    String userName = 'Bruce Wayne',
    String userEmail = 'bruce@wayne.corp',
    String currencySymbol = '₹',
    String period = 'OCTOBER 2026',
  }) async {
    await Printing.layoutPdf(
      name: 'LEDGER_Financial_Report',
      onLayout: (PdfPageFormat format) async {
        return generateReportBytes(
          userName: userName,
          userEmail: userEmail,
          currencySymbol: currencySymbol,
          period: period,
        );
      },
    );
  }
}

pw.Widget _buildMetricBox(String title, String value, PdfColor bg, PdfColor text, {int flex = 1}) {
  return pw.Expanded(
    flex: flex,
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF000000), width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: text,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.FittedBox(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: text,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
