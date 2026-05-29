import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/dashboard/data/dashboard_repository.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Bandeau d'accueil + indicateurs du jour (pleine largeur de la zone contenu).
class DailyKpiStrip extends StatefulWidget {
  const DailyKpiStrip({super.key});

  @override
  State<DailyKpiStrip> createState() => _DailyKpiStripState();
}

class _DailyKpiStripState extends State<DailyKpiStrip> with AutoRefreshMixin {
  final _repo = DashboardRepository();
  final _returnsRepo = SaleReturnsRepository();
  final _dayKeyFmt = DateFormat('yyyy-MM-dd');
  String? _loadedDay;
  Future<Map<String, dynamic>>? _statsFuture;
  Future<int>? _lowStockFuture;
  Future<Map<String, dynamic>>? _returnsFuture;

  void _reloadIfNewDay(AppPermissions perms, String? scopeId) {
    final today = _dayKeyFmt.format(DateTime.now());
    if (_loadedDay == today && _statsFuture != null) return;
    _loadedDay = today;
    _statsFuture = _repo.todayStats(
      includeFinancial: perms.canViewGlobalRevenue || perms.scopeOwnSalesOnly,
      onlyUserId: scopeId,
    );
    _lowStockFuture = _repo.lowStockCount();
    _returnsFuture = perms.canViewSalesHistory
        ? _returnsRepo.returnDailySummary(onlyUserId: scopeId)
        : null;
  }

  @override
  void onAutoRefresh() {
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final scopeId = perms.scopeOwnSalesOnly ? user.id : null;
    setState(() {
      _loadedDay = null;
      _statsFuture = null;
      _lowStockFuture = null;
      _returnsFuture = null;
    });
    _reloadIfNewDay(perms, scopeId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final scopeId = perms.scopeOwnSalesOnly ? user.id : null;
    _reloadIfNewDay(perms, scopeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return SelectionContainer.disabled(
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: FutureBuilder(
              future: Future.wait([
                _statsFuture!,
                _lowStockFuture!,
                ?_returnsFuture,
              ]),
              builder: (context, snap) {
                final stats = snap.data != null
                    ? snap.data![0] as Map<String, dynamic>
                    : <String, dynamic>{};
                final lowStock =
                    snap.data != null ? snap.data![1] as int : 0;
                final returns = snap.data != null && _returnsFuture != null
                    ? snap.data![2] as Map<String, dynamic>
                    : <String, dynamic>{};
                final returnsToday = returns['returns_today'] is int
                    ? returns['returns_today'] as int
                    : int.tryParse('${returns['returns_today']}') ?? 0;

                final tiles = <_KpiTileData>[
                  if (perms.canViewGlobalRevenue || perms.scopeOwnSalesOnly)
                    _KpiTileData(
                      perms.scopeOwnSalesOnly
                          ? l10n.myDailySales
                          : l10n.dailySales,
                      snap.hasData
                          ? '${fmt.format(_num(stats['revenue']))} ${AppConfig.currencySymbol}'
                          : '—',
                      Icons.payments,
                    ),
                  _KpiTileData(
                    l10n.transactions,
                    snap.hasData ? '${stats['transactions'] ?? 0}' : '—',
                    Icons.receipt_long,
                  ),
                  if (perms.canViewGlobalRevenue || perms.scopeOwnSalesOnly)
                    _KpiTileData(
                      l10n.averageBasket,
                      snap.hasData
                          ? '${fmt.format(_num(stats['avg_basket']))} ${AppConfig.currencySymbol}'
                          : '—',
                      Icons.shopping_bag,
                    ),
                  _KpiTileData(
                    l10n.lowStock,
                    snap.hasData ? '$lowStock' : '—',
                    Icons.warning_amber,
                    highlight: lowStock > 0,
                  ),
                  if (perms.canViewSalesHistory)
                    _KpiTileData(
                      l10n.dashboardReturnsToday,
                      snap.hasData ? '$returnsToday' : '—',
                      Icons.assignment_return_outlined,
                      highlight: returnsToday > 0,
                    ),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.welcome}, ${user.fullName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.isManager
                          ? l10n.dashboardManager
                          : l10n.dashboardGestionnaire,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 14),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0)
                              const VerticalDivider(width: 1, thickness: 1),
                            Expanded(child: _KpiTile(data: tiles[i])),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class _KpiTileData {
  const _KpiTileData(
    this.label,
    this.value,
    this.icon, {
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.data});

  final _KpiTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      color: data.highlight
          ? Colors.orange.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(data.icon, size: 22, color: const Color(0xFFC9A227)),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
