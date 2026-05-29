import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/store_settings.dart';

class SaleReceipt {
  SaleReceipt({
    required this.invoiceNumber,
    required this.lines,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeGiven,
    required this.soldAt,
    this.cashierName,
    this.clientPhone,
    StoreSettings? store,
    this.loyaltyStamps,
    this.loyaltyGiftEligible = false,
  }) : store = store ?? StoreSettings.defaults;

  final String invoiceNumber;
  final List<CartLine> lines;
  final double subtotal;
  final double discountAmount;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double changeGiven;
  final DateTime soldAt;
  final String? cashierName;
  final String? clientPhone;
  final StoreSettings store;
  final int? loyaltyStamps;
  final bool loyaltyGiftEligible;

  int get loyaltyThreshold => LoyaltyConfig.giftThreshold;

  String get storeNameFr => store.nameFr;
  String get storeNameAr => store.nameAr;
  String get currencySymbol => store.currencySymbol;

  factory SaleReceipt.beforeComplete({
    required List<CartLine> lines,
    required double subtotal,
    required double discountAmount,
    required double total,
    required String paymentMethod,
    required double amountPaid,
    required double changeGiven,
    String? cashierName,
    String? clientPhone,
    StoreSettings? store,
  }) {
    return SaleReceipt(
      invoiceNumber: '',
      lines: lines
          .map((l) => CartLine(product: l.product, quantity: l.quantity))
          .toList(),
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      soldAt: DateTime.now(),
      cashierName: cashierName,
      clientPhone: clientPhone,
      store: store,
    );
  }

  SaleReceipt withInvoice(String invoiceNumber) {
    return SaleReceipt(
      invoiceNumber: invoiceNumber,
      lines: lines,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      soldAt: soldAt,
      cashierName: cashierName,
      clientPhone: clientPhone,
      store: store,
      loyaltyStamps: loyaltyStamps,
      loyaltyGiftEligible: loyaltyGiftEligible,
    );
  }

  SaleReceipt withStore(StoreSettings store) {
    return SaleReceipt(
      invoiceNumber: invoiceNumber,
      lines: lines,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      soldAt: soldAt,
      cashierName: cashierName,
      clientPhone: clientPhone,
      store: store,
      loyaltyStamps: loyaltyStamps,
      loyaltyGiftEligible: loyaltyGiftEligible,
    );
  }

  SaleReceipt withLoyalty({required int stamps, required bool giftEligible}) {
    return SaleReceipt(
      invoiceNumber: invoiceNumber,
      lines: lines,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeGiven: changeGiven,
      soldAt: soldAt,
      cashierName: cashierName,
      clientPhone: clientPhone,
      store: store,
      loyaltyStamps: stamps,
      loyaltyGiftEligible: giftEligible,
    );
  }
}
