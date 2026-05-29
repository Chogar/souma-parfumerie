import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/features/sales/widgets/pending_return_detail_dialog.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Liste des retours en attente de validation (manager).
class PendingReturnsPanel extends StatefulWidget {
  const PendingReturnsPanel({
    super.key,
    required this.managerId,
    required this.onChanged,
  });

  final String managerId;
  final VoidCallback onChanged;

  @override
  State<PendingReturnsPanel> createState() => _PendingReturnsPanelState();
}

class _PendingReturnsPanelState extends State<PendingReturnsPanel> {
  final _repo = SaleReturnsRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.listPendingReturns();
    setState(() {});
  }

  String _returnError(AppLocalizations l10n, Object e) {
    if (e is SaleReturnException) {
      switch (e.code) {
        case SaleReturnsRepository.codeMigrationRequired:
          return l10n.saleReturnMigrationRequired;
        case SaleReturnsRepository.codeNotPending:
          return l10n.saleReturnNotPending;
        case SaleReturnsRepository.codeForbidden:
          return l10n.saleReturnForbidden;
        default:
          return l10n.saleReturnFailed;
      }
    }
    return '$e';
  }

  Future<void> _openDetail(String saleId) async {
    await showPendingReturnDetailDialog(
      context: context,
      saleId: saleId,
      repo: _repo,
    );
  }

  Future<void> _approve(String saleId) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showPendingReturnDetailDialog(
      context: context,
      saleId: saleId,
      repo: _repo,
    );
    if (action != PendingReturnDialogAction.approve) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmApproveReturn),
        content: Text(l10n.confirmApproveReturnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.approveReturn),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repo.approveReturn(
        saleId: saleId,
        managerId: widget.managerId,
      );
      _reload();
      widget.onChanged();
      if (mounted) bumpAppRefresh(context);
      if (mounted) AppNotifier.success(l10n.saleReturnApproved);
    } catch (e) {
      if (mounted) AppNotifier.error(_returnError(l10n, e));
    }
  }

  Future<void> _reject(String saleId) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showPendingReturnDetailDialog(
      context: context,
      saleId: saleId,
      repo: _repo,
    );
    if (action != PendingReturnDialogAction.reject) return;
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmRejectReturn),
        content: Text(l10n.confirmRejectReturnBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.rejectReturn),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _repo.rejectReturn(
        saleId: saleId,
        managerId: widget.managerId,
      );
      _reload();
      widget.onChanged();
      if (mounted) bumpAppRefresh(context);
      if (mounted) AppNotifier.success(l10n.saleReturnRejected);
    } catch (e) {
      if (mounted) AppNotifier.error(_returnError(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final pending = snap.data!;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_return, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.pendingReturnsTitle(pending.length),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...pending.map((s) {
                  final saleId = s['id'] as String;
                  final total = s['total'];
                  final amount = total is num
                      ? total.toDouble()
                      : double.tryParse('$total') ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PendingReturnTile(
                        saleId: saleId,
                        sale: s,
                        repo: _repo,
                        l10n: l10n,
                        amount: amount,
                        fmt: _fmt,
                        onTap: () => _openDetail(saleId),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openDetail(saleId),
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: Text(l10n.viewReturnDetail),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _reject(saleId),
                            child: Text(l10n.rejectReturn),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: () => _approve(saleId),
                            child: Text(l10n.approveReturn),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingReturnTile extends StatelessWidget {
  const _PendingReturnTile({
    required this.saleId,
    required this.sale,
    required this.repo,
    required this.l10n,
    required this.amount,
    required this.fmt,
    this.onTap,
  });

  final String saleId;
  final Map<String, dynamic> sale;
  final SaleReturnsRepository repo;
  final AppLocalizations l10n;
  final double amount;
  final NumberFormat fmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.pendingReturnLineItems(saleId),
      builder: (context, snap) {
        final lines = snap.data ?? [];
        final linesSummary = lines.isEmpty
            ? null
            : lines
                .map(
                  (l) =>
                      '• ${l['name_fr'] ?? l['name_ar'] ?? '—'}: ${l['quantity_to_return']}/${l['quantity_sold']}',
                )
                .join('\n');

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${sale['invoice_number']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${sale['cashier_name']} • ${sale['return_requester_name'] ?? ''}\n'
            '${sale['return_reason'] ?? l10n.saleReturnNoReason}'
            '${linesSummary != null ? '\n$linesSummary' : ''}',
          ),
          isThreeLine: true,
          trailing: Text(
            '${fmt.format(amount)} ${AppConfig.currencySymbol}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: onTap,
        );
      },
    );
  }
}
