import 'package:pdf/widgets.dart' as pw;
import 'package:souma_parfumerie/core/models/store_settings.dart';

/// En-tête boutique pour PDF (factures, rapports).
class StoreDocumentHelper {
  StoreDocumentHelper._();

  static List<pw.Widget> pdfHeader(
    StoreSettings store, {
    required String locale,
    bool bilingual = false,
  }) {
    final isAr = locale.startsWith('ar');
    final name = bilingual
        ? '${store.nameFr}\n${store.nameAr}'
        : store.displayName(locale);
    final slogan = bilingual
        ? [
            if (store.sloganFr.isNotEmpty) store.sloganFr,
            if (store.sloganAr.isNotEmpty) store.sloganAr,
          ].join('\n')
        : store.displaySlogan(locale);

    final lines = <pw.Widget>[
      pw.Text(
        name,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    ];

    if (slogan != null && slogan.isNotEmpty) {
      lines.add(pw.SizedBox(height: 4));
      lines.add(
        pw.Text(slogan, style: const pw.TextStyle(fontSize: 10)),
      );
    }

    final contact = <String>[
      if (store.address.isNotEmpty) store.address,
      if (store.phone.isNotEmpty)
        '${isAr ? 'هاتف' : 'Tél.'} : ${store.phone}',
      if (store.email.isNotEmpty) store.email,
    ];
    if (contact.isNotEmpty) {
      lines.add(pw.SizedBox(height: 6));
      for (final c in contact) {
        lines.add(pw.Text(c, style: const pw.TextStyle(fontSize: 9)));
      }
    }

    if (store.openingHours.isNotEmpty) {
      lines.add(pw.SizedBox(height: 4));
      lines.add(
        pw.Text(
          '${isAr ? 'ساعات العمل' : 'Horaires'} : ${store.openingHours}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      );
    }

    if (store.legalInfo.isNotEmpty) {
      lines.add(pw.SizedBox(height: 6));
      lines.add(
        pw.Text(
          store.legalInfo,
          style: const pw.TextStyle(fontSize: 7),
        ),
      );
    }

    lines.add(pw.SizedBox(height: 12));
    lines.add(pw.Divider());
    lines.add(pw.SizedBox(height: 8));
    return lines;
  }

  static List<String> receiptLines(StoreSettings store, String lang) {
    final isAr = lang == 'ar';
    final bilingual = lang == 'bilingual';
    final lines = <String>[];

    void add(String s) {
      if (s.isNotEmpty) lines.add(s);
    }

    if (store.address.isNotEmpty) add(store.address);
    if (store.phone.isNotEmpty) {
      add(bilingual || isAr ? 'هاتف: ${store.phone}' : 'Tél: ${store.phone}');
    }
    if (store.email.isNotEmpty) add(store.email);

    final slogan = bilingual
        ? [
            if (store.sloganFr.isNotEmpty) store.sloganFr,
            if (store.sloganAr.isNotEmpty) store.sloganAr,
          ].join('\n')
        : (isAr ? store.sloganAr : store.sloganFr);
    if (slogan.isNotEmpty) add(slogan);

    return lines;
  }
}
