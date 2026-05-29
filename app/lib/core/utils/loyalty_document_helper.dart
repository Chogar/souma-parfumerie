import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';

/// Rendu PDF du programme fidélité (grille 2×5 + logos), ticket et facture.
class LoyaltyDocumentHelper {
  LoyaltyDocumentHelper._();

  static const _perRow = 5;
  static const _cardBg = PdfColor.fromInt(0xFFF8F4E8);
  static const _borderGold = PdfColor.fromInt(0xFFC9A227);

  static pw.ImageProvider? _logoCache;

  static Future<pw.ImageProvider?> loadLogo() async {
    if (_logoCache != null) return _logoCache;
    try {
      final data = await rootBundle.load(AppLogo.assetPath);
      _logoCache = pw.MemoryImage(data.buffer.asUint8List());
      return _logoCache;
    } catch (_) {
      return null;
    }
  }

  /// Bloc fidélité complet pour ticket thermique ou facture A4.
  static Future<List<pw.Widget>> buildLoyaltySection({
    required int stamps,
    required int threshold,
    required String locale,
    bool compact = false,
  }) async {
    final logo = await loadLogo();
    final filled = stamps.clamp(0, threshold);
    final isAr = locale.startsWith('ar');
    final stampSize = compact ? 22.0 : 36.0;
    final remaining = (threshold - filled).clamp(0, threshold);

    pw.Widget stampCell(int index) {
      final checked = index < filled;
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: stampSize,
            height: stampSize,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: checked ? null : PdfColors.white,
              border: pw.Border.all(
                color: checked ? _borderGold : PdfColors.grey400,
                width: checked ? 1.5 : 1,
              ),
            ),
            child: checked && logo != null
                ? pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover))
                : null,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${index + 1}',
            style: pw.TextStyle(
              fontSize: compact ? 6 : 8,
              color: PdfColors.grey700,
            ),
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

    final titleFr = 'Programme fidélité';
    final titleAr = 'برنامج الولاء';
    final progressFr = '$filled/$threshold validations';
    final progressAr = '$filled/$threshold عمليات';
    final untilFr =
        'Encore $remaining validation(s) avant le cadeau';
    final untilAr = 'باقي $remaining عملية(ات) قبل الهدية';
    final giftFr = 'Cadeau à offrir';
    final giftAr = 'هدية مستحقة';

    return [
      pw.SizedBox(height: compact ? 6 : 10),
      pw.Container(
        padding: pw.EdgeInsets.all(compact ? 8 : 12),
        decoration: pw.BoxDecoration(
          color: _cardBg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _borderGold, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isAr ? titleAr : titleFr,
                  style: pw.TextStyle(
                    fontSize: compact ? 8 : 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  isAr ? progressAr : progressFr,
                  style: pw.TextStyle(
                    fontSize: compact ? 8 : 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: compact ? 6 : 10),
            stampRow(0),
            pw.SizedBox(height: compact ? 4 : 8),
            stampRow(1),
            pw.SizedBox(height: compact ? 4 : 6),
            pw.Center(
              child: pw.Text(
                filled >= threshold
                    ? (isAr ? giftAr : giftFr)
                    : (isAr ? untilAr : untilFr),
                style: pw.TextStyle(
                  fontSize: compact ? 7 : 9,
                  fontWeight: filled >= threshold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: filled >= threshold
                      ? PdfColors.amber800
                      : PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static int get defaultThreshold => LoyaltyConfig.giftThreshold;
}
