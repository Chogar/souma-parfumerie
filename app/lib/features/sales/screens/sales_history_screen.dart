import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:souma_parfumerie/core/config/app_config.dart';
import 'package:souma_parfumerie/core/security/app_permissions.dart';
import 'package:souma_parfumerie/core/services/locale_provider.dart';
import 'package:souma_parfumerie/features/auth/providers/auth_provider.dart';
import 'package:souma_parfumerie/features/sales/data/sale_returns_repository.dart';
import 'package:souma_parfumerie/features/sales/data/sales_repository.dart';
import 'package:souma_parfumerie/features/sales/services/invoice_service.dart';
import 'package:souma_parfumerie/core/widgets/app_notifier.dart';
import 'package:souma_parfumerie/core/widgets/auto_refresh_mixin.dart';
import 'package:souma_parfumerie/features/sales/models/sale_return_line_request.dart';
import 'package:souma_parfumerie/features/sales/widgets/invoice_detail_dialog.dart';
import 'package:souma_parfumerie/features/sales/widgets/sale_return_quantity_dialog.dart';
import 'package:souma_parfumerie/l10n/app_localizations.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen>
    with AutoRefreshMixin {
  final _repo = SalesRepository();
  final _returnsRepo = SaleReturnsRepository();
  final _fmt = NumberFormat('#,##0', 'fr_FR');
  bool _busyPdf = false;
  String? _busyPdfSaleId;
  int _reloadTick = 0;

  void _reload() => setState(() => _reloadTick++);

  @override
  void onAutoRefresh() => _reload();

  String _returnError(AppLocalizations l10n, Object e) {
    if (e is SaleReturnException) {
      switch (e.code) {
        case SaleReturnsRepository.codeMigrationRequired:
          return l10n.saleReturnMigrationRequired;
        case SaleReturnsRepository.codeNotReturnable:
          return l10n.saleReturnNotReturnable;
        case SaleReturnsRepository.codeAlreadyPending:
          return l10n.saleReturnAlreadyPending;
        case SaleReturnsRepository.codeNotFound:
          return l10n.saleReturnNotFound;
        case SaleReturnsRepository.codeForbidden:
          return l10n.saleReturnForbidden;
        case SaleReturnsRepository.codeInvalidItems:
          return l10n.saleReturnInvalidQty;
        default:
          return l10n.saleReturnFailed;
      }
    }
    return '$e';
  }

  Future<void> _requestReturn(
    String saleId,
    String userId,
    String? onlyUserId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final lines = await _repo.saleLines(saleId);
    if (!mounted || lines.isEmpty) return;

    final SaleReturnDialogResult? dialogResult;
    if (saleNeedsReturnQuantityPicker(lines)) {
      dialogResult = await showSaleReturnQuantityDialog(
        context: context,
        saleLines: lines,
      );
    } else {
      final l = lines.first;
      dialogResult = await showSaleReturnReasonDialog(
        context: context,
        singleLine: SaleReturnLineRequest(
          saleLineId: l['id'] as String,
          productId: l['product_id'] as String,
          quantitySold: saleLineQuantity(l['quantity']),
          quantityToReturn: 1,
        ),
      );
    }
    if (dialogResult == null) return;
    try {
      await _returnsRepo.requestReturn(
        saleId: saleId,
        requestedByUserId: userId,
        items: dialogResult.items,
        reason: dialogResult.reason,
        onlyUserId: onlyUserId,
      );
      _reload();
      if (mounted) bumpAppRefresh(context);
      if (mounted) AppNotifier.success(l10n.saleReturnRequested);
    } catch (e) {
      if (mounted) AppNotifier.error(_returnError(l10n, e));
    }
  }

  Future<void> _openDetail(
    String saleId,
    String locale,
    Map<String, dynamic> sale,
    AppPermissions perms,
    String? onlyUserId,
    String currentUserId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final verified = await _repo.getSaleById(saleId, onlyUserId: onlyUserId);
    if (!mounted) return;
    if (verified == null) {
      AppNotifier.warning(l10n.managerOnly);
      return;
    }

    final lines = await _repo.saleLines(saleId);
    if (!mounted) return;

    final returnStatus = verified['return_status']?.toString();
    final canRequest = perms.canRequestSaleReturn &&
        (returnStatus == null || returnStatus == 'rejected') &&
        (onlyUserId == null || verified['user_id'] == currentUserId);

    await showDialog<void>(
      context: context,
      barrierDismissible: !_busyPdf,
      builder: (ctx) => InvoiceDetailDialog(
        saleId: saleId,
        sale: verified,
        lines: lines,
        locale: locale,
        showAmounts: perms.canViewSaleAmounts,
        onlyUserId: onlyUserId,
        returnStatus: returnStatus,
        canRequestReturn: canRequest,
        onRequestReturn: canRequest
            ? () async {
                Navigator.pop(ctx);
                await _requestReturn(saleId, currentUserId, onlyUserId);
              }
            : null,
      ),
    );
    _reload();
  }

  Future<void> _exportPdf(
    String saleId,
    String locale, {
    String? onlyUserId,
  }) async {
    setState(() {
      _busyPdf = true;
      _busyPdfSaleId = saleId;
    });
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await InvoiceService.exportInvoicePdf(
        saleId,
        locale: locale,
        onlyUserId: onlyUserId,
      );
      if (result.ok) {
        final pathMsg = result.path != null ? '\n${result.path}' : '';
        AppNotifier.success('${l10n.pdfExportReady}$pathMsg');
      } else {
        AppNotifier.error(l10n.pdfExportFailed);
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.error('${l10n.pdfExportFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyPdf = false;
          _busyPdfSaleId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user!;
    final perms = AppPermissions(user, user.permissions);
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    if (!perms.canViewSalesHistory) {
      return Center(child: Text(l10n.managerOnly));
    }

    final onlyUserId = perms.scopeOwnSalesOnly ? user.id : null;

    return FutureBuilder(
      key: ValueKey(_reloadTick),
      future: _repo.listSales(onlyUserId: onlyUserId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = snap.data!;
        if (sales.isEmpty) {
          return Center(child: Text(l10n.noData));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (perms.scopeOwnSalesOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.mySalesOnly,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Expanded(
              child: sales.isEmpty
                  ? Center(child: Text(l10n.noData))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sales.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = sales[i];
                        final saleId = s['id'] as String;
                        final pdfLoading =
                            _busyPdf && _busyPdfSaleId == saleId;
                        final returnStatus =
                            s['return_status']?.toString();
                        final isPending = returnStatus == 'pending';
                        final canRequestReturn = perms.canRequestSaleReturn &&
                            !isPending &&
                            (returnStatus == null ||
                                returnStatus == 'rejected') &&
                            (onlyUserId == null ||
                                s['user_id'] == user.id);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPending
                                ? Colors.orange.withValues(alpha: 0.2)
                                : const Color(0xFFC9A227)
                                    .withValues(alpha: 0.15),
                            child: Icon(
                              isPending
                                  ? Icons.hourglass_top
                                  : Icons.receipt_long,
                              color: isPending
                                  ? Colors.orange.shade800
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${s['invoice_number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.saleReturnPending,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            perms.scopeOwnSalesOnly
                                ? '${s['sold_at']}\n'
                                    '${s['payment_method']}'
                                    '${s['client_phone'] != null ? ' • ${s['client_phone']}' : ''}'
                                : '${s['cashier_name']} • ${s['sold_at']}\n'
                                    '${s['payment_method']}'
                                    '${s['client_phone'] != null ? ' • ${s['client_phone']}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (perms.canViewSaleAmounts)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    '${_fmt.format(_num(s['total']))} ${AppConfig.currencySymbol}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (canRequestReturn)
                                IconButton(
                                  icon: const Icon(
                                    Icons.assignment_return_outlined,
                                  ),
                                  tooltip: l10n.requestSaleReturn,
                                  onPressed: () => _requestReturn(
                                    saleId,
                                    user.id,
                                    onlyUserId,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.print_outlined),
                                tooltip: l10n.reprintReceipt,
                                onPressed: () => _openDetail(
                                  saleId,
                                  locale,
                                  s,
                                  perms,
                                  onlyUserId,
                                  user.id,
                                ),
                              ),
                              IconButton(
                                icon: pdfLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                tooltip: l10n.exportInvoicePdf,
                                onPressed: pdfLoading
                                    ? null
                                    : () => _exportPdf(
                                          saleId,
                                          locale,
                                          onlyUserId: onlyUserId,
                                        ),
                              ),
                            ],
                          ),
                          onTap: () => _openDetail(
                            saleId,
                            locale,
                            s,
                            perms,
                            onlyUserId,
                            user.id,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
