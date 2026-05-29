import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/features/sales/widgets/pending_returns_panel.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Historique de toutes les demandes de retour.
class SaleReturnsHistoryScreen extends StatefulWidget {
  const SaleReturnsHistoryScreen({super.key});

  @override
  State<SaleReturnsHistoryScreen> createState() =>
      _SaleReturnsHistoryScreenState();
}

class _SaleReturnsHistoryScreenState extends State<SaleReturnsHistoryScreen>
    with AutoRefreshMixin {
  final _repo = SaleReturnsRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  String? _statusFilter;
  int _reloadTick = 0;

  void _reload() => setState(() => _reloadTick++);

  @override
  void onAutoRefresh() => _reload();

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'pending':
        return l10n.saleReturnPending;
      case 'approved':
        return l10n.saleReturnApproved;
      case 'rejected':
        return l10n.saleReturnRejected;
      default:
        return status ?? '—';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE65100);
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFB00020);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final onlyUserId = perms.scopeOwnSalesOnly ? user.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (perms.canApproveSaleReturn)
          PendingReturnsPanel(
            managerId: user.id,
            onChanged: _reload,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: l10n.saleReturnFilterAll,
              selected: _statusFilter == null,
              onTap: () => setState(() => _statusFilter = null),
            ),
            _FilterChip(
              label: l10n.saleReturnFilterPending,
              selected: _statusFilter == 'pending',
              onTap: () => setState(() => _statusFilter = 'pending'),
            ),
            _FilterChip(
              label: l10n.saleReturnFilterApproved,
              selected: _statusFilter == 'approved',
              onTap: () => setState(() => _statusFilter = 'approved'),
            ),
            _FilterChip(
              label: l10n.saleReturnFilterRejected,
              selected: _statusFilter == 'rejected',
              onTap: () => setState(() => _statusFilter = 'rejected'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('returns-$_reloadTick-$_statusFilter'),
            future: _repo.listReturnHistory(
              onlyUserId: onlyUserId,
              statusFilter: _statusFilter,
            ),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              final rows = snap.data ?? [];
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    l10n.saleReturnsEmpty,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final status = r['return_status']?.toString();
                    final requestedAt = r['return_requested_at'];
                    final approvedAt = r['return_approved_at'];
                    DateTime? dt;
                    if (approvedAt != null) {
                      dt = approvedAt is DateTime
                          ? approvedAt
                          : DateTime.tryParse('$approvedAt');
                    }
                    dt ??= requestedAt is DateTime
                        ? requestedAt
                        : DateTime.tryParse('$requestedAt');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            _statusColor(status).withValues(alpha: 0.12),
                        child: Icon(
                          Icons.assignment_return_outlined,
                          color: _statusColor(status),
                          size: 22,
                        ),
                      ),
                      title: Text(
                        r['invoice_number']?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.saleReturnRequestedBy}: ${r['return_requester_name'] ?? r['cashier_name'] ?? '—'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (r['return_reason'] != null &&
                              '${r['return_reason']}'.trim().isNotEmpty)
                            Text(
                              '${l10n.saleReturnReason}: ${r['return_reason']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (dt != null)
                            Text(
                              '${l10n.saleReturnProcessedAt}: ${_dateFmt.format(dt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel(l10n, status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                          if (perms.canViewFinancialReports) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_fmt.format(_num(r['total']))} ${AppConfig.currencySymbol}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.accent.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
    );
  }
}
