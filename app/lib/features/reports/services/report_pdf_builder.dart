import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/utils/intl_locale_init.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/features/reports/services/report_pdf_charts.dart';

/// Mise en page premium des rapports PDF (couleurs boutique, tableaux, KPI).
class ReportPdfBuilder {
  ReportPdfBuilder._();

  static final _fmt = NumberFormat('#,##0');
  static final _periodFmt = DateFormat('dd/MM/yyyy');
  static final _generatedFmt = DateFormat('dd/MM/yyyy à HH:mm');

  static const _primary = PdfColor.fromInt(0xFF1A1A2E);
  static const _accent = PdfColor.fromInt(0xFFC9A227);
  static const _accentSoft = PdfColor.fromInt(0xFFF5EDD6);
  static const _surface = PdfColor.fromInt(0xFFF8F6F1);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE0E0E0);
  static const _white = PdfColors.white;

  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load(AppLogo.assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> buildDocument({
    required StoreSettings store,
    required String reportTitle,
    required String reportSubtitle,
    required DateTime from,
    required DateTime to,
    required List<pw.Widget> body,
    String locale = 'fr',
  }) async {
    await IntlLocaleInit.ensureFrench();
    final logo = await _loadLogo();
    final isAr = locale.startsWith('ar');
    final generated = _generatedFmt.format(DateTime.now());

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 52),
        footer: (ctx) => _pageFooter(
          ctx: ctx,
          generated: generated,
          isAr: isAr,
        ),
        build: (ctx) => [
          _heroHeader(
            store: store,
            logo: logo,
            title: reportTitle,
            subtitle: reportSubtitle,
            from: from,
            to: to,
            isAr: isAr,
          ),
          pw.SizedBox(height: 22),
          ...body,
          pw.SizedBox(height: 16),
          _experienceTechFooter(isAr: isAr),
        ],
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  static pw.Widget _heroHeader({
    required StoreSettings store,
    required pw.ImageProvider? logo,
    required String title,
    required String subtitle,
    required DateTime from,
    required DateTime to,
    required bool isAr,
  }) {
    final period =
        '${_periodFmt.format(from)} - ${_periodFmt.format(to)}';
    final storeName = store.displayName(isAr ? 'ar' : 'fr');

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              width: 64,
              height: 64,
              margin: pw.EdgeInsets.only(right: isAr ? 0 : 16, left: isAr ? 16 : 0),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: _accent, width: 2),
              ),
              child: pw.ClipOval(
                child: pw.Image(logo, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (store.address.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    store.address,
                    style: const pw.TextStyle(color: _accent, fontSize: 9),
                  ),
                ],
                if (store.phone.isNotEmpty)
                  pw.Text(
                    '${isAr ? 'هاتف' : 'Tél.'} ${store.phone}',
                    style: const pw.TextStyle(color: PdfColor.fromInt(0xFFB8B8C8), fontSize: 9),
                  ),
              ],
            ),
          ),
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF252542),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _accent, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(color: _white, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: _accent,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  period,
                  style: const pw.TextStyle(color: _white, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget sectionTitle(String title, {String? subtitle, bool isAr = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(width: 4, height: 18, color: _accent),
            pw.SizedBox(width: 10),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 14),
            child: pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        ],
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget kpiGrid(List<({String label, String value, bool highlight})> items) {
    final children = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      children.add(
        pw.Expanded(
          child: pw.Container(
            margin: pw.EdgeInsets.only(
              right: i < items.length - 1 ? 10 : 0,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: pw.BoxDecoration(
              color: item.highlight ? _accentSoft : _surface,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: item.highlight ? _accent : _border,
                width: item.highlight ? 1.2 : 0.5,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.label.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  item.value,
                  style: pw.TextStyle(
                    fontSize: item.highlight ? 16 : 14,
                    fontWeight: pw.FontWeight.bold,
                    color: item.highlight ? _primary : PdfColor.fromInt(0xFF2D2D44),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return pw.Row(children: children);
  }

  static pw.Widget dataTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<double>? columnWidths,
    bool rankColumn = false,
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _surface,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          '-',
          style: const pw.TextStyle(color: _muted, fontSize: 10),
        ),
      );
    }

    final widths = <int, pw.TableColumnWidth>{};
    if (columnWidths != null) {
      for (var i = 0; i < columnWidths.length; i++) {
        widths[i] = pw.FlexColumnWidth(columnWidths[i]);
      }
    }

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primary),
        children: headers
            .map(
              (h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: pw.Text(
                  h.toUpperCase(),
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      ...rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? _white : _surface,
          ),
          children: row.asMap().entries.map((cell) {
            final col = cell.key;
            final text = cell.value;
            final isRank = rankColumn && col == 0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: isRank && i < 3 ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isRank && i < 3 ? _accent : PdfColor.fromInt(0xFF1A1A2E),
                ),
              ),
            );
          }).toList(),
        );
      }),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Table(
          columnWidths: widths.isEmpty ? null : widths,
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _border, width: 0.3),
          ),
          children: tableRows,
        ),
      ),
    );
  }

  static pw.Widget metricRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget summaryPanel({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 2, width: 40, color: _accent),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _pageFooter({
    required pw.Context ctx,
    required String generated,
    required bool isAr,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isAr ? 'تم الإنشاء: $generated' : 'Généré le $generated',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            isAr
                ? 'صفحة ${ctx.pageNumber} / ${ctx.pagesCount}'
                : 'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _experienceTechFooter({required bool isAr}) {
    return pw.Center(
      child: pw.Text(
        isAr ? '© Expérience Tech' : 'Document généré par Souma Parfumerie - © Expérience Tech',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  static String money(double value, String symbol) =>
      '${_fmt.format(value)} $symbol';

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  // ——— Rapports typés ———

  static String _cellText(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return '-';
    return s;
  }

  static Future<Uint8List> buildSynthesisPdf({
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
    await IntlLocaleInit.ensureFrench();
    final isAr = locale.startsWith('ar');
    final sym = store.currencySymbol;
    final revenue = _asDouble(summary['revenue']);
    final tx = summary['transactions']?.toString() ?? '0';
    final avg = _asDouble(summary['avg_basket']);

    final rs = returnStats;
    final hasReturns = rs != null &&
        (_asDouble(rs['requested']) > 0 ||
            _asDouble(rs['approved']) > 0 ||
            _asDouble(rs['rejected']) > 0 ||
            _asDouble(rs['pending']) > 0);

    return buildDocument(
      store: store,
      reportTitle: isAr ? 'تقرير ملخص' : 'Rapport synthèse',
      reportSubtitle: isAr ? 'مؤشرات الأداء' : 'Indicateurs de performance',
      from: from,
      to: to,
      locale: locale,
      body: [
        kpiGrid([
          (label: isAr ? 'الإيرادات' : 'Recettes', value: money(revenue, sym), highlight: true),
          (label: isAr ? 'المعاملات' : 'Transactions', value: tx, highlight: false),
          (label: isAr ? 'متوسط السلة' : 'Panier moyen', value: money(avg, sym), highlight: false),
        ]),
        if (hasReturns) ...[
          pw.SizedBox(height: 20),
          sectionTitle(
            isAr ? 'المرتجعات' : 'Retours (période)',
            isAr: isAr,
          ),
          pw.SizedBox(height: 8),
          kpiGrid([
            (
              label: isAr ? 'طلبات' : 'Demandes',
              value: '${_int(rs['requested'])}',
              highlight: false,
            ),
            (
              label: isAr ? 'قيد الانتظار' : 'En attente',
              value: '${_int(rs['pending'])}',
              highlight: false,
            ),
            (
              label: isAr ? 'مقبولة' : 'Validés',
              value: '${_int(rs['approved'])}',
              highlight: true,
            ),
          ]),
          pw.SizedBox(height: 8),
          dataTable(
            headers: isAr
                ? ['الحالة', 'العدد', 'المبلغ']
                : ['Statut', 'Nombre', 'Montant'],
            columnWidths: [2, 1, 1.5],
            rows: [
              [
                isAr ? 'مرفوضة' : 'Refusés',
                '${_int(rs['rejected'])}',
                '-',
              ],
              if (_asDouble(rs['approved_amount']) > 0)
                [
                  isAr ? 'مبلغ المرتجعات' : 'Montant retours validés',
                  '${_int(rs['approved'])}',
                  money(_asDouble(rs['approved_amount']), sym),
                ],
            ],
          ),
        ],
        if (dailyRevenue != null && dailyRevenue.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          ReportPdfCharts.chartBlock(
            title: isAr
                ? 'تطور الإيرادات اليومي'
                : 'Évolution journalière du CA',
            chart: ReportPdfCharts.dailyRevenueChart(dailyRevenue),
          ),
        ],
        if (monthlyRevenue != null && monthlyRevenue.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          ReportPdfCharts.chartBlock(
            title: isAr ? 'تطور شهري' : 'Histogramme mensuel (12 mois)',
            subtitle: isAr ? 'الإيرادات حسب الشهر' : 'Recettes par mois',
            chart: ReportPdfCharts.monthlyRevenueChart(monthlyRevenue),
          ),
        ],
        pw.SizedBox(height: 22),
        sectionTitle(
          isAr ? 'أفضل المنتجات' : 'Top produits',
          subtitle: isAr
              ? 'حسب الكمية والإيرادات'
              : 'Classés par quantité vendue et CA',
          isAr: isAr,
        ),
        dataTable(
          rankColumn: true,
          headers: isAr
              ? ['#', 'المنتج', 'الكمية', 'الإيرادات']
              : ['#', 'Produit', 'Qté vendue', 'CA'],
          columnWidths: [0.5, 3, 1, 1.5],
          rows: [
            for (var i = 0; i < top.length; i++)
              [
                '${i + 1}',
                _cellText(top[i]['name_fr']),
                '${top[i]['qty_sold']}',
                money(_asDouble(top[i]['revenue']), sym),
              ],
          ],
        ),
      ],
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static Future<Uint8List> buildSalesPdf({
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
    await IntlLocaleInit.ensureFrench();
    final isAr = locale.startsWith('ar');
    final sym = store.currencySymbol;
    final revenue = _asDouble(summary['revenue']);

    return buildDocument(
      store: store,
      reportTitle: isAr ? 'تقرير المبيعات' : 'Rapport ventes',
      reportSubtitle: isAr ? 'الإيرادات والمصروفات' : 'Recettes, dépenses et caissiers',
      from: from,
      to: to,
      locale: locale,
      body: [
        kpiGrid([
          (label: isAr ? 'الإيرادات' : 'Recettes', value: money(revenue, sym), highlight: true),
          (label: isAr ? 'الربح التقديري' : 'Bénéfice estimé', value: money(profit, sym), highlight: true),
          (label: isAr ? 'المعاملات' : 'Transactions', value: '${summary['transactions']}', highlight: false),
          (label: isAr ? 'المصروفات' : 'Dépenses', value: money(_asDouble(expenses['total']), sym), highlight: false),
        ]),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: summaryPanel(
                title: isAr ? 'ملخص مالي' : 'Synthèse financière',
                children: [
                  metricRow(
                    isAr ? 'إجمالي المبيعات' : 'Total des ventes',
                    money(revenue, sym),
                    bold: true,
                  ),
                  metricRow(
                    isAr ? 'المصروفات' : 'Dépenses période',
                    money(_asDouble(expenses['total']), sym),
                  ),
                  metricRow(
                    isAr ? 'الربح التقديري' : 'Bénéfice estimé',
                    money(profit, sym),
                    bold: true,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    isAr
                        ? '* الربح = الإيرادات − المصروفات (تقدير)'
                        : '* Bénéfice = recettes − dépenses (estimation)',
                    style: const pw.TextStyle(fontSize: 7, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (dailyRevenue != null && dailyRevenue.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          ReportPdfCharts.chartBlock(
            title: isAr ? 'تطور المبيعات' : 'Évolution des ventes',
            chart: ReportPdfCharts.dailyRevenueChart(dailyRevenue),
          ),
        ],
        pw.SizedBox(height: 22),
        sectionTitle(
          isAr ? 'المبيعات حسب الكاشير' : 'Ventes par caissier',
          isAr: isAr,
        ),
        if (cashiers.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          ReportPdfCharts.chartBlock(
            title: isAr ? 'رسم بياني' : 'Histogramme par caissier',
            chart: ReportPdfCharts.cashierRevenueChart(cashiers),
          ),
          pw.SizedBox(height: 12),
        ],
        dataTable(
          headers: isAr
              ? ['الكاشير', 'عدد المبيعات', 'الإيرادات']
              : ['Caissier', 'Nb ventes', 'Chiffre d\'affaires'],
          columnWidths: [2.5, 1, 1.5],
          rows: [
            for (final c in cashiers)
              [
                '${c['cashier_name']}',
                '${c['transactions']}',
                money(_asDouble(c['revenue']), sym),
              ],
          ],
        ),
        if (payments != null && payments.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          sectionTitle(
            isAr ? 'طرق الدفع' : 'Répartition des paiements',
            isAr: isAr,
          ),
          pw.SizedBox(height: 8),
          ReportPdfCharts.chartBlock(
            title: isAr ? 'رسم بياني' : 'Répartition visuelle',
            chart: ReportPdfCharts.paymentBreakdownChart(payments),
          ),
          pw.SizedBox(height: 12),
          dataTable(
            headers: isAr
                ? ['الطريقة', 'المعاملات', 'المبلغ']
                : ['Mode', 'Transactions', 'Montant'],
            columnWidths: [2, 1, 1.5],
            rows: [
              for (final p in payments)
                [
                  '${p['payment_method']}',
                  '${p['transactions']}',
                  money(_asDouble(p['total']), sym),
                ],
            ],
          ),
        ],
      ],
    );
  }

  static Future<Uint8List> buildProductsPdf({
    required StoreSettings store,
    required List<Map<String, dynamic>> top,
    required List<Map<String, dynamic>> byCategory,
    required DateTime from,
    required DateTime to,
    String locale = 'fr',
  }) {
    final isAr = locale.startsWith('ar');
    final sym = store.currencySymbol;
    final totalTop = top.fold<double>(
      0,
      (s, r) => s + _asDouble(r['revenue']),
    );

    final widgets = <pw.Widget>[
      if (top.isNotEmpty)
        kpiGrid([
          (
            label: isAr ? 'منتجات مدرجة' : 'Produits listés',
            value: '${top.length}',
            highlight: false,
          ),
          (
            label: isAr ? 'إيرادات Top' : 'CA Top produits',
            value: money(totalTop, sym),
            highlight: true,
          ),
        ]),
      pw.SizedBox(height: 22),
      sectionTitle(
        isAr ? 'أفضل المنتجات' : 'Top produits',
        subtitle: isAr ? 'الأكثر مبيعاً' : 'Les plus vendus sur la période',
        isAr: isAr,
      ),
      dataTable(
        rankColumn: true,
        headers: isAr
            ? ['#', 'المنتج', 'الكمية', 'الإيرادات']
            : ['#', 'Produit', 'Qté', 'Chiffre d\'affaires'],
        columnWidths: [0.5, 3, 1, 1.5],
        rows: [
          for (var i = 0; i < top.length; i++)
            [
              '${i + 1}',
              '${top[i]['name_fr']}',
              '${top[i]['qty_sold']}',
              money(_asDouble(top[i]['revenue']), sym),
            ],
        ],
      ),
    ];

    if (byCategory.isNotEmpty) {
      widgets.addAll([
        pw.SizedBox(height: 22),
        ReportPdfCharts.chartBlock(
          title: isAr ? 'مبيعات حسب الفئة' : 'Ventes par catégorie (diagramme)',
          chart: ReportPdfCharts.categoryPieChart(byCategory),
        ),
        pw.SizedBox(height: 16),
        sectionTitle(
          isAr ? 'حسب الفئة' : 'Répartition par catégorie',
          isAr: isAr,
        ),
        dataTable(
          headers: isAr
              ? ['الفئة', 'الإيرادات']
              : ['Catégorie', 'Chiffre d\'affaires'],
          columnWidths: [3, 1.5],
          rows: [
            for (final r in byCategory)
              [
                '${r['category_name_fr'] ?? r['name_fr']}',
                money(_asDouble(r['revenue']), sym),
              ],
          ],
        ),
      ]);
    }

    return buildDocument(
      store: store,
      reportTitle: isAr ? 'تقرير المنتجات' : 'Rapport produits',
      reportSubtitle: isAr ? 'الأداء والفئات' : 'Performance et catégories',
      from: from,
      to: to,
      locale: locale,
      body: widgets,
    );
  }

  static Future<Uint8List> buildAnnualDetailedPdf({
    required StoreSettings store,
    required int year,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> monthly,
    required Map<String, dynamic> yoy,
    required List<Map<String, dynamic>> payments,
    required List<Map<String, dynamic>> top,
    required double profit,
    required     Map<String, dynamic> expenses,
    String locale = 'fr',
  }) async {
    await IntlLocaleInit.ensureFrench();
    final isAr = locale.startsWith('ar');
    final sym = store.currencySymbol;
    final monthFmt = DateFormat('MMMM yyyy', 'fr_FR');
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31);
    final cur = _asDouble(summary['revenue']);
    final prev = _asDouble((yoy['previous'] as Map?)?['revenue']);
    String? yoyLabel;
    if (prev > 0) {
      final pct = ((cur - prev) / prev) * 100;
      yoyLabel = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)} % vs ${year - 1}';
    }

    final monthRows = <List<String>>[];
    for (final m in monthly) {
      final raw = m['month'];
      DateTime? dt;
      if (raw is DateTime) {
        dt = raw;
      } else {
        dt = DateTime.tryParse(raw?.toString() ?? '');
      }
      final label = dt != null ? monthFmt.format(dt) : '-';
      monthRows.add([
        label,
        '${m['transactions'] ?? 0}',
        money(_asDouble(m['revenue']), sym),
        money(_asDouble(m['avg_basket']), sym),
      ]);
    }

    return buildDocument(
      store: store,
      reportTitle: isAr ? 'تقرير سنوي' : 'Rapport annuel détaillé',
      reportSubtitle: isAr ? 'سنة $year' : 'Année $year',
      from: from,
      to: to,
      locale: locale,
      body: [
        kpiGrid([
          (label: isAr ? 'إيرادات السنة' : 'Recettes annuelles', value: money(cur, sym), highlight: true),
          (label: isAr ? 'المعاملات' : 'Transactions', value: '${summary['transactions']}', highlight: false),
          (label: isAr ? 'متوسط السلة' : 'Panier moyen', value: money(_asDouble(summary['avg_basket']), sym), highlight: false),
          if (yoyLabel != null)
            (label: isAr ? 'مقارنة' : 'Évolution N-1', value: yoyLabel, highlight: true),
        ]),
        if (monthly.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          ReportPdfCharts.chartBlock(
            title: isAr ? 'الإيرادات الشهرية' : 'Histogramme mensuel de l\'année',
            chart: ReportPdfCharts.monthlyRevenueChart(
              monthly,
              calendarYear: true,
            ),
          ),
        ],
        pw.SizedBox(height: 18),
        summaryPanel(
          title: isAr ? 'ملخص مالي' : 'Synthèse financière annuelle',
          children: [
            metricRow(isAr ? 'الربح التقديري' : 'Bénéfice estimé', money(profit, sym), bold: true),
            metricRow(isAr ? 'المصروفات' : 'Dépenses', money(_asDouble(expenses['total']), sym)),
            metricRow(isAr ? 'الخصومات' : 'Remises accordées', money(_asDouble(summary['total_discounts']), sym)),
          ],
        ),
        pw.SizedBox(height: 22),
        sectionTitle(
          isAr ? 'تفصيل شهري' : 'Détail mensuel',
          subtitle: isAr ? 'من يناير إلى ديسمبر' : 'Janvier à décembre',
          isAr: isAr,
        ),
        dataTable(
          headers: isAr
              ? ['الشهر', 'المعاملات', 'الإيرادات', 'متوسط السلة']
              : ['Mois', 'Transactions', 'Recettes', 'Panier moy.'],
          columnWidths: [2, 1, 1.5, 1.2],
          rows: monthRows,
        ),
        if (payments.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          sectionTitle(isAr ? 'طرق الدفع' : 'Répartition des paiements', isAr: isAr),
          dataTable(
            headers: isAr
                ? ['الطريقة', 'المعاملات', 'المبلغ']
                : ['Mode', 'Transactions', 'Montant'],
            columnWidths: [2, 1, 1.5],
            rows: [
              for (final p in payments)
                [
                  '${p['payment_method']}',
                  '${p['transactions']}',
                  money(_asDouble(p['total']), sym),
                ],
            ],
          ),
        ],
        if (top.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          sectionTitle(isAr ? 'أفضل المنتجات' : 'Top produits de l\'année', isAr: isAr),
          dataTable(
            rankColumn: true,
            headers: isAr
                ? ['#', 'المنتج', 'الكمية', 'الإيرادات']
                : ['#', 'Produit', 'Qté', 'CA'],
            columnWidths: [0.5, 3, 1, 1.5],
            rows: [
              for (var i = 0; i < top.length; i++)
                [
                  '${i + 1}',
                  '${top[i]['name_fr']}',
                  '${top[i]['qty_sold']}',
                  money(_asDouble(top[i]['revenue']), sym),
                ],
            ],
          ),
        ],
      ],
    );
  }
}
