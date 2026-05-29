import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/app_shell_navigation.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/crud_icon_actions.dart';
import 'package:souma_parfumerie/core/widgets/numbered_data_table.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/catalog/data/catalog_repository.dart';
import 'package:souma_parfumerie/features/catalog/widgets/product_form_dialog.dart';
import 'package:souma_parfumerie/features/categories/data/categories_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with AutoRefreshMixin {
  final _repo = CatalogRepository();
  final _categoriesRepo = CategoriesRepository();
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

  @override
  void onAutoRefresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    _products = await _repo.listProducts(search: _search.text);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _notifyAndReload() async {
    await _load();
    if (mounted) bumpAppRefresh(context);
  }

  Future<void> _confirmDelete(ProductModel p) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeleteProduct),
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
      await _repo.deactivateProduct(p.id);
      await _notifyAndReload();
    }
  }

  Future<void> _showProductForm({ProductModel? product}) async {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = product != null;
    final categories = await _categoriesRepo.list();
    if (!mounted) return;
    if (categories.isEmpty) {
      AppNotifier.warning(l10n.categories);
      return;
    }

    final data = await ProductFormDialog.show(
      context,
      categories: categories,
      product: product,
    );
    if (data == null || !mounted) return;

    try {
      final existing = product;
      if (isEdit && existing != null) {
        await _repo.updateProduct(
          id: existing.id,
          categoryId: data.categoryId,
          barcode: CatalogRepository.resolveBarcode(data.barcode),
          nameFr: data.nameFr,
          nameAr: data.nameAr,
          salePrice: data.salePrice,
          purchasePrice: data.purchasePrice,
          brand: data.brand,
          volumeMl: data.volumeMl,
          minStockLevel: data.minStockLevel,
          expiresAt: data.expiresAt,
          stockQuantity: data.stockQuantity,
        );
      } else {
        await _repo.createProduct(
          categoryId: data.categoryId,
          barcode: CatalogRepository.resolveBarcode(data.barcode),
          nameFr: data.nameFr,
          nameAr: data.nameAr,
          salePrice: data.salePrice,
          purchasePrice: data.purchasePrice,
          brand: data.brand,
          volumeMl: data.volumeMl,
          initialStock: data.stockQuantity ?? 0,
          minStockLevel: data.minStockLevel,
          expiresAt: data.expiresAt,
        );
      }
      if (mounted) {
        AppNotifier.success(l10n.save);
        await _notifyAndReload();
      }
    } catch (e) {
      if (mounted) AppNotifier.error('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final canWrite = perms.canManageProducts;

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
              if (canWrite)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.addProduct,
                  onPressed: () => _showProductForm(),
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
                      NumberedTableColumn(label: l10n.barcode),
                      NumberedTableColumn(label: l10n.nameFr),
                      NumberedTableColumn(label: l10n.category),
                      NumberedTableColumn(label: l10n.brand),
                      NumberedTableColumn(
                        label: l10n.stock,
                        numeric: true,
                      ),
                      NumberedTableColumn(
                        label: l10n.price,
                        numeric: true,
                      ),
                      if (canWrite)
                        NumberedTableColumn(label: l10n.columnActions),
                    ],
                    rowCount: _products.length,
                    emptyMessage: l10n.noData,
                    totalLabel: l10n.tableProductsCount(_products.length),
                    rowBuilder: (context, i, n) {
                      final p = _products[i];
                      final expiry = p.expiresAt != null
                          ? DateFormat('dd/MM/yyyy').format(p.expiresAt!)
                          : null;
                      final expired = p.isExpired;
                      final cat = p.categoryName(locale) ?? '—';

                      final statusChips = <Widget>[];
                      if (expired) {
                        statusChips.add(
                          _statusChip(l10n.expired, Colors.red),
                        );
                      } else if (p.isLowStock) {
                        statusChips.add(
                          _statusChip(l10n.lowStock, Colors.orange),
                        );
                      }

                      return [
                        numberedIndexCell(n),
                        numberedCell(
                          SelectableText(
                            p.barcode,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        numberedCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.displayName(locale),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (expiry != null)
                                Text(
                                  '${l10n.expiryDate}: $expiry',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              if (statusChips.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: statusChips,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        numberedCell(Text(cat)),
                        numberedCell(Text(p.brand ?? '—')),
                        numberedCell(
                          Text(
                            '${p.stockQuantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: expired
                                  ? Colors.red.shade700
                                  : p.isLowStock
                                      ? Colors.orange.shade800
                                      : null,
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                        numberedCell(
                          Text(
                            '${fmt.format(p.salePrice)} ${AppConfig.currencySymbol}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          alignment: Alignment.centerRight,
                        ),
                        if (canWrite)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (expired && p.stockQuantity > 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                    ),
                                    tooltip: l10n.removeExpiredStock,
                                    onPressed: () {
                                      context
                                          .read<AppShellNavigation>()
                                          .openAlertsExpiryTab(
                                            productId: p.id,
                                          );
                                    },
                                  ),
                                CrudIconActions(
                                  editTooltip: l10n.edit,
                                  deleteTooltip: l10n.delete,
                                  onEdit: () => _showProductForm(product: p),
                                  onDelete: () => _confirmDelete(p),
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

  Widget _statusChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
