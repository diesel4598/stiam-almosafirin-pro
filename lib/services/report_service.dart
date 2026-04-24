import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;

class ReportService {
  static Future<void> generateMonthlyReport({
    required String monthName,
    required List<Map<String, dynamic>> dailyStats,
  }) async {
    final pdf = pw.Document();

    // Support for Arabic text in PDF (requires a font that supports it)
    // For now, using standard provided fonts if available, or just standard ones.
    // Note: Generating Arabic PDF in Flutter can be tricky without the right font.
    // We'll try to use a basic font or just standard for now, but usually needs a .ttf font file.
    
    // Attempting to load a font from assets if we had one. 
    // Since we don't have a customized .ttf asset right now, 
    // we'll stick to a basic layout.

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gestion de Distribution d\'Eau', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rapport Mensuel - $monthName', style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Voyageurs', 'Bouteilles Distribuées'],
              data: dailyStats.map((stat) => [
                stat['date'] ?? 'N/A',
                (stat['totalPassengers'] ?? 0).toString(),
                (stat['totalBottles'] ?? 0).toString(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Généré le: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> generateInventoryReport({
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('État des Stocks - Transport Alexandrie', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date/Heure', 'N° Bon/Reçu', 'Nom de l\'Article', 'Quantité', 'Unité'],
              data: items.map((item) => [
                item['receiptDateTime'] ?? 'N/A',
                item['receiptNumber'] ?? 'N/A',
                item['name'] ?? 'N/A',
                (item['quantity'] ?? 0).toString(),
                item['unit'] ?? '',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('État généré le: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
