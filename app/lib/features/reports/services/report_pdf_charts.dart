import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Graphiques PDF (histogrammes, courbes, secteurs) alignés sur l'app.
class ReportPdfCharts {
  ReportPdfCharts._();

  static const _primary = PdfColor.fromInt(0xFF1A1A2E);
  static const _accent = PdfColor.fromInt(0xFFC9A227);
  static const _accent2 = PdfColor.fromInt(0xFF4A6FA5);
  static const _accent3 = PdfColor.fromInt(0xFF6B8E6B);
  static const _surface = PdfColor.fromInt(0xFFF8F6F1);
  static const _muted = PdfColor.fromInt(0xFF6B7280);

  static const _monthNamesFr = [
    'Janv',
    'Févr',
    'Mars',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Août',
    'Sept',
    'Oct',
    'Nov',
    'Déc',
  ];

  static String _dayLabel(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  static String _monthLabel(DateTime dt) =>
      '${_monthNamesFr[dt.month - 1]} ${dt.year % 100}';

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseMonth(dynamic raw) {
    if (raw is DateTime) return DateTime(raw.year, raw.month, 1);
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    return dt != null ? DateTime(dt.year, dt.month, 1) : null;
  }

  static pw.Widget chartBlock({
    required String title,
    required pw.Widget chart,
    String? subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
          ),
          child: chart,
        ),
      ],
    );
  }

  /// Histogramme mensuel (recettes).
  static pw.Widget monthlyRevenueChart(
    List<Map<String, dynamic>> monthly, {
    bool calendarYear = false,
  }) {
    final points = <({String label, double value})>[];
    if (calendarYear && monthly.length >= 12) {
      for (final m in monthly) {
        final dt = _parseMonth(m['month']);
        points.add((
          label: dt != null ? _monthLabel(dt) : '-',
          value: _asDouble(m['revenue']),
        ));
      }
    } else {
      for (var i = 0; i < monthly.length; i++) {
        final m = monthly[i];
        final dt = _parseMonth(m['month']);
        points.add((
          label: dt != null ? _monthLabel(dt) : '${i + 1}',
          value: _asDouble(m['revenue']),
        ));
      }
    }
    return _barChart(points, barColor: _accent);
  }

  /// CA par caissier.
  static pw.Widget cashierRevenueChart(List<Map<String, dynamic>> cashiers) {
    final points = <({String label, double value})>[];
    for (final c in cashiers) {
      final name = '${c['cashier_name'] ?? '-'}';
      points.add((
        label: name.length > 9 ? '${name.substring(0, 9)}…' : name,
        value: _asDouble(c['revenue']),
      ));
    }
    return _barChart(points, barColor: _accent2);
  }

  /// Courbe / barres journalières (évolution CA).
  static pw.Widget dailyRevenueChart(List<Map<String, dynamic>> daily) {
    final points = <({String label, double value})>[];
    for (final d in daily) {
      final raw = d['day'];
      DateTime? dt;
      if (raw is DateTime) {
        dt = raw;
      } else {
        dt = DateTime.tryParse(raw?.toString() ?? '');
      }
      points.add((
        label: dt != null ? _dayLabel(dt) : '',
        value: _asDouble(d['revenue']),
      ));
    }
    if (points.length > 31) {
      final step = (points.length / 20).ceil().clamp(1, points.length);
      final sampled = <({String label, double value})>[];
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      return _lineChart(sampled);
    }
    return _lineChart(points);
  }

  /// Répartition des modes de paiement (même visuel que catégories).
  static pw.Widget paymentBreakdownChart(List<Map<String, dynamic>> payments) {
    final mapped = [
      for (final p in payments)
        {
          'name_fr': p['payment_method'],
          'revenue': p['total'],
        },
    ];
    return categoryPieChart(
      mapped,
      nameOf: (r) => '${r['name_fr']}',
    );
  }

  /// Répartition catégories (secteurs visuels + légende).
  static pw.Widget categoryPieChart(
    List<Map<String, dynamic>> byCategory, {
    String Function(Map<String, dynamic>)? nameOf,
  }) {
    final total = byCategory.fold<double>(
      0,
      (s, r) => s + _asDouble(r['revenue']),
    );
    if (total <= 0) {
      return pw.Text('-', style: const pw.TextStyle(color: _muted, fontSize: 10));
    }

    final colors = [_accent, _primary, _accent2, _accent3, PdfColors.orange, PdfColors.teal];
    final slices = <pw.Widget>[];
    var i = 0;
    for (final r in byCategory.take(8)) {
      final v = _asDouble(r['revenue']);
      final pct = (v / total * 100);
      final name = nameOf != null
          ? nameOf(r)
          : (r['name_fr'] ?? r['category_name_fr'] ?? '-').toString();
      final color = colors[i % colors.length];
      slices.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.Container(width: 12, height: 12, color: color),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  name,
                  style: const pw.TextStyle(fontSize: 9),
                  maxLines: 1,
                ),
              ),
              pw.Text(
                '${pct.toStringAsFixed(0)} %',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
      );
      i++;
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: _donutLegend(byCategory, total, colors),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: slices,
          ),
        ),
      ],
    );
  }

  /// Anneau proportionnel (segments empilés).
  static pw.Widget _donutLegend(
    List<Map<String, dynamic>> data,
    double total,
    List<PdfColor> colors,
  ) {
    final segments = <pw.Widget>[];
    var i = 0;
    for (final r in data.take(6)) {
      final v = _asDouble(r['revenue']);
      if (v <= 0) continue;
      final h = (v / total * 120).clamp(4.0, 120.0);
      segments.add(
        pw.Container(
          height: h,
          color: colors[i % colors.length],
        ),
      );
      i++;
    }
    if (segments.isEmpty) {
      return pw.SizedBox(height: 80);
    }
    return pw.Container(
      width: 48,
      height: 120,
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: segments.reversed.toList(),
      ),
    );
  }

  /// Histogrammes PDF sans `pw.Chart` (évite NaN / crash à l'enregistrement).
  static pw.Widget _barChart(
    List<({String label, double value})> points, {
    required PdfColor barColor,
    double maxBarWidth = 300,
  }) {
    if (points.isEmpty) {
      return pw.Text('-', style: const pw.TextStyle(color: _muted, fontSize: 10));
    }
    final max = points.fold<double>(
      0,
      (a, p) => p.value.isFinite && p.value > a ? p.value : a,
    );
    if (max <= 0 || !max.isFinite) {
      return pw.Text('-', style: const pw.TextStyle(color: _muted, fontSize: 10));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final p in points)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 42,
                  child: pw.Text(
                    p.label,
                    style: const pw.TextStyle(fontSize: 7, color: _muted),
                    maxLines: 2,
                  ),
                ),
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.Container(
                        width: (p.value / max).clamp(0.0, 1.0) * maxBarWidth,
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: barColor,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.SizedBox(
                  width: 52,
                  child: pw.Text(
                    _formatCompact(p.value),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _lineChart(List<({String label, double value})> points) =>
      _barChart(points, barColor: _accent2);

  static String _formatCompact(double v) {
    if (!v.isFinite) return '0';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
