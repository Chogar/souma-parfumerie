import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:souma_parfumerie/core/utils/loyalty_document_helper.dart';
import 'package:souma_parfumerie/core/utils/store_document_helper.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';

/// Impression reçu thermique 80 mm (PDF → imprimante par défaut).
class ReceiptPrintService {
  static final _fmt = NumberFormat('#,##0', 'fr_FR');
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  static const _rollFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    297 * PdfPageFormat.mm,
    marginAll: 4 * PdfPageFormat.mm,
  );

  static Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_print') ?? false;
  }

  static Future<String> printLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('print_language') ?? 'fr';
  }

  static Future<void> setAutoPrint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_print', value);
  }

  static Future<void> setPrintLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('print_language', lang);
  }

  /// `fr`, `ar` ou `bilingual`
  static Future<void> printReceipt(
    SaleReceipt receipt, {
    String? language,
    bool force = false,
  }) async {
    if (!force && !await isAutoPrintEnabled()) return;

    try {
      await _printReceiptImpl(receipt, language).timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Ne pas bloquer la caisse si l'impression échoue.
    }
  }

  /// Réimpression manuelle : feuille de partage sur bureau (évite le blocage macOS).
  static Future<bool> presentReceipt(
    SaleReceipt receipt, {
    String? language,
  }) async {
    try {
      final lang = language ?? await printLanguage();
      final bytes = Uint8List.fromList(await _buildPdfBytes(receipt, lang));
      final name = 'ticket_${receipt.invoiceNumber}.pdf';

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        await Printing.sharePdf(bytes: bytes, filename: name).timeout(
          const Duration(seconds: 45),
        );
        return true;
      }

      return await _directPrint(bytes);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _printReceiptImpl(
    SaleReceipt receipt,
    String? language,
  ) async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // Évite listPrinters / directPrintPdf qui bloquent souvent sur macOS.
      return;
    }

    final lang = language ?? await printLanguage();
    final bytes = Uint8List.fromList(await _buildPdfBytes(receipt, lang));
    await _directPrint(bytes);
  }

  static Future<bool> _directPrint(Uint8List bytes) async {
    final printers = await Printing.listPrinters().timeout(
      const Duration(seconds: 3),
      onTimeout: () => <Printer>[],
    );
    if (printers.isEmpty) return false;

    var printer = printers.first;
    for (final p in printers) {
      if (p.isDefault) {
        printer = p;
        break;
      }
    }

    await (() async {
      final job = Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => bytes,
        format: _rollFormat,
      );
      if (job is Future) await job;
    })().timeout(const Duration(seconds: 15));
    return true;
  }

  static Future<List<int>> _buildPdfBytes(SaleReceipt r, String lang) async {
    final doc = await _buildPdf(r, lang);
    return doc.save();
  }

  static Future<pw.Document> _buildPdf(SaleReceipt r, String lang) async {
    final doc = pw.Document();
    final isAr = lang == 'ar';
    final bilingual = lang == 'bilingual';
    final loyaltyWidgets = r.loyaltyStamps != null
        ? await LoyaltyDocumentHelper.buildLoyaltySection(
            stamps: r.loyaltyStamps!,
            threshold: r.loyaltyThreshold,
            locale: lang,
            compact: true,
          )
        : <pw.Widget>[];

    String t(String fr, String ar) {
      if (bilingual) return '$fr\n$ar';
      return isAr ? ar : fr;
    }

    pw.Widget row(String left, String right) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(left, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Text(right, style: const pw.TextStyle(fontSize: 9)),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: _rollFormat,
        build: (ctx) => [
          pw.Center(
            child: pw.Text(
              bilingual
                  ? '${r.storeNameFr}\n${r.storeNameAr}'
                  : (isAr ? r.storeNameAr : r.storeNameFr),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 4),
          for (final line in StoreDocumentHelper.receiptLines(r.store, lang))
            pw.Center(
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          if (StoreDocumentHelper.receiptLines(r.store, lang).isNotEmpty)
            pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              t('Ticket de caisse', 'تذكرة الصندوق'),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Divider(),
          pw.Text('${t('N°', 'رقم')}: ${r.invoiceNumber}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text(_dateFmt.format(r.soldAt),
              style: const pw.TextStyle(fontSize: 8)),
          if (r.cashierName != null)
            pw.Text(
              '${t('Caissier', 'أمين الصندوق')}: ${r.cashierName}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          pw.Divider(),
          for (final l in r.lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: row(
                '${l.quantity}x ${isAr ? l.product.nameAr : l.product.nameFr}',
                _fmt.format(l.lineTotal),
              ),
            ),
          pw.Divider(),
          row(
            t('Sous-total', 'المجموع'),
            '${_fmt.format(r.subtotal)} ${r.currencySymbol}',
          ),
          if (r.discountAmount > 0)
            row(
              t('Remise', 'خصم'),
              '-${_fmt.format(r.discountAmount)}',
            ),
          row(
            t('TOTAL', 'الإجمالي'),
            '${_fmt.format(r.total)} ${r.currencySymbol}',
          ),
          row(
            t('Paiement', 'الدفع'),
            _paymentLabel(r.paymentMethod, isAr, bilingual),
          ),
          if (r.paymentMethod == 'cash') ...[
            row(
              t('Reçu', 'المستلم'),
              '${_fmt.format(r.amountPaid)} ${r.currencySymbol}',
            ),
            row(
              t('Monnaie', 'الباقي'),
              '${_fmt.format(r.changeGiven)} ${r.currencySymbol}',
            ),
          ],
          if (r.clientPhone != null && r.clientPhone!.isNotEmpty) ...[
            pw.Divider(),
            pw.Text(
              '${t('Client', 'العميل')}: ${r.clientPhone}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
          ...loyaltyWidgets,
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              t('Merci de votre visite !', 'شكراً لزيارتكم !'),
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static String _paymentLabel(String method, bool isAr, bool bilingual) {
    const map = <String, (String, String)>{
      'cash': ('Espèces', 'نقداً'),
      'card': ('Carte', 'بطاقة'),
      'mobile': ('Mobile', 'محفظة'),
      'mixed': ('Mixte', 'مختلط'),
    };
    final labels = map[method];
    if (labels == null) return '';
    if (bilingual) return '${labels.$1} / ${labels.$2}';
    return isAr ? labels.$2 : labels.$1;
  }
}
