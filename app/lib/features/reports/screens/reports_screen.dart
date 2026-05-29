import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/services/store_settings_service.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_header.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_layout.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/reports/data/reports_repository.dart';
import 'package:souma_parfumerie/features/reports/services/export_service.dart';
import 'package:souma_parfumerie/features/reports/widgets/report_period_dialog.dart';
import 'package:souma_parfumerie/features/reports/widgets/reports_periods_panel.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with AutoRefreshMixin {
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  final _dayFmt = DateFormat('dd/MM', 'fr_FR');
  final _monthFmt = DateFormat('MMM yy', 'fr_FR');

  late DateTime _from;
  late DateTime _to;
  Future<List<Object?>>? _reportFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 29));
    _loadReports();
  }

  ReportsRepository _repoFor(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    return ReportsRepository(
      scopeUserId: perms.scopeOwnSalesOnly ? user.id : null,
    );
  }

  @override
  void onAutoRefresh() => _loadReports();

  void _loadReports() {
    final repo = _repoFor(context);
    setState(() {
      _reportFuture = Future.wait([
        repo.periodSummary(from: _from, to: _to),
        repo.topProducts(from: _from, to: _to),
        repo.revenueByDay(from: _from, to: _to),
        repo.estimatedProfit(from: _from, to: _to),
        repo.previousPeriodComparison(from: _from, to: _to),
        repo.salesByCategory(from: _from, to: _to),
        repo.expensesPeriod(from: _from, to: _to),
        repo.salesByCashier(from: _from, to: _to),
        repo.monthlyRevenue(months: 12),
        repo.paymentBreakdown(from: _from, to: _to),
        repo.returnPeriodSummary(from: _from, to: _to),
      ]);
    });
  }

  void _presetYear() {
    final now = DateTime.now();
    setState(() {
      _to = DateTime(now.year, now.month, now.day);
      _from = DateTime(now.year, 1, 1);
    });
    _loadReports();
  }

  void _presetCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _from = DateTime(now.year, now.month, 1);
      _to = DateTime(now.year, now.month, now.day);
    });
    _loadReports();
  }

  void _presetLastMonth() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final lastPrev = first.subtract(const Duration(days: 1));
    setState(() {
      _from = DateTime(lastPrev.year, lastPrev.month, 1);
      _to = lastPrev;
    });
    _loadReports();
  }

  Future<void> _pickRange() async {
    final picked = await ReportPeriodDialog.show(
      context,
      from: _from,
      to: _to,
    );
    if (picked != null) {
      setState(() {
        _from = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
      _loadReports();
    }
  }

  void _presetDays(int days) {
    final now = DateTime.now();
    setState(() {
      _to = DateTime(now.year, now.month, now.day);
      _from = _to.subtract(Duration(days: days - 1));
    });
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final periodLabel =
        '${DateFormat('dd/MM/yyyy').format(_from)} — ${DateFormat('dd/MM/yyyy').format(_to)}';

    if (!perms.canViewOperationalReports) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(l10n.managerOnly, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return HubPageLayout(
      title: l10n.reports,
      subtitle: l10n.reportsSubtitle,
      icon: Icons.insights_rounded,
      body: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 18,
                    color: AppTheme.accent.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      periodLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: l10n.reportPresetToday,
                    onTap: () => _presetDays(1),
                  ),
                  const SizedBox(width: 4),
                  _PeriodChip(
                    label: l10n.reportPresetWeek,
                    onTap: () => _presetDays(7),
                  ),
                  const SizedBox(width: 4),
                  _PeriodChip(
                    label: l10n.reportPresetMonth,
                    onTap: () => _presetDays(30),
                  ),
                  const SizedBox(width: 4),
                  _PeriodChip(
                    label: l10n.reportPresetCurrentMonth,
                    onTap: _presetCurrentMonth,
                  ),
                  const SizedBox(width: 4),
                  _PeriodChip(
                    label: l10n.reportPresetLastMonth,
                    onTap: _presetLastMonth,
                  ),
                  const SizedBox(width: 4),
                  _PeriodChip(
                    label: l10n.reportPresetYear,
                    onTap: _presetYear,
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: l10n.reportCustomRange,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      padding: const EdgeInsets.all(6),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                      ),
                      onPressed: _pickRange,
                      icon: const Icon(Icons.edit_calendar, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            HubStyledTabBar(
              tabs: [
                hubTabWidget(HubTab(
                  label: l10n.reportTabOverview,
                  icon: Icons.dashboard_outlined,
                )),
                hubTabWidget(HubTab(
                  label: l10n.reportTabSales,
                  icon: Icons.receipt_long_outlined,
                )),
                hubTabWidget(HubTab(
                  label: l10n.reportTabProducts,
                  icon: Icons.inventory_2_outlined,
                )),
                hubTabWidget(HubTab(
                  label: l10n.reportTabPeriods,
                  icon: Icons.calendar_month_outlined,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Object?>>(
                future: _reportFuture,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final d = snap.data!;
                  return TabBarView(
                    children: [
                      _scrollTab(_buildOverview(
                        context, l10n, locale, perms,
                        d[0] as Map<String, dynamic>,
                        d[1] as List<Map<String, dynamic>>,
                        d[2] as List<Map<String, dynamic>>,
                        d[8] as List<Map<String, dynamic>>,
                        d[10] as Map<String, dynamic>,
                      )),
                      _scrollTab(_buildSalesTab(
                        context, l10n, locale, perms,
                        d[0] as Map<String, dynamic>,
                        d[3] as double,
                        d[4] as Map<String, dynamic>,
                        d[6] as Map<String, dynamic>,
                        d[7] as List<Map<String, dynamic>>,
                        d[2] as List<Map<String, dynamic>>,
                        d[9] as List<Map<String, dynamic>>,
                      )),
                      _scrollTab(_buildProductsTab(
                        context, l10n, locale, perms,
                        d[1] as List<Map<String, dynamic>>,
                        d[5] as List<Map<String, dynamic>>,
                      )),
                      ReportsPeriodsPanel(
                        repo: _repoFor(context),
                        perms: perms,
                        store: context.read<StoreSettingsService>().settings,
                        locale: locale,
                        monthlyBarChartBuilder: _calendarYearBarChart,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollTab(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  List<Widget> _buildOverview(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    AppPermissions perms,
    Map<String, dynamic> summary,
    List<Map<String, dynamic>> top,
    List<Map<String, dynamic>> daily,
    List<Map<String, dynamic>> monthly,
    Map<String, dynamic> returnStats,
  ) {
    final requested = _int(returnStats['requested']);
    final pending = _int(returnStats['pending']);
    final approved = _int(returnStats['approved']);
    final rejected = _int(returnStats['rejected']);
    final hasReturnStats =
        requested > 0 || pending > 0 || approved > 0 || rejected > 0;

    return [
      ..._buildKpiGrid(context, l10n, perms, summary),
      if (hasReturnStats) ...[
        const SizedBox(height: 20),
        HubSectionPanel(
          title: l10n.reportReturnsTitle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: LayoutBuilder(
              builder: (context, c) {
                final cols =
                    c.maxWidth > 720 ? 4 : (c.maxWidth > 400 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 2.6 : 1.8,
                  children: [
                    HubStatCard(
                      label: l10n.reportReturnsRequested,
                      value: '$requested',
                      icon: Icons.assignment_return_outlined,
                    ),
                    HubStatCard(
                      label: l10n.saleReturnPending,
                      value: '$pending',
                      icon: Icons.hourglass_top_outlined,
                      accent: const Color(0xFFE65100),
                    ),
                    HubStatCard(
                      label: l10n.reportReturnsApproved,
                      value: '$approved',
                      icon: Icons.check_circle_outline,
                      accent: const Color(0xFF2E7D32),
                    ),
                    HubStatCard(
                      label: l10n.reportReturnsRejected,
                      value: '$rejected',
                      icon: Icons.cancel_outlined,
                      accent: const Color(0xFFB00020),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
      if (perms.canViewFinancialReports) ...[
        const SizedBox(height: 20),
        _ExportBar(
          l10n: l10n,
          store: context.read<StoreSettingsService>().settings,
          locale: locale,
          summary: summary,
          top: top,
          from: _from,
          to: _to,
          dailyRevenue: daily,
          monthlyRevenue: monthly,
          returnStats: returnStats,
        ),
      ],
      if (perms.canViewFinancialReports && monthly.isNotEmpty) ...[
        const SizedBox(height: 24),
        HubSectionPanel(
          title: l10n.reportAnnualHint,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
            child: SizedBox(
              height: 280,
              child: _monthlyBarChart(monthly),
            ),
          ),
        ),
      ],
      if (perms.canViewFinancialReports) ...[
        const SizedBox(height: 24),
        HubSectionPanel(
          title: l10n.revenueEvolution,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
            child: SizedBox(
              height: 240,
              child: daily.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : LineChart(_dailyChartData(daily)),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildSalesTab(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    AppPermissions perms,
    Map<String, dynamic> summary,
    double profit,
    Map<String, dynamic> comparison,
    Map<String, dynamic> expenses,
    List<Map<String, dynamic>> cashiers,
    List<Map<String, dynamic>> daily,
    List<Map<String, dynamic>> payments,
  ) {
    final showFinancial = perms.canViewFinancialReports;
    final currency = context.read<StoreSettingsService>().currencySymbol;
    final revenue = _num(summary['revenue']);
    final expenseTotal = _num(expenses['total']);
    final periodLabel =
        '${DateFormat('dd/MM/yyyy').format(_from)} — ${DateFormat('dd/MM/yyyy').format(_to)}';

    final children = <Widget>[
      HubSectionPanel(
        title: l10n.reportDailyTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              periodLabel,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 720 ? 3 : (c.maxWidth > 400 ? 2 : 1);
                final metrics = <_ReportMetric>[
                  _ReportMetric(
                    l10n.transactions,
                    '${summary['transactions'] ?? 0}',
                    Icons.receipt_long_outlined,
                    const Color(0xFF4A6FA5),
                  ),
                  if (showFinancial) ...[
                    _ReportMetric(
                      l10n.periodRevenue,
                      '${_fmt.format(revenue)} $currency',
                      Icons.payments_outlined,
                      AppTheme.accent,
                    ),
                    _ReportMetric(
                      l10n.estimatedProfit,
                      '${_fmt.format(profit)} $currency',
                      Icons.trending_up,
                      const Color(0xFF2E7D32),
                    ),
                    _ReportMetric(
                      l10n.totalDiscounts,
                      '${_fmt.format(_num(summary['total_discounts']))} $currency',
                      Icons.discount_outlined,
                      Colors.grey,
                    ),
                    _ReportMetric(
                      l10n.totalExpenses,
                      '${_fmt.format(expenseTotal)} $currency',
                      Icons.arrow_outward,
                      const Color(0xFFB00020),
                    ),
                    _ReportMetric(
                      l10n.netEstimate,
                      '${_fmt.format(revenue - expenseTotal)} $currency',
                      Icons.account_balance_wallet_outlined,
                      AppTheme.primary,
                      highlight: true,
                    ),
                  ],
                ];
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 2.4 : 1.85,
                  children: [
                    for (final m in metrics) _ReportMetricTile(metric: m),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ];

    if (cashiers.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 20),
        HubSectionPanel(
          title: l10n.salesByCashier,
          child: Column(
            children: [
              for (var i = 0; i < cashiers.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _CashierSaleTile(
                  name: cashiers[i]['cashier_name']?.toString() ?? '—',
                  transactions: '${cashiers[i]['transactions'] ?? 0}',
                  revenue: showFinancial
                      ? '${_fmt.format(_num(cashiers[i]['revenue']))} $currency'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ]);
    }

    if (showFinancial) {
      final cur = comparison['current'] as Map<String, dynamic>? ?? {};
      final prev = comparison['previous'] as Map<String, dynamic>? ?? {};
      final curRev = _num(cur['revenue']);
      final prevRev = _num(prev['revenue']);
      final curTx = cur['transactions'] ?? 0;
      final prevTx = prev['transactions'] ?? 0;
      final pct = prevRev > 0 ? ((curRev - prevRev) / prevRev * 100) : 0.0;
      children.addAll([
        const SizedBox(height: 20),
        HubSectionPanel(
          title: l10n.periodComparison,
          child: _PeriodComparisonPanel(
            pct: pct,
            currentRevenue: '${_fmt.format(curRev)} $currency',
            previousRevenue: '${_fmt.format(prevRev)} $currency',
            currentTransactions: '$curTx ${l10n.transactions}',
            previousTransactions: '$prevTx ${l10n.transactions}',
            currentLabel: l10n.reportPeriodCurrent,
            previousLabel: l10n.reportPeriodPrevious,
            evolutionLabel: l10n.revenueChange,
          ),
        ),
      ]);
    }

    if (showFinancial) {
      children.addAll([
        const SizedBox(height: 20),
        _SalesExportBar(
          l10n: l10n,
          store: context.read<StoreSettingsService>().settings,
          locale: locale,
          summary: summary,
          profit: profit,
          expenses: expenses,
          cashiers: cashiers,
          from: _from,
          to: _to,
          dailyRevenue: daily,
          payments: payments,
        ),
      ]);
    }

    return children;
  }

  List<Widget> _buildProductsTab(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    AppPermissions perms,
    List<Map<String, dynamic>> top,
    List<Map<String, dynamic>> byCategory,
  ) {
    final showFinancial = perms.canViewFinancialReports;
    return [
      HubSectionPanel(
        title: l10n.topProducts,
        child: top.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l10n.noData)),
              )
            : _TopProductsPreview(
                top: top,
                locale: locale,
                showFinancial: showFinancial,
                fmt: _fmt,
                num: _num,
                productName: (r) => _productName(r, locale),
                categoryName: (r) => _categoryName(r, locale),
              ),
      ),
      if (showFinancial && byCategory.isNotEmpty) ...[
        const SizedBox(height: 20),
        HubSectionPanel(
          title: l10n.salesByCategory,
          child: SizedBox(
            height: 220,
            child: _categoryPieChart(byCategory, l10n.noData),
          ),
        ),
      ],
      if (showFinancial) ...[
        const SizedBox(height: 20),
        _ProductsExportBar(
          l10n: l10n,
          store: context.read<StoreSettingsService>().settings,
          locale: locale,
          top: top,
          byCategory: byCategory,
          from: _from,
          to: _to,
        ),
      ],
    ];
  }

  List<Widget> _buildKpiGrid(
    BuildContext context,
    AppLocalizations l10n,
    AppPermissions perms,
    Map<String, dynamic> summary,
  ) {
    if (!perms.canViewFinancialReports) {
      return [
        HubStatCard(
          label: l10n.transactions,
          value: '${summary['transactions'] ?? 0}',
          icon: Icons.receipt_long_outlined,
        ),
      ];
    }
    return [
      LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cols = w > 900 ? 3 : (w > 520 ? 2 : 1);
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: cols == 1 ? 2.6 : 2.2,
            children: [
              HubStatCard(
                label: l10n.periodRevenue,
                value:
                    '${_fmt.format(_num(summary['revenue']))} ${AppConfig.currencySymbol}',
                icon: Icons.payments_outlined,
              ),
              HubStatCard(
                label: l10n.transactions,
                value: '${summary['transactions'] ?? 0}',
                icon: Icons.receipt_long_outlined,
                accent: const Color(0xFF4A6FA5),
              ),
              HubStatCard(
                label: l10n.averageBasket,
                value:
                    '${_fmt.format(_num(summary['avg_basket']))} ${AppConfig.currencySymbol}',
                icon: Icons.shopping_bag_outlined,
                accent: const Color(0xFF6B8E6B),
              ),
            ],
          );
        },
      ),
    ];
  }

  String _categoryName(Map<String, dynamic> r, String locale) {
    final name = locale.startsWith('ar') ? r['category_ar'] : r['category_fr'];
    return name?.toString() ?? '';
  }

  /// Série complète sur 12 mois (mois sans vente = 0).
  List<Map<String, dynamic>> _normalizeMonthlySeries(
    List<Map<String, dynamic>> raw, {
    int months = 12,
  }) {
    final byMonth = <String, double>{};
    for (final r in raw) {
      final m = _parseMonth(r['month']);
      if (m == null) continue;
      byMonth['${m.year}-${m.month}'] = _num(r['revenue']);
    }

    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, 1);
    final series = <Map<String, dynamic>>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(anchor.year, anchor.month - i, 1);
      final key = '${month.year}-${month.month}';
      series.add({
        'month': month,
        'revenue': byMonth[key] ?? 0.0,
      });
    }
    return series;
  }

  DateTime? _parseMonth(dynamic raw) {
    if (raw is DateTime) return DateTime(raw.year, raw.month, 1);
    if (raw == null) return null;
    final s = raw.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) return DateTime(dt.year, dt.month, 1);
    return null;
  }

  String _formatChartAxisValue(double value) {
    final v = value.abs();
    if (v >= 1000000) {
      final m = value / 1000000;
      return '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)} M';
    }
    if (v >= 1000) {
      final k = value / 1000;
      return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)} k';
    }
    return _fmt.format(value);
  }

  /// Graphique 12 mois d'une année civile (janv. → déc.).
  Widget _calendarYearBarChart(List<Map<String, dynamic>> monthly) =>
      _monthlyBarChart(monthly, useRawSeries: true);

  Widget _monthlyBarChart(
    List<Map<String, dynamic>> monthly, {
    bool useRawSeries = false,
  }) {
    final currency = context.read<StoreSettingsService>().currencySymbol;
    final series =
        useRawSeries ? monthly : _normalizeMonthlySeries(monthly);
    if (series.every((m) => _num(m['revenue']) <= 0)) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noData,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final maxVal = series
        .map((m) => _num(m['revenue']))
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;
    final yInterval = maxY / 4;

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < series.length; i++) {
      final revenue = _num(series[i]['revenue']);
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: AppTheme.accent,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: AppTheme.accent.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 8,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.18),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
            left: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY + 0.01) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatChartAxisValue(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length) {
                  return const SizedBox.shrink();
                }
                final month = series[i]['month'] as DateTime;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _monthFmt.format(month),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.primary.withValues(alpha: 0.92),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = series[group.x]['month'] as DateTime;
              final revenue = rod.toY;
              return BarTooltipItem(
                '${_monthFmt.format(month)}\n',
                const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${_fmt.format(revenue)} $currency',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: groups,
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _categoryPieChart(List<Map<String, dynamic>> data, String noDataLabel) {
    final total = data.fold<double>(0, (s, r) => s + _num(r['revenue']));
    if (total <= 0) {
      return Center(child: Text(noDataLabel));
    }
    final colors = [
      AppTheme.accent,
      AppTheme.primary,
      const Color(0xFF4A6FA5),
      const Color(0xFF6B8E6B),
      Colors.orange,
      Colors.teal,
    ];
    var i = 0;
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        sections: [
          for (final r in data)
            PieChartSectionData(
              value: _num(r['revenue']),
              title: '${(_num(r['revenue']) / total * 100).toStringAsFixed(0)}%',
              radius: 48,
              color: colors[i++ % colors.length],
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _productName(Map<String, dynamic> r, String locale) {
    final name = locale.startsWith('ar') ? r['name_ar'] : r['name_fr'];
    return name?.toString() ?? '—';
  }

  LineChartData _dailyChartData(List<Map<String, dynamic>> daily) {
    final spots = <FlSpot>[
      for (var i = 0; i < daily.length; i++)
        FlSpot(i.toDouble(), _num(daily[i]['revenue'])),
    ];
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return LineChartData(
      minY: 0,
      maxY: maxY <= 0 ? 1 : maxY * 1.15,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: Colors.grey.withValues(alpha: 0.2),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (v, _) => Text(
              _fmt.format(v),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, meta) {
              final i = v.toInt();
              if (i < 0 || i >= daily.length) return const SizedBox.shrink();
              final d = daily[i]['day'];
              final label = d is DateTime
                  ? _dayFmt.format(d)
                  : (d?.toString().substring(5, 10) ?? '');
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppTheme.accent,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: AppTheme.accent,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.accent.withValues(alpha: 0.35),
                AppTheme.accent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class _SalesExportBar extends StatefulWidget {
  const _SalesExportBar({
    required this.l10n,
    required this.store,
    required this.locale,
    required this.summary,
    required this.profit,
    required this.expenses,
    required this.cashiers,
    required this.from,
    required this.to,
    required this.dailyRevenue,
    required this.payments,
  });

  final AppLocalizations l10n;
  final StoreSettings store;
  final String locale;
  final Map<String, dynamic> summary;
  final double profit;
  final Map<String, dynamic> expenses;
  final List<Map<String, dynamic>> cashiers;
  final DateTime from;
  final DateTime to;
  final List<Map<String, dynamic>> dailyRevenue;
  final List<Map<String, dynamic>> payments;

  @override
  State<_SalesExportBar> createState() => _SalesExportBarState();
}

class _SalesExportBarState extends State<_SalesExportBar> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final result = await ExportService.exportSalesPdf(
        store: widget.store,
        summary: widget.summary,
        profit: widget.profit,
        expenses: widget.expenses,
        cashiers: widget.cashiers,
        from: widget.from,
        to: widget.to,
        dailyRevenue: widget.dailyRevenue,
        payments: widget.payments,
        locale: widget.locale,
      );
      if (mounted) {
        if (result.ok) {
          AppNotifier.success(
            '${widget.l10n.pdfExportReady}\n${result.path}',
            context: context,
          );
        } else {
          AppNotifier.error(
            '${widget.l10n.pdfExportFailed}${result.error != null ? ': ${result.error}' : ''}',
            context: context,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final file = await ExportService.exportSalesExcel(
        store: widget.store,
        summary: widget.summary,
        profit: widget.profit,
        expenses: widget.expenses,
        cashiers: widget.cashiers,
        from: widget.from,
        to: widget.to,
      );
      if (mounted) {
        if (file != null) {
          AppNotifier.success(
            '${widget.l10n.exportExcel}: ${file.path}',
            context: context,
          );
        } else {
          AppNotifier.error(widget.l10n.pdfExportFailed, context: context);
        }
      }
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ExportButtonsRow(
        l10n: widget.l10n,
        exportingPdf: _exportingPdf,
        exportingExcel: _exportingExcel,
        onPdf: _exportPdf,
        onExcel: _exportExcel,
      );
}

class _ProductsExportBar extends StatefulWidget {
  const _ProductsExportBar({
    required this.l10n,
    required this.store,
    required this.locale,
    required this.top,
    required this.byCategory,
    required this.from,
    required this.to,
  });

  final AppLocalizations l10n;
  final StoreSettings store;
  final String locale;
  final List<Map<String, dynamic>> top;
  final List<Map<String, dynamic>> byCategory;
  final DateTime from;
  final DateTime to;

  @override
  State<_ProductsExportBar> createState() => _ProductsExportBarState();
}

class _ProductsExportBarState extends State<_ProductsExportBar> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final result = await ExportService.exportProductsPdf(
        store: widget.store,
        top: widget.top,
        byCategory: widget.byCategory,
        from: widget.from,
        to: widget.to,
        locale: widget.locale,
      );
      if (mounted) {
        if (result.ok) {
          AppNotifier.success(
            '${widget.l10n.pdfExportReady}\n${result.path}',
            context: context,
          );
        } else {
          AppNotifier.error(
            '${widget.l10n.pdfExportFailed}${result.error != null ? ': ${result.error}' : ''}',
            context: context,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final file = await ExportService.exportProductsExcel(
        store: widget.store,
        top: widget.top,
        byCategory: widget.byCategory,
        from: widget.from,
        to: widget.to,
      );
      if (mounted) {
        if (file != null) {
          AppNotifier.success(
            '${widget.l10n.exportExcel}: ${file.path}',
            context: context,
          );
        } else {
          AppNotifier.error(widget.l10n.pdfExportFailed, context: context);
        }
      }
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ExportButtonsRow(
        l10n: widget.l10n,
        exportingPdf: _exportingPdf,
        exportingExcel: _exportingExcel,
        onPdf: _exportPdf,
        onExcel: _exportExcel,
      );
}

class _ExportButtonsRow extends StatelessWidget {
  const _ExportButtonsRow({
    required this.l10n,
    required this.exportingPdf,
    required this.exportingExcel,
    required this.onPdf,
    required this.onExcel,
  });

  final AppLocalizations l10n;
  final bool exportingPdf;
  final bool exportingExcel;
  final VoidCallback onPdf;
  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppTheme.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.exportReportsHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: exportingPdf ? null : onPdf,
              icon: exportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text(l10n.exportPdf),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: exportingExcel ? null : onExcel,
              icon: exportingExcel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart_outlined, size: 20),
              label: Text(l10n.exportExcel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportBar extends StatefulWidget {
  const _ExportBar({
    required this.l10n,
    required this.store,
    required this.locale,
    required this.summary,
    required this.top,
    required this.from,
    required this.to,
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.returnStats,
  });

  final AppLocalizations l10n;
  final StoreSettings store;
  final String locale;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> top;
  final DateTime from;
  final DateTime to;
  final List<Map<String, dynamic>> dailyRevenue;
  final List<Map<String, dynamic>> monthlyRevenue;
  final Map<String, dynamic> returnStats;

  @override
  State<_ExportBar> createState() => _ExportBarState();
}

class _ExportBarState extends State<_ExportBar> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final result = await ExportService.exportPeriodPdf(
        store: widget.store,
        summary: widget.summary,
        top: widget.top,
        from: widget.from,
        to: widget.to,
        dailyRevenue: widget.dailyRevenue,
        monthlyRevenue: widget.monthlyRevenue,
        returnStats: widget.returnStats,
        locale: widget.locale,
      );
      if (mounted) {
        if (result.ok) {
          AppNotifier.success(
            '${widget.l10n.pdfExportReady}\n${result.path}',
            context: context,
          );
        } else {
          AppNotifier.error(
            '${widget.l10n.pdfExportFailed}${result.error != null ? ': ${result.error}' : ''}',
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.error('${widget.l10n.pdfExportFailed}: $e', context: context);
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final file = await ExportService.exportPeriodExcel(
        store: widget.store,
        summary: widget.summary,
        top: widget.top,
        from: widget.from,
        to: widget.to,
      );
      if (mounted) {
        if (file != null) {
          AppNotifier.success(
            '${widget.l10n.exportExcel}: ${file.path}',
            context: context,
          );
        } else {
          AppNotifier.error(widget.l10n.pdfExportFailed, context: context);
        }
      }
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ExportButtonsRow(
        l10n: widget.l10n,
        exportingPdf: _exportingPdf,
        exportingExcel: _exportingExcel,
        onPdf: _exportPdf,
        onExcel: _exportExcel,
      );
}

class _TopProductsPreview extends StatelessWidget {
  const _TopProductsPreview({
    required this.top,
    required this.locale,
    required this.showFinancial,
    required this.fmt,
    required this.num,
    required this.productName,
    this.categoryName,
  });

  static const _previewCount = 4;

  final List<Map<String, dynamic>> top;
  final String locale;
  final bool showFinancial;
  final NumberFormat fmt;
  final double Function(dynamic) num;
  final String Function(Map<String, dynamic>) productName;
  final String Function(Map<String, dynamic>)? categoryName;

  void _openDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.topProducts,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: top.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final cat = categoryName?.call(top[i]);
                    return _TopProductRow(
                      rank: i + 1,
                      name: productName(top[i]),
                      subtitle: cat != null && cat.isNotEmpty ? cat : null,
                      qty: '${top[i]['qty_sold']}',
                      saleCount: '${top[i]['sale_count'] ?? ''}',
                      revenue: showFinancial
                          ? '${fmt.format(num(top[i]['revenue']))} ${AppConfig.currencySymbol}'
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = top.take(_previewCount).toList();
    final remaining = top.length - preview.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: preview.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (_, i) {
            final cat = categoryName?.call(preview[i]);
            return _TopProductRow(
              rank: i + 1,
              name: productName(preview[i]),
              subtitle: cat != null && cat.isNotEmpty ? cat : null,
              qty: '${preview[i]['qty_sold']}',
              saleCount: '${preview[i]['sale_count'] ?? ''}',
              revenue: showFinancial
                  ? '${fmt.format(num(preview[i]['revenue']))} ${AppConfig.currencySymbol}'
                  : null,
            );
          },
        ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: TextButton.icon(
              onPressed: () => _openDetails(context),
              icon: const Icon(Icons.unfold_more, size: 20),
              label: Text(l10n.topProductsShowMore(remaining)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.rank,
    required this.name,
    required this.qty,
    this.subtitle,
    this.saleCount,
    this.revenue,
  });

  final int rank;
  final String name;
  final String? subtitle;
  final String qty;
  final String? saleCount;
  final String? revenue;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = const Color(0xFFC9A227);
    } else if (rank == 2) {
      badgeColor = const Color(0xFF9E9E9E);
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32);
    } else {
      badgeColor = AppTheme.primary.withValues(alpha: 0.15);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: badgeColor.withValues(alpha: rank <= 3 ? 1 : 0.5),
        foregroundColor: rank <= 3 ? Colors.white : AppTheme.primary,
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          ?subtitle,
          ?revenue,
          if (saleCount != null && saleCount!.isNotEmpty) '$saleCount ventes',
        ].join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '× $qty',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ReportMetric {
  const _ReportMetric(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({required this.metric});

  final _ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: metric.highlight
            ? AppTheme.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: metric.highlight
              ? AppTheme.accent.withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 18, color: metric.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: TextStyle(
              fontSize: metric.highlight ? 17 : 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CashierSaleTile extends StatelessWidget {
  const _CashierSaleTile({
    required this.name,
    required this.transactions,
    this.revenue,
  });

  final String name;
  final String transactions;
  final String? revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$transactions ${AppLocalizations.of(context)!.transactions}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (revenue != null)
            Text(
              revenue!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodComparisonPanel extends StatelessWidget {
  const _PeriodComparisonPanel({
    required this.pct,
    required this.currentRevenue,
    required this.previousRevenue,
    required this.currentTransactions,
    required this.previousTransactions,
    required this.currentLabel,
    required this.previousLabel,
    required this.evolutionLabel,
  });

  final double pct;
  final String currentRevenue;
  final String previousRevenue;
  final String currentTransactions;
  final String previousTransactions;
  final String currentLabel;
  final String previousLabel;
  final String evolutionLabel;

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    final color = up ? const Color(0xFF2E7D32) : const Color(0xFFB00020);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                up ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                evolutionLabel,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              Text(
                '${up ? '+' : ''}${pct.toStringAsFixed(1)} %',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PeriodBox(
                title: currentLabel,
                revenue: currentRevenue,
                transactions: currentTransactions,
                accent: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PeriodBox(
                title: previousLabel,
                revenue: previousRevenue,
                transactions: previousTransactions,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodBox extends StatelessWidget {
  const _PeriodBox({
    required this.title,
    required this.revenue,
    required this.transactions,
    this.accent = false,
  });

  final String title;
  final String revenue;
  final String transactions;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.accent.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent
              ? AppTheme.accent.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            revenue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            transactions,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
