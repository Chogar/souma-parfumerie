import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/categories/data/categories_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutoRefreshMixin {
  final _repo = CategoriesRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    _items = await _repo.list();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void onAutoRefresh() => _reload();

  Future<void> _edit([Map<String, dynamic>? cat]) async {
    final fr = TextEditingController(text: cat?['name_fr']?.toString());
    final ar = TextEditingController(text: cat?['name_ar']?.toString());
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categories),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fr,
              decoration: InputDecoration(labelText: l10n.french),
            ),
            TextField(
              controller: ar,
              decoration: InputDecoration(labelText: l10n.arabic),
            ),
          ],
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
    if (ok == true) {
      try {
        await _repo.save(
          id: cat?['id'] as String?,
          nameFr: fr.text.trim(),
          nameAr: ar.text.trim(),
        );
        if (!mounted) return;
        await _reload();
        if (!mounted) return;
        bumpAppRefresh(context);
        AppNotifier.success(l10n.save);
      } catch (e) {
        if (mounted) AppNotifier.error('$e');
      }
    }
    fr.dispose();
    ar.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);

    if (!perms.canManageCategories) {
      return Center(child: Text(l10n.managerOnly));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
              ElevatedButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: Text(l10n.categories),
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
                      NumberedTableColumn(label: l10n.french),
                      NumberedTableColumn(label: l10n.arabic),
                      NumberedTableColumn(label: l10n.columnActions),
                    ],
                    rowCount: _items.length,
                    emptyMessage: l10n.noData,
                    totalLabel: l10n.tableItemsCount(_items.length),
                    rowBuilder: (context, i, n) {
                      final c = _items[i];
                      return [
                        numberedIndexCell(n),
                        numberedCell(
                          Text(
                            c['name_fr']?.toString() ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        numberedCell(Text(c['name_ar']?.toString() ?? '—')),
                        DataCell(
                          CrudIconActions(
                            editTooltip: l10n.edit,
                            onEdit: () => _edit(c),
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
