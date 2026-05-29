import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/store_settings_service.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/clients/data/clients_repository.dart';
import 'package:souma_parfumerie/core/widgets/app_logo.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/loyalty_stamp_row.dart';
import 'package:souma_parfumerie/core/widgets/store_info_header.dart';
import 'package:souma_parfumerie/features/sales/services/invoice_service.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Détail facture avec totaux, réimpression et export PDF.
class InvoiceDetailDialog extends StatefulWidget {
  const InvoiceDetailDialog({
    super.key,
    required this.saleId,
    required this.sale,
    required this.lines,
    required this.locale,
    required this.showAmounts,
    this.onlyUserId,
    this.returnStatus,
    this.canRequestReturn = false,
    this.onRequestReturn,
  });

  final String saleId;
  final Map<String, dynamic> sale;
  final List<Map<String, dynamic>> lines;
  final String locale;
  final bool showAmounts;
  final String? onlyUserId;
  final String? returnStatus;
  final bool canRequestReturn;
  final VoidCallback? onRequestReturn;

  @override
  State<InvoiceDetailDialog> createState() => _InvoiceDetailDialogState();
}

class _InvoiceDetailDialogState extends State<InvoiceDetailDialog> {
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  final _clientsRepo = ClientsRepository();
  bool _printing = false;
  bool _exportingPdf = false;
  bool _giftLoading = false;
  int? _loyaltyStamps;

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loyaltyStamps = _readLoyaltyStamps(widget.sale);
  }

  int _readLoyaltyStamps(Map<String, dynamic> sale) {
    final v = sale['client_loyalty_points'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _offerGift() async {
    final clientId = widget.sale['client_id']?.toString().trim();
    if (clientId == null || clientId.isEmpty) return;
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
    if (ok != true || !mounted) return;
    setState(() => _giftLoading = true);
    try {
      final success = await _clientsRepo.redeemGift(clientId);
      if (!mounted) return;
      if (success) {
        setState(() => _loyaltyStamps = 0);
        bumpAppRefresh(context);
        AppNotifier.success(l10n.giftOfferedDone, context: context);
      } else {
        AppNotifier.error(l10n.redeemGiftFailed, context: context);
      }
    } finally {
      if (mounted) setState(() => _giftLoading = false);
    }
  }

  Future<void> _reprint() async {
    if (_printing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _printing = true);
    try {
      final ok = await InvoiceService.reprintReceipt(
        widget.saleId,
        language: widget.locale,
        onlyUserId: widget.onlyUserId,
      ).timeout(const Duration(seconds: 50));
      if (mounted) {
        if (ok) {
          AppNotifier.success(l10n.pdfExportReady);
        } else {
          AppNotifier.warning(l10n.printError);
        }
      }
    } on TimeoutException {
      if (mounted) {
        AppNotifier.error(l10n.printError);
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.error('${l10n.printError}: $e');
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await InvoiceService.exportInvoicePdf(
        widget.saleId,
        locale: widget.locale,
        onlyUserId: widget.onlyUserId,
      );
      if (!mounted) return;
      if (result.ok) {
        final pathMsg = result.path != null ? '\n${result.path}' : '';
        AppNotifier.success(
          '${l10n.pdfExportReady}$pathMsg',
          context: context,
        );
      } else {
        AppNotifier.error(l10n.pdfExportFailed, context: context);
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.error('${l10n.pdfExportFailed}: $e', context: context);
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = widget.locale.startsWith('ar');
    final store = context.watch<StoreSettingsService>().settings;
    final currency = store.currencySymbol;
    final discount = _num(widget.sale['discount_amount']);
    final total = _num(widget.sale['total']);
    final soldAt = widget.sale['sold_at'];
    final soldAtStr = soldAt is DateTime
        ? DateFormat('dd/MM/yyyy HH:mm').format(soldAt)
        : soldAt?.toString() ?? '';
    final clientPhone = widget.sale['client_phone']?.toString();
    final clientId = widget.sale['client_id'] as String?;
    final stamps = _loyaltyStamps;
    final loyaltyStamps = clientPhone != null &&
            clientPhone.isNotEmpty &&
            stamps != null
        ? stamps
        : null;
    final giftEligible = loyaltyStamps != null &&
        loyaltyStamps >= LoyaltyConfig.giftThreshold;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final canOfferGift =
        giftEligible && perms.canManageClients && clientId != null;
    final isReturnPending = widget.returnStatus == 'pending';

    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text('${l10n.invoiceDetail} — ${widget.sale['invoice_number']}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: maxContentHeight.clamp(320.0, 720.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 72, showBorder: true)),
              const SizedBox(height: 12),
              StoreInfoHeader(store: store, locale: widget.locale),
              const SizedBox(height: 14),
              Text(
                '${widget.sale['cashier_name']} • $soldAtStr',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.sale['client_phone'] != null)
                Text('${l10n.clientPhone}: ${widget.sale['client_phone']}'),
              if (widget.sale['client_name'] != null &&
                  widget.sale['client_name'].toString().isNotEmpty)
                Text('${l10n.clientName}: ${widget.sale['client_name']}'),
              if (isReturnPending) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.saleReturnPendingManager,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (loyaltyStamps != null) ...[
                const SizedBox(height: 12),
                LoyaltySummaryPanel(
                  stamps: loyaltyStamps,
                  giftEligible: giftEligible,
                  onGiftOffered: canOfferGift ? _offerGift : null,
                  giftOfferedLoading: _giftLoading,
                ),
              ],
              const SizedBox(height: 12),
              ..._buildLineTiles(isAr, currency),
              if (widget.showAmounts) ...[
                const Divider(height: 24),
                if (discount > 0)
                  _totalRow(l10n.discount, -discount, currency),
                _totalRow(l10n.total, total, currency, bold: true),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowButtonSpacing: 8,
      actions: [
        if (widget.canRequestReturn && widget.onRequestReturn != null)
          OutlinedButton.icon(
            onPressed: widget.onRequestReturn,
            icon: const Icon(Icons.assignment_return_outlined, size: 20),
            label: Text(l10n.requestSaleReturn),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        FilledButton.icon(
          onPressed: _printing ? null : _reprint,
          icon: _printing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print, size: 20),
          label: Text(l10n.reprintReceipt),
        ),
        FilledButton.tonalIcon(
          onPressed: _exportingPdf ? null : _exportPdf,
          icon: _exportingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf, size: 20),
          label: Text(l10n.exportInvoicePdf),
        ),
      ],
    );
  }

  List<Widget> _buildLineTiles(bool isAr, String currency) {
    final widgets = <Widget>[];
    for (var i = 0; i < widget.lines.length; i++) {
      if (i > 0) widgets.add(const Divider(height: 1));
      final l = widget.lines[i];
      final name = isAr ? l['name_ar'] : l['name_fr'];
      final qty = l['quantity'];
      final lineTotal = _num(l['line_total']);
      widgets.add(
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(name?.toString() ?? ''),
          subtitle: widget.showAmounts
              ? Text('${_fmt.format(_num(l['unit_price']))} × $qty')
              : null,
          trailing: widget.showAmounts
              ? Text(
                  '${_fmt.format(lineTotal)} $currency',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )
              : Text('×$qty'),
        ),
      );
    }
    return widgets;
  }

  Widget _totalRow(
    String label,
    double value,
    String currency, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${_fmt.format(value)} $currency',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
