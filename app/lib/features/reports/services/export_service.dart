import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/services/pdf_presentation_service.dart';
import 'package:souma_parfumerie/features/reports/services/pdf_export_result.dart';
import 'package:souma_parfumerie/features/reports/services/report_pdf_builder.dart';

class ExportService {
  static Future<Uint8List> buildReportPdfBytes({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> top,
    required DateTime from,
    required DateTime to,
    List<Map<String, dynamic>>? dailyRevenue,
    List<Map<String, dynamic>>? monthlyRevenue,
    Map<String, dynamic>? returnStats,
    String locale = 'fr',
  }) =>
      ReportPdfBuilder.buildSynthesisPdf(
        store: store,
        summary: summary,
        top: top,
        from: from,
        to: to,
        dailyRevenue: dailyRevenue,
        monthlyRevenue: monthlyRevenue,
        returnStats: returnStats,
        locale: locale,
      );

  static Future<Uint8List> buildSalesReportPdfBytes({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required double profit,
    required Map<String, dynamic> expenses,
    required List<Map<String, dynamic>> cashiers,
    required DateTime from,
    required DateTime to,
    List<Map<String, dynamic>>? dailyRevenue,
    List<Map<String, dynamic>>? payments,
    String locale = 'fr',
  }) =>
      ReportPdfBuilder.buildSalesPdf(
        store: store,
        summary: summary,
        profit: profit,
        expenses: expenses,
        cashiers: cashiers,
        from: from,
        to: to,
        dailyRevenue: dailyRevenue,
        payments: payments,
        locale: locale,
      );

  static Future<Uint8List> buildProductsReportPdfBytes({
    required StoreSettings store,
    required List<Map<String, dynamic>> top,
    required List<Map<String, dynamic>> byCategory,
    required DateTime from,
    required DateTime to,
    String locale = 'fr',
  }) =>
      ReportPdfBuilder.buildProductsPdf(
        store: store,
        top: top,
        byCategory: byCategory,
        from: from,
        to: to,
        locale: locale,
      );

  static Future<PdfExportResult> exportPeriodPdf({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> top,
    required DateTime from,
    required DateTime to,
    List<Map<String, dynamic>>? dailyRevenue,
    List<Map<String, dynamic>>? monthlyRevenue,
    Map<String, dynamic>? returnStats,
    String locale = 'fr',
  }) async {
    try {
      final bytes = await buildReportPdfBytes(
        store: store,
        summary: summary,
        top: top,
        from: from,
        to: to,
        dailyRevenue: dailyRevenue,
        monthlyRevenue: monthlyRevenue,
        returnStats: returnStats,
        locale: locale,
      );
      final name =
          'rapport_synthese_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}';
      final result =
          await PdfPresentationService.present(bytes: bytes, filename: name);
      if (result.saved && result.file != null) {
        return PdfExportResult(path: result.file!.path);
      }
      return PdfExportResult(error: result.error ?? 'Enregistrement impossible');
    } catch (e) {
      return PdfExportResult(error: e);
    }
  }

  static Future<PdfExportResult> exportSalesPdf({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required double profit,
    required Map<String, dynamic> expenses,
    required List<Map<String, dynamic>> cashiers,
    required DateTime from,
    required DateTime to,
    List<Map<String, dynamic>>? dailyRevenue,
    List<Map<String, dynamic>>? payments,
    String locale = 'fr',
  }) async {
    try {
    final bytes = await buildSalesReportPdfBytes(
      store: store,
      summary: summary,
      profit: profit,
      expenses: expenses,
      cashiers: cashiers,
      from: from,
      to: to,
      dailyRevenue: dailyRevenue,
      payments: payments,
      locale: locale,
    );
    final name =
        'rapport_ventes_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}';
      final result =
          await PdfPresentationService.present(bytes: bytes, filename: name);
      if (result.saved && result.file != null) {
        return PdfExportResult(path: result.file!.path);
      }
      return PdfExportResult(error: result.error);
    } catch (e) {
      return PdfExportResult(error: e);
    }
  }

  static Future<PdfExportResult> exportAnnualPeriodPdf({
    required StoreSettings store,
    required int year,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> monthly,
    required Map<String, dynamic> yoy,
    required List<Map<String, dynamic>> payments,
    required List<Map<String, dynamic>> top,
    required double profit,
    required Map<String, dynamic> expenses,
    String locale = 'fr',
  }) async {
    final bytes = await ReportPdfBuilder.buildAnnualDetailedPdf(
      store: store,
      year: year,
      summary: summary,
      monthly: monthly,
      yoy: yoy,
      payments: payments,
      top: top,
      profit: profit,
      expenses: expenses,
      locale: locale,
    );
    final name = 'rapport_annuel_$year';
    try {
      final result =
          await PdfPresentationService.present(bytes: bytes, filename: name);
      if (result.saved && result.file != null) {
        return PdfExportResult(path: result.file!.path);
      }
      return PdfExportResult(error: result.error);
    } catch (e) {
      return PdfExportResult(error: e);
    }
  }

  static Future<PdfExportResult> exportProductsPdf({
    required StoreSettings store,
    required List<Map<String, dynamic>> top,
    required List<Map<String, dynamic>> byCategory,
    required DateTime from,
    required DateTime to,
    String locale = 'fr',
  }) async {
    final bytes = await buildProductsReportPdfBytes(
      store: store,
      top: top,
      byCategory: byCategory,
      from: from,
      to: to,
      locale: locale,
    );
    final name =
        'rapport_produits_${DateFormat('yyyyMMdd').format(from)}_${DateFormat('yyyyMMdd').format(to)}';
    try {
      final result =
          await PdfPresentationService.present(bytes: bytes, filename: name);
      if (result.saved && result.file != null) {
        return PdfExportResult(path: result.file!.path);
      }
      return PdfExportResult(error: result.error);
    } catch (e) {
      return PdfExportResult(error: e);
    }
  }

  static Future<File?> exportPeriodExcel({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> top,
    required DateTime from,
    required DateTime to,
  }) async {
    final periodFmt = DateFormat('dd/MM/yyyy');
    final excel = Excel.createExcel();
    final sheet = excel['Synthèse'];
    _appendStoreHeader(sheet, store, from, to, periodFmt);
    sheet.appendRow([TextCellValue('Indicateur'), TextCellValue('Valeur')]);
    sheet.appendRow([
      TextCellValue('Recettes'),
      TextCellValue('${summary['revenue']} ${store.currencySymbol}'),
    ]);
    sheet.appendRow([
      TextCellValue('Transactions'),
      TextCellValue('${summary['transactions']}'),
    ]);
    _appendTopSheet(excel, top);
    return _saveExcel(excel, 'rapport_synthese');
  }

  static Future<File?> exportSalesExcel({
    required StoreSettings store,
    required Map<String, dynamic> summary,
    required double profit,
    required Map<String, dynamic> expenses,
    required List<Map<String, dynamic>> cashiers,
    required DateTime from,
    required DateTime to,
  }) async {
    final periodFmt = DateFormat('dd/MM/yyyy');
    final excel = Excel.createExcel();
    final sheet = excel['Ventes'];
    _appendStoreHeader(sheet, store, from, to, periodFmt);
    sheet.appendRow([
      TextCellValue('Transactions'),
      TextCellValue('${summary['transactions']}'),
    ]);
    sheet.appendRow([
      TextCellValue('Recettes'),
      TextCellValue('${summary['revenue']} ${store.currencySymbol}'),
    ]);
    sheet.appendRow([
      TextCellValue('Bénéfice estimé'),
      TextCellValue('$profit ${store.currencySymbol}'),
    ]);
    sheet.appendRow([
      TextCellValue('Dépenses'),
      TextCellValue('${expenses['total']} ${store.currencySymbol}'),
    ]);
    final cashierSheet = excel['Caissiers'];
    cashierSheet.appendRow([
      TextCellValue('Caissier'),
      TextCellValue('Ventes'),
      TextCellValue('CA'),
    ]);
    for (final c in cashiers) {
      cashierSheet.appendRow([
        TextCellValue('${c['cashier_name']}'),
        TextCellValue('${c['transactions']}'),
        TextCellValue('${c['revenue']}'),
      ]);
    }
    return _saveExcel(excel, 'rapport_ventes');
  }

  static Future<File?> exportProductsExcel({
    required StoreSettings store,
    required List<Map<String, dynamic>> top,
    required List<Map<String, dynamic>> byCategory,
    required DateTime from,
    required DateTime to,
  }) async {
    final periodFmt = DateFormat('dd/MM/yyyy');
    final excel = Excel.createExcel();
    final sheet = excel['Produits'];
    _appendStoreHeader(sheet, store, from, to, periodFmt);
    _appendTopSheet(excel, top);
    if (byCategory.isNotEmpty) {
      final catSheet = excel['Catégories'];
      catSheet.appendRow([
        TextCellValue('Catégorie'),
        TextCellValue('CA'),
      ]);
      for (final r in byCategory) {
        catSheet.appendRow([
          TextCellValue('${r['category_name_fr'] ?? r['name_fr']}'),
          TextCellValue('${r['revenue']}'),
        ]);
      }
    }
    return _saveExcel(excel, 'rapport_produits');
  }

  static void _appendStoreHeader(
    Sheet sheet,
    StoreSettings store,
    DateTime from,
    DateTime to,
    DateFormat periodFmt,
  ) {
    sheet.appendRow([TextCellValue(store.nameFr)]);
    if (store.address.isNotEmpty) {
      sheet.appendRow([TextCellValue(store.address)]);
    }
    sheet.appendRow([
      TextCellValue('Période'),
      TextCellValue('${periodFmt.format(from)} - ${periodFmt.format(to)}'),
    ]);
  }

  static void _appendTopSheet(Excel excel, List<Map<String, dynamic>> top) {
    final topSheet = excel['Top produits'];
    topSheet.appendRow([
      TextCellValue('Produit'),
      TextCellValue('Qté'),
      TextCellValue('CA'),
    ]);
    for (final r in top) {
      topSheet.appendRow([
        TextCellValue('${r['name_fr']}'),
        TextCellValue('${r['qty_sold']}'),
        TextCellValue('${r['revenue']}'),
      ]);
    }
  }

  static Future<File?> _saveExcel(Excel excel, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    return file;
  }
}
