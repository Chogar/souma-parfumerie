import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/core/utils/loyalty_document_helper.dart';
import 'package:souma_parfumerie/core/utils/store_document_helper.dart';
import 'package:souma_parfumerie/core/services/pdf_presentation_service.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';
import 'package:souma_parfumerie/features/pos/services/receipt_print_service.dart';
import 'package:souma_parfumerie/features/sales/data/sales_repository.dart';

/// Réimpression thermique et facture PDF A4.
class InvoiceService {
  static final _repo = SalesRepository();
  static final _fmt = NumberFormat('#,##0', 'fr_FR');
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  static Future<SaleReceipt?> loadReceipt(
    String saleId, {
    String? onlyUserId,
  }) =>
      _repo.buildReceipt(saleId, onlyUserId: onlyUserId);

  /// Ouvre le ticket (partage / impression) sans bloquer l'interface.
  static Future<bool> reprintReceipt(
    String saleId, {
    String? language,
    String? onlyUserId,
  }) async {
    final receipt = await loadReceipt(saleId, onlyUserId: onlyUserId);
    if (receipt == null) return false;

    return ReceiptPrintService.presentReceipt(
      receipt,
      language: language,
    );
  }

  static Future<Uint8List> buildInvoicePdfBytes(
    SaleReceipt receipt, {
    required String locale,
  }) async {
    final doc = await _buildDocument(receipt, locale);
    return Uint8List.fromList(await doc.save());
  }

  static Future<({bool ok, String? path})> exportInvoicePdf(
    String saleId, {
    required String locale,
    String? onlyUserId,
  }) async {
    final receipt = await loadReceipt(saleId, onlyUserId: onlyUserId);
    if (receipt == null) return (ok: false, path: null);

    final bytes = await buildInvoicePdfBytes(receipt, locale: locale);
    final result = await PdfPresentationService.present(
      bytes: bytes,
      filename: 'facture_${receipt.invoiceNumber}',
    );
    return (ok: result.saved, path: result.file?.path);
  }

  static Future<pw.ImageProvider?> _loadLogoImage() async {
    try {
      final data = await rootBundle.load(AppLogo.assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Document> _buildDocument(
    SaleReceipt receipt,
    String locale,
  ) async {
    final isAr = locale.startsWith('ar');
    final doc = pw.Document();
    final logo = await _loadLogoImage();
    final loyaltyWidgets = receipt.loyaltyStamps != null
        ? await LoyaltyDocumentHelper.buildLoyaltySection(
            stamps: receipt.loyaltyStamps!,
            threshold: receipt.loyaltyThreshold,
            locale: locale,
          )
        : <pw.Widget>[];

    pw.Widget row(String left, String right, {bool bold = false}) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text(left)),
            pw.Text(
              right,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null)
                pw.Container(
                  width: 72,
                  height: 72,
                  margin: const pw.EdgeInsets.only(right: 16),
                  child: pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover)),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    ...StoreDocumentHelper.pdfHeader(
                      receipt.store,
                      locale: locale,
                    ),
                    pw.Text(
                      isAr ? 'فاتورة' : 'Facture',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    receipt.invoiceNumber,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(_dateFmt.format(receipt.soldAt)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          if (receipt.cashierName != null)
            pw.Text(
              isAr
                  ? 'أمين الصندوق: ${receipt.cashierName}'
                  : 'Caissier : ${receipt.cashierName}',
            ),
          if (receipt.clientPhone != null)
            pw.Text(
              isAr
                  ? 'الهاتف: ${receipt.clientPhone}'
                  : 'Client : ${receipt.clientPhone}',
            ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              isAr ? 'المنتج' : 'Produit',
              isAr ? 'الكمية' : 'Qté',
              isAr ? 'Prix unit.' : 'P.U.',
              isAr ? 'المجموع' : 'Total',
            ],
            data: [
              for (final l in receipt.lines)
                [
                  isAr ? l.product.nameAr : l.product.nameFr,
                  '${l.quantity}',
                  _fmt.format(l.product.salePrice),
                  '${_fmt.format(l.lineTotal)} ${receipt.currencySymbol}',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 16),
          if (receipt.discountAmount > 0)
            row(
              isAr ? 'خصم' : 'Remise',
              '-${_fmt.format(receipt.discountAmount)} ${receipt.currencySymbol}',
            ),
          row(
            isAr ? 'الإجمالي' : 'TOTAL',
            '${_fmt.format(receipt.total)} ${receipt.currencySymbol}',
            bold: true,
          ),
          ...loyaltyWidgets,
        ],
      ),
    );

    return doc;
  }
}
