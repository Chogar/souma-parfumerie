import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/clients/data/clients_repository.dart';
import 'package:souma_parfumerie/features/clients/widgets/loyalty_card_dialog.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with AutoRefreshMixin {
  final _repo = ClientsRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onAutoRefresh() => _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _clients = await _repo.list(search: _search.text);
    if (mounted) setState(() => _loading = false);
  }

  int _points(Map<String, dynamic> c) {
    final v = c['loyalty_points'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _giftsReceived(Map<String, dynamic> c) {
    final v = c['gifts_received'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _edit([Map<String, dynamic>? client]) async {
    final phone = TextEditingController(text: client?['phone']?.toString());
    final name = TextEditingController(text: client?['name']?.toString());
    final l10n = AppLocalizations.of(context)!;
    final isEdit = client != null;
    final pts = client != null ? _points(client) : 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? l10n.editClient : l10n.addClient),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: l10n.clientPhone),
                keyboardType: TextInputType.phone,
                enabled: !isEdit,
              ),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.clientName),
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.loyaltyProgress(pts, LoyaltyConfig.giftThreshold),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true && phone.text.isNotEmpty) {
      try {
        await _repo.upsert(
          id: client?['id'] as String?,
          phone: phone.text.trim(),
          name: name.text.trim().isEmpty ? null : name.text.trim(),
        );
        await _notifyAndReload();
        if (mounted) AppNotifier.success(l10n.save);
      } catch (e) {
        if (mounted) AppNotifier.error('$e');
      }
    }
    phone.dispose();
    name.dispose();
  }

  Future<void> _showDetail(Map<String, dynamic> client) async {
    final pts = _points(client);
    await showDialog<void>(
      context: context,
      builder: (ctx) => LoyaltyCardDialog(
        client: client,
        loyaltyPoints: pts,
        onEdit: () => _edit(client),
        onGiftOffered: pts >= LoyaltyConfig.giftThreshold
            ? () => _redeemGiftAndReturn(client)
            : null,
      ),
    );
  }

  Future<bool> _redeemGiftAndReturn(Map<String, dynamic> client) async {
    final clientId = client['id']?.toString().trim() ?? '';
    if (clientId.isEmpty) return false;

    final success = await _repo.redeemGift(clientId);
    if (success) {
      final idx = _clients.indexWhere(
        (c) => c['id']?.toString() == clientId,
      );
      if (idx >= 0) {
        setState(() {
          _clients[idx] = Map<String, dynamic>.from(_clients[idx])
            ..['loyalty_points'] = 0
            ..['gifts_received'] = _giftsReceived(_clients[idx]) + 1;
        });
      } else {
        await _load();
      }
      if (mounted) bumpAppRefresh(context);
    } else {
      await _load();
    }
    return success;
  }

  Future<void> _redeemGift(Map<String, dynamic> client) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.giftOffered),
        content: Text(l10n.giftOfferedConfirm),
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
    if (ok == true) {
      final success = await _redeemGiftAndReturn(client);
      if (mounted) {
        if (success) {
          AppNotifier.success(l10n.giftOfferedDone);
        } else {
          AppNotifier.error(l10n.redeemGiftFailed);
        }
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> client) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteClient),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.delete(client['id'] as String);
        await _notifyAndReload();
        if (mounted) AppNotifier.success(l10n.delete);
      } catch (e) {
        if (mounted) AppNotifier.error('$e');
      }
    }
  }

  Future<void> _notifyAndReload() async {
    await _load();
    if (mounted) bumpAppRefresh(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final threshold = LoyaltyConfig.giftThreshold;

    if (!perms.canManageClients) {
      return Center(child: Text(l10n.managerOnly));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: l10n.addClient,
                onPressed: () => _edit(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: NumberedDataTable(
                    columns: [
                      NumberedTableColumn(label: l10n.columnNumber),
                      NumberedTableColumn(label: l10n.clientPhone),
                      NumberedTableColumn(label: l10n.clientName),
                      NumberedTableColumn(label: l10n.loyaltyPoints),
                      NumberedTableColumn(label: l10n.clientGiftsReceived),
                      NumberedTableColumn(label: l10n.columnActions),
                    ],
                    rowCount: _clients.length,
                    emptyMessage: l10n.noData,
                    totalLabel: l10n.tableClientsCount(_clients.length),
                    rowBuilder: (context, i, n) {
                      final c = _clients[i];
                      final pts = _points(c);
                      final giftDue = pts >= threshold;
                      final phone = c['phone']?.toString() ?? '';
                      final name = c['name']?.toString();

                      return [
                        numberedIndexCell(n),
                        numberedCell(
                          InkWell(
                            onTap: () => _showDetail(c),
                            child: Text(
                              phone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationStyle: TextDecorationStyle.dotted,
                              ),
                            ),
                          ),
                        ),
                        numberedCell(
                          Text(name?.isNotEmpty == true ? name! : '—'),
                        ),
                        numberedCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.loyaltyProgress(pts, threshold),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: giftDue
                                      ? AppTheme.accent
                                      : Colors.grey.shade700,
                                  fontWeight: giftDue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (giftDue)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Chip(
                                    label: Text(
                                      l10n.giftEligible,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: AppTheme.accent
                                        .withValues(alpha: 0.15),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        numberedCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _giftsReceived(c) > 0
                                    ? AppTheme.accent.withValues(alpha: 0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_giftsReceived(c)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _giftsReceived(c) > 0
                                      ? AppTheme.primary
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.badge_outlined, size: 20),
                                tooltip: l10n.clients,
                                onPressed: () => _showDetail(c),
                              ),
                              if (giftDue)
                                IconButton(
                                  icon: const Icon(
                                    Icons.redeem_outlined,
                                    size: 20,
                                  ),
                                  tooltip: l10n.giftOffered,
                                  onPressed: () => _redeemGift(c),
                                ),
                              CrudIconActions(
                                editTooltip: l10n.edit,
                                deleteTooltip: l10n.delete,
                                onEdit: () => _edit(c),
                                onDelete: () => _delete(c),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
