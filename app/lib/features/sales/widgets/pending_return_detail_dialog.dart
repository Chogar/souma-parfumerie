import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/core/theme/app_theme.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

/// Résultat du dialogue : valider, refuser ou annuler.
enum PendingReturnDialogAction { approve, reject, cancel }

/// Détail produits / quantités avant validation d'un retour.
Future<PendingReturnDialogAction?> showPendingReturnDetailDialog({
  required BuildContext context,
  required String saleId,
  required SaleReturnsRepository repo,
}) async {
  final detail = await repo.getPendingReturnDetail(saleId);
  if (!context.mounted || detail == null) return null;

  return showDialog<PendingReturnDialogAction>(
    context: context,
    builder: (ctx) => _PendingReturnDetailDialog(detail: detail),
  );
}

class _PendingReturnDetailDialog extends StatelessWidget {
  const _PendingReturnDetailDialog({required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isAr = locale.startsWith('ar');
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final sale = detail['sale'] as Map<String, dynamic>;
    final returnLines = (detail['return_lines'] as List).cast<Map<String, dynamic>>();
    final allLines = (detail['all_lines'] as List).cast<Map<String, dynamic>>();
    final currency = AppConfig.currencySymbol;

    final returnByLineId = {
      for (final r in returnLines) r['sale_line_id'] as String: r,
    };

    final requestedAt = sale['return_requested_at'];
    DateTime? reqDt;
    if (requestedAt is DateTime) {
      reqDt = requestedAt;
    } else if (requestedAt != null) {
      reqDt = DateTime.tryParse('$requestedAt');
    }
    final dateStr = reqDt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(reqDt)
        : '—';

    final clientPhone = sale['client_phone']?.toString();
    final loyaltyPts = sale['client_loyalty_points'];
    final hasClient = clientPhone != null && clientPhone.isNotEmpty;

    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(l10n.pendingReturnDetailTitle),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH.clamp(360, 680)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _infoRow(l10n.invoice, '${sale['invoice_number']}'),
              _infoRow(
                l10n.saleReturnRequestedBy,
                '${sale['return_requester_name'] ?? sale['cashier_name'] ?? '—'}',
              ),
              _infoRow(l10n.saleReturnProcessedAt, dateStr),
              if (hasClient) ...[
                _infoRow(l10n.clientPhone, clientPhone),
                if (sale['client_name'] != null &&
                    '${sale['client_name']}'.trim().isNotEmpty)
                  _infoRow(l10n.clientName, '${sale['client_name']}'),
                _infoRow(
                  l10n.loyaltyProgramTitle,
                  '${loyaltyPts ?? 0} / 10',
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.loyalty, size: 18, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.loyaltyStampDeductedOnReturn,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (sale['return_reason'] != null &&
                  '${sale['return_reason']}'.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(l10n.saleReturnReason, '${sale['return_reason']}'),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.returnDetailProducts,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...allLines.map((line) {
                final lineId = line['id'] as String;
                final ret = returnByLineId[lineId];
                final sold = _intQty(line['quantity']);
                final toReturn = ret != null
                    ? _intQty(ret['quantity_to_return'])
                    : 0;
                final name = isAr
                    ? (line['name_ar'] ?? line['name_fr'])
                    : (line['name_fr'] ?? line['name_ar']);
                final unitPrice = _num(line['unit_price']);
                final isReturning = toReturn > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isReturning
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name?.toString() ?? '—',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isReturning
                                ? Colors.orange.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (line['barcode'] != null &&
                            '${line['barcode']}'.trim().isNotEmpty)
                          Text(
                            '${l10n.barcode}: ${line['barcode']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.saleReturnSoldQty(sold),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (isReturning)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.saleReturnQtyLabel(toReturn),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              )
                            else
                              Text(
                                l10n.returnDetailNotReturned,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        if (isReturning) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${fmt.format(unitPrice)} $currency × $toReturn = '
                            '${fmt.format(unitPrice * toReturn)} $currency',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.total,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${fmt.format(_num(sale['total']))} $currency',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, PendingReturnDialogAction.cancel),
          child: Text(l10n.close),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, PendingReturnDialogAction.reject),
          child: Text(l10n.rejectReturn),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, PendingReturnDialogAction.approve),
          child: Text(l10n.approveReturn),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  int _intQty(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
