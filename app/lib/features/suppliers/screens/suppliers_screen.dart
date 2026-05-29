import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/suppliers/data/suppliers_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _repo = SuppliersRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _repo.list(search: _search.text);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([Map<String, dynamic>? supplier]) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = supplier != null;
    final name = TextEditingController(text: supplier?['name']?.toString());
    final phone = TextEditingController(text: supplier?['phone']?.toString());
    final email = TextEditingController(text: supplier?['email']?.toString());
    final address =
        TextEditingController(text: supplier?['address']?.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? l10n.editSupplier : l10n.addSupplier),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.supplierName),
                autofocus: true,
              ),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: l10n.storePhone),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: l10n.storeEmail),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: address,
                decoration: InputDecoration(labelText: l10n.storeAddress),
                maxLines: 2,
              ),
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

    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await _repo.upsert(
          id: supplier?['id'] as String?,
          name: name.text.trim(),
          phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
          email: email.text.trim().isEmpty ? null : email.text.trim(),
          address: address.text.trim().isEmpty ? null : address.text.trim(),
        );
        await _load();
        if (mounted) AppNotifier.success(l10n.save);
      } catch (e) {
        if (mounted) AppNotifier.error('$e');
      }
    }

    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
  }

  Future<void> _deactivate(Map<String, dynamic> s) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteSupplier),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.deactivate(s['id'] as String);
        await _load();
        if (mounted) AppNotifier.success(l10n.delete);
      } catch (e) {
        if (mounted) AppNotifier.error('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);

    if (!perms.canManageSuppliers) {
      return Center(child: Text(l10n.managerOnly));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(width: 8),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              IconButton(
                tooltip: l10n.addSupplier,
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : NumberedDataTable(
                    columns: [
                      NumberedTableColumn(label: l10n.columnNumber),
                      NumberedTableColumn(label: l10n.supplierName),
                      NumberedTableColumn(label: l10n.storePhone),
                      NumberedTableColumn(label: l10n.storeEmail),
                      NumberedTableColumn(label: l10n.storeAddress),
                      NumberedTableColumn(label: l10n.columnActions),
                    ],
                    rowCount: _items.length,
                    emptyMessage: l10n.noData,
                    totalLabel: l10n.tableItemsCount(_items.length),
                    rowBuilder: (context, i, n) {
                      final s = _items[i];
                      return [
                        numberedIndexCell(n),
                        numberedCell(
                          Text(
                            s['name']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        numberedCell(Text(s['phone']?.toString() ?? '—')),
                        numberedCell(Text(s['email']?.toString() ?? '—')),
                        numberedCell(
                          Text(
                            s['address']?.toString() ?? '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          CrudIconActions(
                            editTooltip: l10n.edit,
                            deleteTooltip: l10n.delete,
                            onEdit: () => _edit(s),
                            onDelete: () => _deactivate(s),
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
