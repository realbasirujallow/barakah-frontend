import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _reportTypes = [
    {'id': 'portfolio', 'title': 'Portfolio Summary', 'icon': Icons.pie_chart, 'desc': 'Asset holdings & allocation'},
    {'id': 'zakat', 'title': 'Zakat Statement', 'icon': Icons.volunteer_activism, 'desc': 'Zakat calculation breakdown'},
    {'id': 'transactions', 'title': 'Transaction History', 'icon': Icons.receipt_long, 'desc': 'Income & expense records'},
    {'id': 'full', 'title': 'Full Financial Report', 'icon': Icons.assessment, 'desc': 'Complete financial overview'},
  ];

  Future<void> _generateReport(String type) async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = ApiService(authService);
      final now = DateTime.now();
      final dateStr = DateFormat('MMMM d, yyyy').format(now);

      // Fetch data
      final assets = await apiService.getAssets();
      final zakatData = await apiService.getAssetTotal();
      Map<String, dynamic>? txSummary;
      List<dynamic>? transactions;

      if (type == 'transactions' || type == 'full') {
        try {
          txSummary = await apiService.getTransactionSummary(period: 'year');
          transactions = await apiService.getTransactions();
        } catch (_) {}
      }

      final totalWealth = (zakatData['totalWealth'] ?? 0).toDouble();
      final zakatDue = (zakatData['zakatDue'] ?? 0).toDouble();
      final nisab = (zakatData['nisab'] ?? 0).toDouble();
      final zakatEligible = zakatData['zakatEligible'] ?? false;

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildPdfHeader(dateStr),
          footer: (context) => _buildPdfFooter(context),
          build: (context) {
            List<pw.Widget> content = [];

            if (type == 'portfolio' || type == 'full') {
              content.addAll(_buildPortfolioSection(assets, totalWealth));
            }
            if (type == 'zakat' || type == 'full') {
              content.addAll(_buildZakatSection(totalWealth, nisab, zakatDue, zakatEligible));
            }
            if (type == 'transactions' || type == 'full') {
              content.addAll(_buildTransactionsSection(transactions, txSummary));
            }

            return content;
          },
        ),
      );

      // Show preview & print/share
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Barakah_${type}_Report_${DateFormat('yyyyMMdd').format(now)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  pw.Widget _buildPdfHeader(String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Barakah', style: pw.TextStyle(
                fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
              )),
              pw.Text('Islamic Finance Tracker', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated: $date', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text('Bismillah', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Barakah - May your wealth be blessed',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  List<pw.Widget> _buildPortfolioSection(List<dynamic> assets, double totalWealth) {
    final formatter = NumberFormat.currency(symbol: '\$');

    // Group by type
    final Map<String, double> byType = {};
    for (var a in assets) {
      final type = a.type ?? 'Other';
      byType[type] = (byType[type] ?? 0) + (a.value ?? 0).toDouble();
    }

    return [
      pw.SizedBox(height: 20),
      pw.Text('PORTFOLIO SUMMARY', style: pw.TextStyle(
        fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
      )),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.green50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Total Wealth', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(formatter.format(totalWealth), style: pw.TextStyle(
              fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
            )),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
      // Allocation table
      if (byType.isNotEmpty) ...[
        pw.Text('Asset Allocation', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green100),
              children: [
                _cell('Asset Type', bold: true),
                _cell('Value', bold: true),
                _cell('%', bold: true),
              ],
            ),
            ...byType.entries.map((e) => pw.TableRow(children: [
              _cell(e.key),
              _cell(formatter.format(e.value)),
              _cell(totalWealth > 0 ? '${(e.value / totalWealth * 100).toStringAsFixed(1)}%' : '0%'),
            ])),
          ],
        ),
      ],
      pw.SizedBox(height: 12),
      // Individual assets
      pw.Text('Individual Holdings (${assets.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.green100),
            children: [
              _cell('Name', bold: true),
              _cell('Type', bold: true),
              _cell('Value', bold: true),
            ],
          ),
          ...assets.map((a) => pw.TableRow(children: [
            _cell(a.name ?? ''),
            _cell(a.type ?? ''),
            _cell(formatter.format((a.value ?? 0).toDouble())),
          ])),
        ],
      ),
    ];
  }

  List<pw.Widget> _buildZakatSection(double totalWealth, double nisab, double zakatDue, bool zakatEligible) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return [
      pw.SizedBox(height: 24),
      pw.Text('ZAKAT STATEMENT', style: pw.TextStyle(
        fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
      )),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            _zakatRow('Total Zakatable Wealth', formatter.format(totalWealth)),
            pw.SizedBox(height: 8),
            _zakatRow('Nisab Threshold', formatter.format(nisab)),
            pw.SizedBox(height: 8),
            _zakatRow('Zakat Eligible', zakatEligible ? 'Yes' : 'No'),
            pw.Divider(color: PdfColors.green800),
            _zakatRow('Zakat Due (2.5%)', formatter.format(zakatDue),
                highlight: true),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          '"Take from their wealth a charity to purify and cleanse them." - Quran 9:103',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
        ),
      ),
    ];
  }

  List<pw.Widget> _buildTransactionsSection(List<dynamic>? transactions, Map<String, dynamic>? summary) {
    final formatter = NumberFormat.currency(symbol: '\$');
    List<pw.Widget> content = [
      pw.SizedBox(height: 24),
      pw.Text('TRANSACTION HISTORY', style: pw.TextStyle(
        fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800,
      )),
      pw.SizedBox(height: 12),
    ];

    if (summary != null) {
      content.add(pw.Row(
        children: [
          _summaryBox('Income', formatter.format(summary['income'] ?? 0), PdfColors.green100),
          pw.SizedBox(width: 12),
          _summaryBox('Expenses', formatter.format(summary['expenses'] ?? 0), PdfColors.red100),
          pw.SizedBox(width: 12),
          _summaryBox('Net', formatter.format(summary['net'] ?? 0), PdfColors.blue100),
        ],
      ));
      content.add(pw.SizedBox(height: 12));
    }

    if (transactions != null && transactions.isNotEmpty) {
      content.add(pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.green100),
            children: [
              _cell('Date', bold: true),
              _cell('Category', bold: true),
              _cell('Type', bold: true),
              _cell('Amount', bold: true),
              _cell('Description', bold: true),
            ],
          ),
          ...transactions.take(50).map((t) {
            final date = t.timestamp != null
                ? DateFormat('MMM d').format(DateTime.parse(t.timestamp.toString()))
                : '-';
            return pw.TableRow(children: [
              _cell(date),
              _cell(t.category ?? '-'),
              _cell(t.type ?? '-'),
              _cell(formatter.format((t.amount ?? 0).toDouble())),
              _cell(t.description ?? '-'),
            ]);
          }),
        ],
      ));
      if (transactions.length > 50) {
        content.add(pw.SizedBox(height: 4));
        content.add(pw.Text('... and ${transactions.length - 50} more transactions',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)));
      }
    } else {
      content.add(pw.Text('No transactions found.', style: const pw.TextStyle(color: PdfColors.grey500)));
    }

    return content;
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      )),
    );
  }

  pw.Widget _zakatRow(String label, String value, {bool highlight = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(
          fontSize: highlight ? 14 : 12,
          fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
        )),
        pw.Text(value, style: pw.TextStyle(
          fontSize: highlight ? 16 : 12,
          fontWeight: pw.FontWeight.bold,
          color: highlight ? PdfColors.green800 : PdfColors.black,
        )),
      ],
    );
  }

  pw.Widget _summaryBox(String label, String value, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.deepGreen),
                  SizedBox(height: 16),
                  Text('Generating report...', style: TextStyle(color: AppTheme.deepGreen)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text('PDF Reports', style: TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                      )),
                      SizedBox(height: 4),
                      Text('Generate & share professional reports',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Report options
                ..._reportTypes.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _generateReport(r['id']),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.deepGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(r['icon'], color: AppTheme.deepGreen, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['title'], style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16,
                                  )),
                                  Text(r['desc'], style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant, fontSize: 13,
                                  )),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.download, color: AppTheme.deepGreen),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 16),
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withAlpha(60)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.deepGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reports are generated as PDF files. You can print, save, or share them directly.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
