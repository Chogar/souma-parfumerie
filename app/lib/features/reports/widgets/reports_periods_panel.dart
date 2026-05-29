import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_header.dart';
import 'package:souma_parfumerie/features/reports/data/reports_repository.dart';
import 'package:souma_parfumerie/features/reports/services/export_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Onglet rapports mensuels / annuels détaillés.
class ReportsPeriodsPanel extends StatefulWidget {
  const ReportsPeriodsPanel({
    super.key,
    required this.repo,
    required this.perms,
    required this.store,
    required this.locale,
    required this.monthlyBarChartBuilder,
  });

  final ReportsRepository repo;
  final AppPermissions perms;
  final StoreSettings store;
  final String locale;
  final Widget Function(List<Map<String, dynamic>> monthly) monthlyBarChartBuilder;

  @override
  State<ReportsPeriodsPanel> createState() => _ReportsPeriodsPanelState();
}

class _PeriodsData {
  _PeriodsData({
    required this.monthly,
    required this.summary,
    required this.yoy,
    required this.payments,
    required this.top,
    required this.profit,
    required this.expenses,
  });

  final List<Map<String, dynamic>> monthly;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> yoy;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> top;
  final double profit;
  final Map<String, dynamic> expenses;
}

class _ReportsPeriodsPanelState extends State<ReportsPeriodsPanel> {
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  final _monthLabel = DateFormat('MMMM yyyy', 'fr_FR');
  int _year = DateTime.now().year;
  Future<_PeriodsData>? _future;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = DateTime(_year, 1, 1);
    final to = DateTime(_year, 12, 31);
    setState(() {
      _future = Future.wait([
        widget.repo.monthlyBreakdownForYear(_year),
        widget.repo.yearSummary(_year),
        widget.repo.yearOverYearComparison(_year),
        widget.repo.paymentBreakdown(from: from, to: to),
        widget.repo.topProducts(from: from, to: to, limit: 15),
        widget.repo.estimatedProfit(from: from, to: to),
        widget.repo.expensesPeriod(from: from, to: to),
      ]).then((r) {
        final raw = r[0] as List<Map<String, dynamic>>;
        return _PeriodsData(
          monthly: _fillYearMonths(raw, _year),
          summary: r[1] as Map<String, dynamic>,
          yoy: r[2] as Map<String, dynamic>,
          payments: r[3] as List<Map<String, dynamic>>,
          top: r[4] as List<Map<String, dynamic>>,
          profit: r[5] as double,
          expenses: r[6] as Map<String, dynamic>,
        );
      });
    });
  }

  List<Map<String, dynamic>> _fillYearMonths(
    List<Map<String, dynamic>> raw,
    int year,
  ) {
    final byMonth = <int, Map<String, dynamic>>{};
    for (final r in raw) {
      final m = _parseMonth(r['month']);
      if (m != null) byMonth[m.month] = r;
    }
    return List.generate(12, (i) {
      final month = DateTime(year, i + 1, 1);
      final existing = byMonth[i + 1];
      if (existing != null) return existing;
      return {
        'month': month,
        'revenue': 0,
        'transactions': 0,
        'avg_basket': 0,
        'total_discounts': 0,
      };
    });
  }

  DateTime? _parseMonth(dynamic raw) {
    if (raw is DateTime) return DateTime(raw.year, raw.month, 1);
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt != null) return DateTime(dt.year, dt.month, 1);
    return null;
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  String? _yoyPercent(Map<String, dynamic> yoy) {
    final cur = _num((yoy['current'] as Map?)?['revenue']);
    final prev = _num((yoy['previous'] as Map?)?['revenue']);
    if (prev <= 0) return null;
    final pct = ((cur - prev) / prev) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)} %';
  }

  Future<void> _exportPdf(_PeriodsData data) async {
    if (_exportingPdf || !widget.perms.canViewFinancialReports) return;
    setState(() => _exportingPdf = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await ExportService.exportAnnualPeriodPdf(
        store: widget.store,
        year: _year,
        summary: data.summary,
        monthly: data.monthly,
        yoy: data.yoy,
        payments: data.payments,
        top: data.top,
        profit: data.profit,
        expenses: data.expenses,
        locale: widget.locale,
      );
      if (mounted) {
        if (result.ok) {
          AppNotifier.success('${l10n.pdfExportReady}\n${result.path}');
        } else {
          AppNotifier.error(
            '${l10n.pdfExportFailed}${result.error != null ? ': ${result.error}' : ''}',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showMoney = widget.perms.canViewFinancialReports;

    return FutureBuilder<_PeriodsData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.reportYearLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _year,
                    items: List.generate(5, (i) {
                      final y = DateTime.now().year - 2 + i;
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }),
                    onChanged: (y) {
                      if (y != null) {
                        setState(() => _year = y);
                        _load();
                      }
                    },
                  ),
                  const Spacer(),
                  if (showMoney)
                    FilledButton.icon(
                      onPressed: _exportingPdf ? null : () => _exportPdf(data),
                      icon: _exportingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: Text(l10n.exportAnnualReport),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (showMoney) ...[
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 700 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: [
                        HubStatCard(
                          label: l10n.reportAnnualRevenue,
                          value:
                              '${_fmt.format(_num(data.summary['revenue']))} ${widget.store.currencySymbol}',
                          icon: Icons.payments_outlined,
                        ),
                        HubStatCard(
                          label: l10n.transactions,
                          value: '${data.summary['transactions'] ?? 0}',
                          icon: Icons.receipt_long_outlined,
                          accent: const Color(0xFF4A6FA5),
                        ),
                        HubStatCard(
                          label: l10n.averageBasket,
                          value:
                              '${_fmt.format(_num(data.summary['avg_basket']))} ${widget.store.currencySymbol}',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        if (_yoyPercent(data.yoy) != null)
                          HubStatCard(
                            label: l10n.reportYoyChange,
                            value: _yoyPercent(data.yoy)!,
                            icon: Icons.trending_up,
                            accent: const Color(0xFF6B8E6B),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              HubSectionPanel(
                title: l10n.reportMonthlyBreakdown,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                  child: SizedBox(
                    height: 260,
                    child: widget.monthlyBarChartBuilder(data.monthly),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              HubSectionPanel(
                title: l10n.reportMonthlyTable,
                child: _MonthlyTable(
                  monthly: data.monthly,
                  showMoney: showMoney,
                  fmt: _fmt,
                  monthLabel: _monthLabel,
                  currency: widget.store.currencySymbol,
                  num: _num,
                  l10n: l10n,
                ),
              ),
              if (showMoney && data.payments.isNotEmpty) ...[
                const SizedBox(height: 20),
                HubSectionPanel(
                  title: l10n.reportPaymentBreakdown,
                  child: Column(
                    children: [
                      for (final p in data.payments)
                        ListTile(
                          dense: true,
                          title: Text('${p['payment_method']}'),
                          trailing: Text(
                            '${_fmt.format(_num(p['total']))} ${widget.store.currencySymbol}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${p['transactions']} ${l10n.transactions}'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyTable extends StatelessWidget {
  const _MonthlyTable({
    required this.monthly,
    required this.showMoney,
    required this.fmt,
    required this.monthLabel,
    required this.currency,
    required this.num,
    required this.l10n,
  });

  final List<Map<String, dynamic>> monthly;
  final bool showMoney;
  final NumberFormat fmt;
  final DateFormat monthLabel;
  final String currency;
  final double Function(dynamic) num;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AppTheme.primary.withValues(alpha: 0.08),
        ),
        columns: [
          DataColumn(label: Text(l10n.reportMonthColumn)),
          DataColumn(label: Text(l10n.transactions), numeric: true),
          if (showMoney) ...[
            DataColumn(label: Text(l10n.periodRevenue), numeric: true),
            DataColumn(label: Text(l10n.averageBasket), numeric: true),
          ],
        ],
        rows: [
          for (final m in monthly)
            DataRow(
              cells: [
                DataCell(Text(_monthName(m['month']))),
                DataCell(Text('${m['transactions'] ?? 0}')),
                if (showMoney) ...[
                  DataCell(Text('${fmt.format(num(m['revenue']))} $currency')),
                  DataCell(Text('${fmt.format(num(m['avg_basket']))} $currency')),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _monthName(dynamic raw) {
    if (raw is DateTime) return monthLabel.format(raw);
    final dt = DateTime.tryParse(raw?.toString() ?? '');
    if (dt != null) return monthLabel.format(dt);
    return raw?.toString() ?? '—';
  }
}
