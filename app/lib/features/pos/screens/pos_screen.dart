import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/utils/barcode_utils.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/core/widgets/hub_page_layout.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/pos/data/pos_repository.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';
import 'package:souma_parfumerie/features/pos/providers/pos_provider.dart';
import 'package:souma_parfumerie/features/pos/services/receipt_print_service.dart';
import 'package:souma_parfumerie/features/pos/widgets/client_phone_field.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with AutoRefreshMixin {
  final _barcodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _posRepo = PosRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');

  List<ProductModel> _catalog = [];
  bool _loadingCatalog = true;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  void onAutoRefresh() => _loadCatalog(silent: true);

  Future<void> _onBarcodeSubmitted() async {
    final code = BarcodeUtils.normalize(_barcodeCtrl.text);
    if (code.isEmpty) {
      await _loadCatalog();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final pos = context.read<PosProvider>();
    await pos.scanBarcode(code);

    if (!mounted) return;

    switch (pos.stockError) {
      case 'not_found':
        await _loadCatalog();
        if (mounted) {
          AppNotifier.warning(l10n.productNotFound, context: context);
        }
        break;
      case 'outOfStock':
        await _loadCatalog();
        if (mounted) {
          AppNotifier.warning(l10n.outOfStock, context: context);
        }
        break;
      case 'stockAlert':
        if (mounted) {
          AppNotifier.warning(l10n.stockAlert, context: context);
        }
        break;
      case 'expired':
        if (mounted) {
          AppNotifier.warning(l10n.productExpired, context: context);
        }
        break;
      default:
        _barcodeCtrl.clear();
        await _loadCatalog(silent: true);
        break;
    }
  }

  Future<void> _loadCatalog({bool silent = false}) async {
    if (!silent) setState(() => _loadingCatalog = true);
    try {
      final results = await _posRepo.listProductsForPos(
        query: BarcodeUtils.normalize(_barcodeCtrl.text),
      );
      if (!mounted) return;
      setState(() {
        _catalog = results;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  void _applyLocalStockFromSale(SaleReceipt receipt) {
    for (final line in receipt.lines) {
      final i = _catalog.indexWhere((p) => p.id == line.product.id);
      if (i < 0) continue;
      final p = _catalog[i];
      _catalog[i] = ProductModel(
        id: p.id,
        barcode: p.barcode,
        nameFr: p.nameFr,
        nameAr: p.nameAr,
        salePrice: p.salePrice,
        purchasePrice: p.purchasePrice,
        brand: p.brand,
        volumeMl: p.volumeMl,
        stockQuantity: (p.stockQuantity - line.quantity).clamp(0, 999999),
        categoryId: p.categoryId,
        minStockLevel: p.minStockLevel,
        expiresAt: p.expiresAt,
      );
    }
  }

  void _pickProduct(ProductModel product) {
    if (_isValidating) return;
    if (product.stockQuantity <= 0) return;
    final pos = context.read<PosProvider>();
    pos.addProduct(product);
  }

  Future<void> _validate() async {
    if (_isValidating) return;
    final pos = context.read<PosProvider>();
    if (pos.lines.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final locale = context.read<LocaleProvider>().locale.languageCode;

    setState(() => _isValidating = true);

    pos.setPaymentMethod('cash');
    pos.amountPaid = pos.total;

    try {
      final receipt = await pos
          .completeSale(
            auth.user!.id,
            cashierName: auth.user!.fullName,
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (receipt == null) {
        AppNotifier.error(l10n.errorGeneric);
        return;
      }

      _phoneCtrl.clear();
      _applyLocalStockFromSale(receipt);
      setState(() {});
      bumpAppRefresh(context);

      unawaited(
        ReceiptPrintService.presentReceipt(
          receipt,
          language: locale,
        ),
      );

      var msg = '${l10n.saleSuccess}: ${receipt.invoiceNumber}';
      if (receipt.loyaltyGiftEligible) {
        msg = '${l10n.loyaltyGiftReached}\n$msg';
      } else if (receipt.loyaltyStamps != null) {
        msg =
            '${l10n.loyaltyProgress(receipt.loyaltyStamps!, receipt.loyaltyThreshold)}\n$msg';
      }
      AppNotifier.success(msg);
    } on TimeoutException {
      AppNotifier.error(l10n.saleTimeout);
    } catch (e) {
      AppNotifier.error('${l10n.errorGeneric}\n$e');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return HubPageLayout(
      title: l10n.pos,
      subtitle: l10n.posSubtitle,
      icon: Icons.point_of_sale_rounded,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildCatalogPanel(l10n, locale)),
          _CartPanel(
            phoneCtrl: _phoneCtrl,
            isValidating: _isValidating,
            onValidate: _validate,
            fmt: _fmt,
            locale: locale,
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPanel(AppLocalizations l10n, String locale) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _barcodeCtrl,
            autofocus: true,
            enabled: !_isValidating,
            decoration: InputDecoration(
              labelText: l10n.scanBarcode,
              hintText: l10n.barcodeHint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _loadingCatalog ? null : () => _loadCatalog(),
              ),
            ),
            onSubmitted: (_) => _onBarcodeSubmitted(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.inStockProducts,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            l10n.tapToAddProduct,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loadingCatalog
                ? const Center(child: CircularProgressIndicator())
                : _catalog.isEmpty
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _barcodeCtrl.text.trim().isEmpty
                              ? l10n.posCatalogEmpty
                              : l10n.productNotFound,
                        ),
                      )
                    : Card(
                        child: ListView.separated(
                          itemCount: _catalog.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = _catalog[i];
                            final inStock = p.stockQuantity > 0;
                            return ListTile(
                              enabled: inStock && !_isValidating,
                              title: Text(p.displayName(locale)),
                              subtitle: Text(
                                '${p.barcode} • ${l10n.quantity}: ${p.stockQuantity} • ${_fmt.format(p.salePrice)} ${AppConfig.currencySymbol}',
                              ),
                              trailing: Icon(
                                Icons.add_shopping_cart,
                                color: inStock
                                    ? const Color(0xFFC9A227)
                                    : Colors.grey,
                              ),
                              onTap:
                                  inStock ? () => _pickProduct(p) : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Panier isolé : seul ce widget se reconstruit quand le panier change.
class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.phoneCtrl,
    required this.isValidating,
    required this.onValidate,
    required this.fmt,
    required this.locale,
  });

  final TextEditingController phoneCtrl;
  final bool isValidating;
  final VoidCallback onValidate;
  final NumberFormat fmt;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Selector<PosProvider, _CartViewModel>(
      selector: (_, pos) => _CartViewModel(
        lines: pos.lines,
        subtotal: pos.subtotal,
        total: pos.total,
      ),
      builder: (context, cart, _) {
        final pos = context.read<PosProvider>();

        return Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.cart,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cart.lines.isEmpty
                    ? Center(
                        child: Text(
                          l10n.emptyCart,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : Card(
                        margin: EdgeInsets.zero,
                        child: ListView.separated(
                          itemCount: cart.lines.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final line = cart.lines[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                line.product.displayName(locale),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${fmt.format(line.product.salePrice)} ${AppConfig.currencySymbol}',
                              ),
                              trailing: SizedBox(
                                width: 120,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: isValidating
                                          ? null
                                          : () => pos.updateQuantity(
                                                line.product.id,
                                                line.quantity - 1,
                                              ),
                                    ),
                                    Text('${line.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: isValidating
                                          ? null
                                          : () => pos.updateQuantity(
                                                line.product.id,
                                                line.quantity + 1,
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const Divider(height: 24),
              _row(l10n.subtotal, cart.subtotal, fmt),
              _row(l10n.total, cart.total, fmt, bold: true),
              const SizedBox(height: 12),
              ClientPhoneField(
                controller: phoneCtrl,
                enabled: !isValidating,
                onPhoneChanged: (phone) => pos.setClientPhone(phone),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isValidating
                    ? null
                    : () {
                        pos.clearCart();
                      },
                child: Text(l10n.clearCart),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    cart.lines.isEmpty || isValidating ? null : onValidate,
                child: isValidating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.validatingSale),
                        ],
                      )
                    : Text(l10n.validateSale),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _row(
    String label,
    double value,
    NumberFormat fmt, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            '${fmt.format(value)} ${AppConfig.currencySymbol}',
            style: bold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                : null,
          ),
        ],
      ),
    );
  }
}

class _CartViewModel {
  const _CartViewModel({
    required this.lines,
    required this.subtotal,
    required this.total,
  });

  final List<CartLine> lines;
  final double subtotal;
  final double total;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _CartViewModel) return false;
    if (other.lines.length != lines.length ||
        other.subtotal != subtotal ||
        other.total != total) {
      return false;
    }
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].product.id != other.lines[i].product.id ||
          lines[i].quantity != other.lines[i].quantity) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(subtotal, total, lines.length);
}
