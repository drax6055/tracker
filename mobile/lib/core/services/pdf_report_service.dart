import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  PdfReportService._();

  /// Generates a comprehensive, neo-brutalist PDF financial report
  static Future<Uint8List> generateReportBytes({
    String userName = 'Bruce Wayne',
    String userEmail = 'bruce@wayne.corp',
    String currencySymbol = '₹',
    String period = 'OCTOBER 2026',
  }) async {
    final pdf = pw.Document();
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

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
              _buildMetricBox('NET WORTH', '$currencySymbol 8,45,200', yellow, black, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('INFLOW (INCOME)', '$currencySymbol 1,25,000', green, white, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('OUTFLOW (EXPENSE)', '$currencySymbol 48,500', red, white, flex: 2),
              pw.SizedBox(width: 8),
              _buildMetricBox('SAVINGS RATE', '61.2%', cyan, black, flex: 1),
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
                    pw.Text('$currencySymbol 12,50,000.00', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: green)),
                  ],
                ),
                pw.Container(width: 1.5, height: 30, color: black),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TOTAL LIABILITIES', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('$currencySymbol 4,04,800.00', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: red)),
                  ],
                ),
                pw.Container(width: 1.5, height: 30, color: black),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NET POSITION', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('$currencySymbol 8,45,200.00', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: black)),
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
            data: [
              ['HDFC Salaried Account', 'BANK ACCOUNT', '•••• 4821', 'Active Salary Credit', '$currencySymbol 4,25,000.00'],
              ['Physical Cash Vault', 'CASH WALLET', 'CASH SAFE', 'Liquid Reserve', '$currencySymbol 24,500.00'],
              ['Infinia Metal Card', 'CREDIT CARD', '•••• 9920', 'Limit: $currencySymbol 5,00,000 (9.7% Used)', '$currencySymbol 48,500.00'],
              ['Auto Loan (SBI)', 'LOAN / DEBT', 'SBI AUTO', 'EMI: $currencySymbol 14,500 Due 5th', '-$currencySymbol 3,56,300.00'],
            ],
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
            data: [
              ['Food & Groceries', '35.0%', 'Primary Household', '$currencySymbol 16,975.00'],
              ['Rent & Utilities', '25.0%', 'Living Essentials', '$currencySymbol 12,125.00'],
              ['Travel & Commute', '20.0%', 'Fuel & Rideshare', '$currencySymbol 9,700.00'],
              ['Shopping & Gadgets', '12.0%', 'Discretionary', '$currencySymbol 5,820.00'],
              ['Entertainment', '8.0%', 'Dining Out / Movies', '$currencySymbol 3,880.00'],
            ],
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
            data: [
              ['14 Oct 2026, 10:30 AM', 'Monthly Salary Deposit', 'Salary', 'HDFC Salaried', 'INFLOW', '+$currencySymbol 1,25,000.00'],
              ['13 Oct 2026, 08:15 PM', 'Whole Foods Organic Groceries', 'Food', 'Infinia Metal', 'OUTFLOW', '-$currencySymbol 3,450.00'],
              ['12 Oct 2026, 04:00 PM', 'ATM Cash Safe Withdrawal', 'Transfer', 'HDFC -> Vault', 'TRANSFER', '$currencySymbol 10,000.00'],
              ['12 Oct 2026, 02:45 PM', 'Uber Ride Airport Terminal', 'Travel', 'Cash Vault', 'OUTFLOW', '-$currencySymbol 850.00'],
              ['10 Oct 2026, 09:00 AM', 'Car Loan Fixed Monthly EMI', 'Loan EMI', 'HDFC Salaried', 'OUTFLOW', '-$currencySymbol 14,500.00'],
            ],
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
            data: [
              ['Peter Parker', 'LENT (TO RECEIVE)', '$currencySymbol 50,000.00', '$currencySymbol 35,000.00', '20 Oct 2026', 'Partially Settled'],
              ['Tony Stark', 'BORROWED (I OWE)', '$currencySymbol 18,000.00', '$currencySymbol 18,000.00', '25 Oct 2026', 'Pending Payment'],
              ['Clark Kent', 'LENT (TO RECEIVE)', '$currencySymbol 12,000.00', '$currencySymbol 0.00', '01 Oct 2026', 'Fully Cleared'],
            ],
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
