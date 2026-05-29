import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Résultat du formulaire produit (null = annulé).
class ProductFormResult {
  const ProductFormResult({
    required this.categoryId,
    required this.barcode,
    required this.nameFr,
    required this.nameAr,
    required this.salePrice,
    required this.purchasePrice,
    this.brand,
    this.volumeMl,
    this.stockQuantity,
    this.minStockLevel = 5,
    this.expiresAt,
  });

  final String categoryId;
  final String barcode;
  final String nameFr;
  final String nameAr;
  final double salePrice;
  final double purchasePrice;
  final String? brand;
  final int? volumeMl;
  final int? stockQuantity;
  final int minStockLevel;
  final DateTime? expiresAt;
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    required this.categories,
    required this.isEdit,
    this.product,
  });

  final List<Map<String, dynamic>> categories;
  final bool isEdit;
  final ProductModel? product;

  static Future<ProductFormResult?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> categories,
    ProductModel? product,
  }) {
    return showDialog<ProductFormResult>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => ProductFormDialog(
        categories: categories,
        isEdit: product != null,
        product: product,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcode;
  late final TextEditingController _nameFr;
  late final TextEditingController _nameAr;
  late final TextEditingController _brand;
  late final TextEditingController _volume;
  late final TextEditingController _purchase;
  late final TextEditingController _sale;
  late final TextEditingController _stock;
  late final TextEditingController _minAlert;
  late final TextEditingController _expiry;

  late String? _categoryId;
  DateTime? _pickedExpiry;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _barcode = TextEditingController(text: p?.barcode);
    _nameFr = TextEditingController(text: p?.nameFr);
    _nameAr = TextEditingController(text: p?.nameAr);
    _brand = TextEditingController(text: p?.brand);
    _volume = TextEditingController(text: p?.volumeMl?.toString() ?? '');
    _purchase = TextEditingController(
      text: p?.purchasePrice.toStringAsFixed(0) ?? '0',
    );
    _sale = TextEditingController(text: p?.salePrice.toStringAsFixed(0) ?? '');
    _stock = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    _minAlert = TextEditingController(text: '${p?.minStockLevel ?? 5}');
    _pickedExpiry = p?.expiresAt;
    _expiry = TextEditingController(
      text: _pickedExpiry != null
          ? DateFormat('dd/MM/yyyy').format(_pickedExpiry!)
          : '',
    );
    _categoryId = p?.categoryId ?? widget.categories.first['id'] as String?;
  }

  @override
  void dispose() {
    _barcode.dispose();
    _nameFr.dispose();
    _nameAr.dispose();
    _brand.dispose();
    _volume.dispose();
    _purchase.dispose();
    _sale.dispose();
    _stock.dispose();
    _minAlert.dispose();
    _expiry.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _pickedExpiry ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _pickedExpiry = d;
        _expiry.text = DateFormat('dd/MM/yyyy').format(d);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final catId = _categoryId;
    if (catId == null) return;

    final nameFr = _nameFr.text.trim();
    Navigator.pop(
      context,
      ProductFormResult(
        categoryId: catId,
        barcode: _barcode.text.trim(),
        nameFr: nameFr,
        nameAr: _nameAr.text.trim().isEmpty ? nameFr : _nameAr.text.trim(),
        salePrice: double.tryParse(_sale.text) ?? 0,
        purchasePrice: double.tryParse(_purchase.text) ?? 0,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        volumeMl: int.tryParse(_volume.text),
        stockQuantity: int.tryParse(_stock.text),
        minStockLevel: int.tryParse(_minAlert.text) ?? 5,
        expiresAt: _pickedExpiry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.isEdit ? l10n.editProduct : l10n.addProduct;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF16213E)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(l10n.category),
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: _dec(l10n.category),
                        items: [
                          for (final c in widget.categories)
                            DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['name_fr'] as String),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) =>
                            v == null ? l10n.categories : null,
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Identification'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _barcode,
                        decoration: _dec(
                          l10n.barcode,
                          hint: l10n.barcodeOptionalHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameFr,
                              decoration: _dec(l10n.nameFr),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? l10n.nameFr
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextFormField(
                                controller: _nameAr,
                                decoration: _dec(l10n.nameAr),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brand,
                              decoration: _dec(l10n.brand),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _volume,
                              decoration: _dec('Volume (ml)'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Tarification'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _purchase,
                              decoration: _dec(
                                l10n.purchasePrice,
                                hint: AppConfig.currencySymbol,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _sale,
                              decoration: _dec(
                                l10n.price,
                                hint: AppConfig.currencySymbol,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n <= 0) return l10n.price;
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Stock'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stock,
                              decoration: _dec(
                                widget.isEdit
                                    ? l10n.quantity
                                    : l10n.initialStock,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _minAlert,
                              decoration: _dec(
                                l10n.minStockAlert,
                                helper: l10n.minStockAlertHint,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickExpiry,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: _dec(l10n.expiryDate, hint: '—'),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _expiry.text.isEmpty
                                      ? '—'
                                      : _expiry.text,
                                  style: TextStyle(
                                    color: _expiry.text.isEmpty
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                              if (_expiry.text.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() {
                                    _pickedExpiry = null;
                                    _expiry.clear();
                                  }),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.save),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppTheme.primary.withValues(alpha: 0.55),
      ),
    );
  }
}
