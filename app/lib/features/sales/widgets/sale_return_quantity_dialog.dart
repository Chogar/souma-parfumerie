import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/sales/models/sale_return_line_request.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class _LineState {
  _LineState({
    required this.saleLineId,
    required this.productId,
    required this.label,
    required this.quantitySold,
    this.selected = false,
    int returnQty = 1,
  }) : returnQty = returnQty.clamp(1, quantitySold);

  final String saleLineId;
  final String productId;
  final String label;
  final int quantitySold;
  bool selected;
  int returnQty;
}

/// Résultat du dialogue retour (lignes + motif optionnel).
class SaleReturnDialogResult {
  const SaleReturnDialogResult({required this.items, this.reason});

  final List<SaleReturnLineRequest> items;
  final String? reason;
}

int saleLineQuantity(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 1;
}

bool saleNeedsReturnQuantityPicker(List<Map<String, dynamic>> lines) {
  if (lines.length > 1) return true;
  if (lines.isEmpty) return false;
  return saleLineQuantity(lines.first['quantity']) > 1;
}

/// Choix des produits et quantités à retourner (+ motif).
Future<SaleReturnDialogResult?> showSaleReturnQuantityDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> saleLines,
}) {
  return showDialog<SaleReturnDialogResult>(
    context: context,
    builder: (ctx) => _SaleReturnQuantityDialog(saleLines: saleLines),
  );
}

/// Motif seul (une ligne, quantité 1).
Future<SaleReturnDialogResult?> showSaleReturnReasonDialog({
  required BuildContext context,
  required SaleReturnLineRequest singleLine,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final reason = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.requestSaleReturn),
      content: TextField(
        controller: reason,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.saleReturnReason,
          hintText: l10n.saleReturnReasonHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.requestSaleReturn),
        ),
      ],
    ),
  );
  final text = reason.text.trim();
  reason.dispose();
  if (ok != true) return null;
  return SaleReturnDialogResult(
    items: [singleLine],
    reason: text.isEmpty ? null : text,
  );
}

class _SaleReturnQuantityDialog extends StatefulWidget {
  const _SaleReturnQuantityDialog({required this.saleLines});

  final List<Map<String, dynamic>> saleLines;

  @override
  State<_SaleReturnQuantityDialog> createState() =>
      _SaleReturnQuantityDialogState();
}

class _SaleReturnQuantityDialogState extends State<_SaleReturnQuantityDialog> {
  late final List<_LineState> _lines;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    final multi = widget.saleLines.length > 1;
    _lines = widget.saleLines.map((l) {
      final sold = saleLineQuantity(l['quantity']);
      return _LineState(
        saleLineId: l['id'] as String,
        productId: l['product_id'] as String,
        label: _labelFor(l),
        quantitySold: sold,
        selected: !multi || sold == 1,
        returnQty: 1,
      );
    }).toList();
  }

  String _labelFor(Map<String, dynamic> l) {
    final locale = context.read<LocaleProvider>().locale.languageCode;
    if (locale == 'ar') {
      final ar = l['name_ar']?.toString().trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return l['name_fr']?.toString() ?? l['name_ar']?.toString() ?? '—';
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final multi = widget.saleLines.length > 1;

    return AlertDialog(
      title: Text(l10n.saleReturnSelectProducts),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (multi)
                Text(
                  l10n.saleReturnSelectProductsHint,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              const SizedBox(height: 12),
              ..._lines.map((state) {
                final sold = state.quantitySold;
                final showQty = sold > 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (multi)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              state.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              l10n.saleReturnSoldQty(sold),
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: state.selected,
                            onChanged: (v) {
                              setState(() {
                                state.selected = v ?? false;
                                if (state.selected && sold == 1) {
                                  state.returnQty = 1;
                                }
                              });
                            },
                          )
                        else
                          Text(
                            state.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        if (showQty && (!multi || state.selected)) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                l10n.saleReturnQtyToReturn,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: state.returnQty > 1
                                    ? () => setState(() => state.returnQty--)
                                    : null,
                              ),
                              Text(
                                '${state.returnQty} / $sold',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: state.returnQty < sold
                                    ? () => setState(() => state.returnQty++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: _reason,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.saleReturnReason,
                  hintText: l10n.saleReturnReasonHint,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.requestSaleReturn),
        ),
      ],
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final multi = widget.saleLines.length > 1;
    final selected = multi
        ? _lines.where((s) => s.selected).toList()
        : _lines;

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saleReturnSelectAtLeastOne)),
      );
      return;
    }

    final items = <SaleReturnLineRequest>[];
    for (final s in selected) {
      if (s.returnQty < 1 || s.returnQty > s.quantitySold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saleReturnInvalidQty)),
        );
        return;
      }
      items.add(
        SaleReturnLineRequest(
          saleLineId: s.saleLineId,
          productId: s.productId,
          quantitySold: s.quantitySold,
          quantityToReturn: s.returnQty,
        ),
      );
    }

    final reasonText = _reason.text.trim();
    Navigator.pop(
      context,
      SaleReturnDialogResult(
        items: items,
        reason: reasonText.isEmpty ? null : reasonText,
      ),
    );
  }
}
