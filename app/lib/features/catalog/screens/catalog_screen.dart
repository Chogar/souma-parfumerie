import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/catalog/data/catalog_repository.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _repo = CatalogRepository();
  final _search = TextEditingController();
  List<ProductModel> _products = [];
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
    _products = await _repo.listProducts(search: _search.text);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isManager = context.watch<AuthProvider>().user?.isManager ?? false;
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = _products[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${p.stockQuantity}'),
                            ),
                            title: Text(p.displayName(locale)),
                            subtitle: Text(
                              '${p.barcode} • ${p.brand ?? ''} ${p.volumeMl != null ? '${p.volumeMl}ml' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${fmt.format(p.salePrice)} ${AppConfig.currencySymbol}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (isManager)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editPrice(context, p),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPrice(BuildContext context, ProductModel p) async {
    final ctrl = TextEditingController(text: p.salePrice.toStringAsFixed(0));
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.price),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok == true) {
      await _repo.updatePrice(p.id, double.tryParse(ctrl.text) ?? p.salePrice);
      await _load();
    }
  }
}
