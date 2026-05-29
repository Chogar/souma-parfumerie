import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/app_shell_navigation.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_layout.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/alerts/data/alerts_repository.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/catalog/data/catalog_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin, AutoRefreshMixin {
  final _repo = AlertsRepository();
  final _catalogRepo = CatalogRepository();
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _lowStockFuture;
  late Future<List<Map<String, dynamic>>> _expiryFuture;
  String? _highlightProductId;
  AppShellNavigation? _shellNav;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<AppShellNavigation>();
    if (_shellNav != nav) {
      _shellNav?.removeListener(_onShellNavigation);
      _shellNav = nav;
      _shellNav!.addListener(_onShellNavigation);
      _applyShellNavigation(animate: false);
    }
  }

  @override
  void dispose() {
    _shellNav?.removeListener(_onShellNavigation);
    _tabController.dispose();
    super.dispose();
  }

  void _onShellNavigation() => _applyShellNavigation(animate: true);

  void _applyShellNavigation({required bool animate}) {
    final nav = context.read<AppShellNavigation>();
    final tab = nav.takePendingAlertsTab();
    final productId = nav.takePendingProductId();
    if (tab == null && productId == null) return;
    if (tab != null) {
      if (animate) {
        _tabController.animateTo(tab.clamp(0, 1));
      } else {
        _tabController.index = tab.clamp(0, 1);
      }
    }
    if (productId != null) {
      setState(() => _highlightProductId = productId);
    }
  }

  void _reload() {
    _lowStockFuture = _repo.lowStock();
    _expiryFuture = _repo.expiringSoon(withinDays: 30);
    setState(() {});
  }

  @override
  void onAutoRefresh() => _reload();

  Future<void> _clearExpiredStock(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context)!;
    final user = context.read<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    if (!perms.canManageProducts) {
      AppNotifier.warning(l10n.managerOnly);
      return;
    }
    final productId = row['id']?.toString();
    if (productId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeExpiredStock),
        content: Text(l10n.removeExpiredStockConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _catalogRepo.clearExpiredStock(
        productId: productId,
        userId: user.id,
      );
      if (mounted) {
        AppNotifier.success(l10n.removeExpiredStockDone);
        setState(() {
          if (_highlightProductId == productId) _highlightProductId = null;
        });
        _reload();
        bumpAppRefresh(context);
      }
    } catch (e) {
      if (mounted) AppNotifier.error('$e');
    }
  }

  bool _isExpired(Map<String, dynamic> r) {
    final daysLeft = r['days_left'];
    if (daysLeft is int) return daysLeft < 0;
    if (daysLeft is num) return daysLeft < 0;
    final raw = r['expires_at'];
    final dt = raw is DateTime
        ? raw
        : DateTime.tryParse(raw?.toString() ?? '');
    if (dt == null) return false;
    final today = DateTime.now();
    final exp = DateTime(dt.year, dt.month, dt.day);
    final now = DateTime(today.year, today.month, today.day);
    return exp.isBefore(now);
  }

  int _quantity(Map<String, dynamic> r) {
    final q = r['quantity'];
    if (q is int) return q;
    if (q is num) return q.toInt();
    return int.tryParse('$q') ?? 0;
  }

  String _productName(Map<String, dynamic> r, String locale) {
    final name = locale.startsWith('ar') ? r['name_ar'] : r['name_fr'];
    return name?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final dateFmt = DateFormat.yMMMd(locale.startsWith('ar') ? 'ar' : 'fr');
    final user = context.watch<AuthProvider>().user!;
    final canRemoveStock =
        AppPermissions(user, user.permissions).canManageProducts;

    return HubTabbedLayout(
      title: l10n.alerts,
      subtitle: l10n.alertsSubtitle,
      icon: Icons.notifications_active_rounded,
      tabController: _tabController,
      tabs: [
        HubTab(label: l10n.lowStockTab, icon: Icons.warning_amber_outlined),
        HubTab(label: l10n.expiryTab, icon: Icons.event_busy_outlined),
      ],
      children: [
        _NumberedAlertTable(
          future: _lowStockFuture,
          emptyMessage: l10n.noLowStock,
          onRefresh: _reload,
          l10n: l10n,
          columns: [
            NumberedTableColumn(label: l10n.columnNumber),
            NumberedTableColumn(label: l10n.barcode),
            NumberedTableColumn(label: l10n.nameFr),
            NumberedTableColumn(label: l10n.stock, numeric: true),
            NumberedTableColumn(label: l10n.columnMinStock, numeric: true),
          ],
          rowBuilder: (ctx, r, n) {
            final qty = r['quantity'] ?? 0;
            final min = r['min_stock_level'] ?? 5;
            return [
              numberedIndexCell(n),
              numberedCell(
                SelectableText(
                  r['barcode']?.toString() ?? '—',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              numberedCell(Text(_productName(r, locale))),
              numberedCell(
                Text(
                  '$qty',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                alignment: Alignment.center,
              ),
              numberedCell(
                Text('$min'),
                alignment: Alignment.center,
              ),
            ];
          },
        ),
        _NumberedAlertTable(
          future: _expiryFuture,
          emptyMessage: l10n.noExpiryAlert,
          onRefresh: _reload,
          l10n: l10n,
          columns: [
            NumberedTableColumn(label: l10n.columnNumber),
            NumberedTableColumn(label: l10n.barcode),
            NumberedTableColumn(label: l10n.nameFr),
            NumberedTableColumn(label: l10n.stock, numeric: true),
            NumberedTableColumn(label: l10n.expiresOn),
            NumberedTableColumn(label: l10n.columnDaysLeft, numeric: true),
            if (canRemoveStock)
              NumberedTableColumn(label: l10n.columnActions),
          ],
          rowBuilder: (ctx, r, n) {
            final expires = r['expires_at'];
            DateTime? dt;
            if (expires is DateTime) {
              dt = expires;
            } else if (expires != null) {
              dt = DateTime.tryParse(expires.toString());
            }
            final daysLeft = r['days_left'];
            final expired = _isExpired(r);
            final qty = _quantity(r);
            final productId = r['id']?.toString();
            final highlighted =
                productId != null && productId == _highlightProductId;

            final cells = <DataCell>[
              numberedIndexCell(n),
              numberedCell(
                SelectableText(
                  r['barcode']?.toString() ?? '—',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              numberedCell(
                Row(
                  children: [
                    Expanded(child: Text(_productName(r, locale))),
                    if (highlighted)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                      ),
                  ],
                ),
              ),
              numberedCell(
                Text('$qty'),
                alignment: Alignment.center,
              ),
              numberedCell(
                Text(dt != null ? dateFmt.format(dt) : '—'),
              ),
              numberedCell(
                Text(
                  expired
                      ? l10n.expired
                      : (daysLeft != null ? '${daysLeft}j' : '—'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: expired ? Colors.red : Colors.orange.shade800,
                  ),
                ),
                alignment: Alignment.center,
              ),
            ];
            if (canRemoveStock) {
              cells.add(
                DataCell(
                  expired && qty > 0
                      ? IconButton(
                          icon: const Icon(Icons.inventory_2_outlined, size: 20),
                          tooltip: l10n.removeExpiredStock,
                          onPressed: () => _clearExpiredStock(r),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }
            return cells;
          },
        ),
      ],
    );
  }
}

class _NumberedAlertTable extends StatelessWidget {
  const _NumberedAlertTable({
    required this.future,
    required this.emptyMessage,
    required this.l10n,
    required this.columns,
    required this.rowBuilder,
    this.onRefresh,
  });

  final Future<List<Map<String, dynamic>>> future;
  final String emptyMessage;
  final AppLocalizations l10n;
  final List<NumberedTableColumn> columns;
  final List<DataCell> Function(
    BuildContext context,
    Map<String, dynamic> row,
    int number,
  ) rowBuilder;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onRefresh != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context)
                    .refreshIndicatorSemanticLabel,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data!;
              if (rows.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(emptyMessage),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: NumberedDataTable(
                  columns: columns,
                  rowCount: rows.length,
                  totalLabel: l10n.tableItemsCount(rows.length),
                  rowBuilder: (ctx, i, n) => rowBuilder(ctx, rows[i], n),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
