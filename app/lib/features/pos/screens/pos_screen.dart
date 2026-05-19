import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/pos/providers/pos_provider.dart';
import 'package:souma_parfumerie/features/pos/services/receipt_print_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _barcodeCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fmt = NumberFormat('#,##0', 'fr_FR');

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _amountPaidCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = _barcodeCtrl.text.trim();
    if (code.isEmpty) return;
    final pos = context.read<PosProvider>();
    await pos.scanBarcode(code);
    _barcodeCtrl.clear();
    if (!mounted) return;
    if (pos.stockError != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stockAlert)),
      );
    }
  }

  Future<void> _validate() async {
    final auth = context.read<AuthProvider>();
    final pos = context.read<PosProvider>();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    pos.amountPaid = double.tryParse(_amountPaidCtrl.text) ?? pos.total;

    final receipt = await pos.completeSale(
      auth.user!.id,
      cashierName: auth.user!.fullName,
    );

    if (!mounted || receipt == null) return;

    try {
      await ReceiptPrintService.printReceipt(
        receipt,
        language: locale,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impression: $e')),
      );
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.invoice}: ${receipt.invoiceNumber}')),
    );
    _amountPaidCtrl.clear();
    _phoneCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final pos = context.watch<PosProvider>();
    final auth = context.watch<AuthProvider>();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _barcodeCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.scanBarcode,
                    hintText: l10n.barcodeHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
                  ),
                  onSubmitted: (_) => _scan(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: pos.lines.isEmpty
                      ? Center(child: Text(l10n.noData))
                      : ListView.builder(
                          itemCount: pos.lines.length,
                          itemBuilder: (_, i) {
                            final line = pos.lines[i];
                            return Card(
                              child: ListTile(
                                title: Text(line.product.displayName(locale)),
                                subtitle: Text(
                                  '${line.product.barcode} • ${_fmt.format(line.product.salePrice)} ${AppConfig.currencySymbol}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () => pos.updateQuantity(
                                        line.product.id,
                                        line.quantity - 1,
                                      ),
                                    ),
                                    Text('${line.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => pos.updateQuantity(
                                        line.product.id,
                                        line.quantity + 1,
                                      ),
                                    ),
                                    Text(
                                      _fmt.format(line.lineTotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _row(l10n.subtotal, pos.subtotal),
              if (auth.user!.isManager) ...[
                TextField(
                  decoration: InputDecoration(labelText: l10n.discount),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) =>
                      pos.setDiscountAmount(double.tryParse(v) ?? 0),
                ),
              ],
              _row(l10n.total, pos.total, bold: true),
              const Divider(),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: l10n.clientPhone),
                onChanged: pos.setClientPhone,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: pos.paymentMethod,
                decoration: InputDecoration(labelText: l10n.cash),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                  DropdownMenuItem(value: 'card', child: Text(l10n.card)),
                  DropdownMenuItem(value: 'mobile', child: Text(l10n.mobile)),
                ],
                onChanged: (v) {
                  if (v != null) pos.setPaymentMethod(v);
                },
              ),
              if (pos.paymentMethod == 'cash') ...[
                TextField(
                  controller: _amountPaidCtrl,
                  decoration: InputDecoration(labelText: l10n.amountPaid),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                _row(l10n.change, pos.change),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: pos.clearCart,
                child: Text(l10n.clearCart),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: pos.lines.isEmpty ? null : _validate,
                child: Text(l10n.validateSale),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(
            '${NumberFormat('#,##0', 'fr_FR').format(value)} ${AppConfig.currencySymbol}',
            style: bold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18) : null,
          ),
        ],
      ),
    );
  }
}
