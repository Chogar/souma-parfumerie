import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportService {
  static Future<void> exportDailyPdf(
    Map<String, dynamic> daily,
    List<Map<String, dynamic>> top,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('SOUMAPARFUMERIE — Rapport journalier')),
          pw.SizedBox(height: 12),
          pw.Text('Recettes: ${daily['revenue']}'),
          pw.Text('Transactions: ${daily['transactions']}'),
          pw.Text('Panier moyen: ${daily['avg_basket']}'),
          pw.SizedBox(height: 16),
          pw.Text('Top produits', style: pw.TextStyle(fontSize: 16)),
          for (final r in top)
            pw.Text('${r['name_fr']} — ${r['qty_sold']} unités'),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static Future<File?> exportDailyExcel(
    Map<String, dynamic> daily,
    List<Map<String, dynamic>> top,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Ventes'];
    sheet.appendRow([TextCellValue('Indicateur'), TextCellValue('Valeur')]);
    sheet.appendRow([TextCellValue('Recettes'), TextCellValue('${daily['revenue']}')]);
    sheet.appendRow([
      TextCellValue('Transactions'),
      TextCellValue('${daily['transactions']}'),
    ]);

    final topSheet = excel['Top produits'];
    topSheet.appendRow([TextCellValue('Produit'), TextCellValue('Quantité')]);
    for (final r in top) {
      topSheet.appendRow([
        TextCellValue('${r['name_fr']}'),
        TextCellValue('${r['qty_sold']}'),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/rapport_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    return file;
  }
}
