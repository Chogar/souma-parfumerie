import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_header.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_layout.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/dashboard/data/dashboard_repository.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutoRefreshMixin {
  final _repo = DashboardRepository();
  final _returnsRepo = SaleReturnsRepository();
  final _dayKeyFmt = DateFormat('yyyy-MM-dd');
  String? _loadedDay;
  Future<List<Map<String, dynamic>>>? _recentFuture;
  Future<Map<String, dynamic>>? _returnsFuture;

  @override
  void onAutoRefresh() {
    setState(() {
      _loadedDay = null;
      _recentFuture = null;
      _returnsFuture = null;
    });
  }

  void _ensureLoaded(AppPermissions perms, String? scopeUserId) {
    final today = _dayKeyFmt.format(DateTime.now());
    if (_loadedDay == today && _recentFuture != null) return;
    _loadedDay = today;
    _recentFuture = _repo.recentSales(
      onlyUserId: scopeUserId,
      todayOnly: true,
    );
    _returnsFuture = _returnsRepo.returnDailySummary(onlyUserId: scopeUserId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final scopeId = perms.scopeOwnSalesOnly ? user.id : null;

    if (!perms.canViewSalesHistory) {
      return HubPageLayout(
        title: l10n.dashboard,
        subtitle: l10n.dashboardSubtitle,
        icon: Icons.dashboard_rounded,
        body: Center(child: Text(l10n.noData)),
      );
    }

    _ensureLoaded(perms, scopeId);

    return HubPageLayout(
      title: l10n.dashboard,
      subtitle: l10n.dashboardDailySubtitle,
      icon: Icons.dashboard_rounded,
      body: FutureBuilder(
        future: Future.wait([_recentFuture!, _returnsFuture!]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final recent = snap.data![0] as List<Map<String, dynamic>>;
          final returns = snap.data![1] as Map<String, dynamic>;
          final returnsToday = _int(returns['returns_today']);
          final approvedToday = _int(returns['approved_today']);
          final rejectedToday = _int(returns['rejected_today']);
          final fmt = NumberFormat('#,##0', 'fr_FR');
          final todayLabel = DateFormat('EEEE d MMMM', 'fr_FR')
              .format(DateTime.now());

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadedDay = null;
                _recentFuture = null;
                _returnsFuture = null;
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    todayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  HubSectionPanel(
                    title: l10n.dashboardReturnsTitle,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 720
                              ? 3
                              : (c.maxWidth > 400 ? 2 : 1);
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: cols == 1 ? 2.8 : 1.6,
                            children: [
                              _ReturnStatCard(
                                label: l10n.dashboardReturnsToday,
                                value: '$returnsToday',
                                icon: Icons.assignment_return_outlined,
                                color: AppTheme.accent,
                                highlight: returnsToday > 0,
                              ),
                              _ReturnStatCard(
                                label: l10n.dashboardReturnsApprovedToday,
                                value: '$approvedToday',
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF2E7D32),
                              ),
                              _ReturnStatCard(
                                label: l10n.dashboardReturnsRejectedToday,
                                value: '$rejectedToday',
                                icon: Icons.cancel_outlined,
                                color: const Color(0xFFB00020),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  HubSectionPanel(
                    title: l10n.dashboardTodaySales,
                    child: recent.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                l10n.noData,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recent.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = recent[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accent
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  '${r['invoice_number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${r['full_name']} • ${r['sold_at']}',
                                ),
                                trailing: perms.canViewSaleAmounts
                                    ? Text(
                                        '${fmt.format(_num(r['total']))} ${AppConfig.currencySymbol}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

class _ReturnStatCard extends StatelessWidget {
  const _ReturnStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? color.withValues(alpha: 0.35) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
