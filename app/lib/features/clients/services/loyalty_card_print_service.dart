import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/services/pdf_presentation_service.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';

/// Impression / export PDF de la carte de fidélité client.
class LoyaltyCardPrintService {
  static const _stampSize = 44.0;
  static const _perRow = 5;

  static Future<({bool ok, String? path})> printCard({
    required Map<String, dynamic> client,
    required int loyaltyPoints,
    required StoreSettings store,
    String locale = 'fr',
  }) async {
    final bytes = await buildPdfBytes(
      client: client,
      loyaltyPoints: loyaltyPoints,
      store: store,
      locale: locale,
    );
    final phone = client['phone']?.toString() ?? 'client';
    final safePhone = phone.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final result = await PdfPresentationService.present(
      bytes: bytes,
      filename: 'carte_fidelite_$safePhone',
    );
    return (ok: result.saved, path: result.file?.path);
  }

  static Future<Uint8List> buildPdfBytes({
    required Map<String, dynamic> client,
    required int loyaltyPoints,
    required StoreSettings store,
    String locale = 'fr',
  }) async {
    final doc = await _buildDocument(
      client: client,
      loyaltyPoints: loyaltyPoints,
      store: store,
      locale: locale,
    );
    return Uint8List.fromList(await doc.save());
  }

  static Future<pw.Document> _buildDocument({
    required Map<String, dynamic> client,
    required int loyaltyPoints,
    required StoreSettings store,
    required String locale,
  }) async {
    final isAr = locale.startsWith('ar');
    final threshold = LoyaltyConfig.giftThreshold;
    final filled = loyaltyPoints.clamp(0, threshold);
    final phone = client['phone']?.toString() ?? '';
    final name = client['name']?.toString() ?? '';
    final logo = await _loadLogo();

    pw.Widget stampCell(int index) {
      final checked = index < filled;
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: _stampSize,
            height: _stampSize,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: checked ? PdfColors.amber800 : PdfColors.grey400,
                width: checked ? 2 : 1,
              ),
            ),
            child: checked && logo != null
                ? pw.ClipOval(
                    child: pw.Image(logo, fit: pw.BoxFit.cover),
                  )
                : null,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${index + 1}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      );
    }

    pw.Widget stampRow(int rowIndex) {
      final start = rowIndex * _perRow;
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < _perRow; i++) stampCell(start + i),
        ],
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 64,
                    height: 64,
                    margin: const pw.EdgeInsets.only(right: 16),
                    child: pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover)),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        store.displayName(locale),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (store.phone.isNotEmpty)
                        pw.Text(store.phone, style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        isAr ? 'بطاقة الولاء' : 'Carte de fidélité',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber800,
                        ),
                      ),
                      pw.Text(
                        isAr
                            ? '10 مشتريات = هدية'
                            : '10 achats = 1 cadeau',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Text(
              phone,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (name.isNotEmpty)
              pw.Text(name, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 16),
            stampRow(0),
            pw.SizedBox(height: 14),
            stampRow(1),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                isAr
                    ? '$filled / $threshold عمليات'
                    : '$filled / $threshold validations',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (filled >= threshold)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(
                    isAr ? 'هدية مستحقة' : 'Cadeau à offrir',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return doc;
  }

  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load(AppLogo.assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
