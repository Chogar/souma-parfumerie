import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/features/pos/data/pos_repository.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';

class PosProvider extends ChangeNotifier {
  PosProvider(this._repository);

  final PosRepository _repository;
  final List<CartLine> _lines = [];

  String paymentMethod = 'cash';
  double discountAmount = 0;
  double discountPercent = 0;
  double amountPaid = 0;
  String? clientPhone;
  String? lastInvoice;
  String? stockError;

  List<CartLine> get lines => List.unmodifiable(_lines);

  double get subtotal =>
      _lines.fold(0, (sum, l) => sum + l.lineTotal);

  double get total {
    var t = subtotal;
    if (discountPercent > 0) {
      t -= subtotal * (discountPercent / 100);
    }
    t -= discountAmount;
    return t < 0 ? 0 : t;
  }

  double get change =>
      paymentMethod == 'cash' && amountPaid > total ? amountPaid - total : 0;

  void setDiscountAmount(double value) {
    discountAmount = value;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setClientPhone(String? phone) {
    clientPhone = phone;
    notifyListeners();
  }

  Future<void> scanBarcode(String barcode, {bool allowOverride = false}) async {
    stockError = null;
    final product = await _repository.findByBarcode(barcode);
    if (product == null) {
      stockError = 'not_found';
      notifyListeners();
      return;
    }

    final existing = _lines.where((l) => l.product.id == product.id).firstOrNull;
    final newQty = (existing?.quantity ?? 0) + 1;

    if (newQty > product.stockQuantity && !allowOverride) {
      stockError = 'stockAlert';
      notifyListeners();
      return;
    }

    if (existing != null) {
      existing.quantity = newQty;
    } else {
      _lines.add(CartLine(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int qty) {
    final line = _lines.where((l) => l.product.id == productId).firstOrNull;
    if (line == null) return;
    if (qty <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = qty;
    }
    notifyListeners();
  }

  void removeLine(String productId) {
    _lines.removeWhere((l) => l.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _lines.clear();
    discountAmount = 0;
    discountPercent = 0;
    amountPaid = 0;
    clientPhone = null;
    stockError = null;
    notifyListeners();
  }

  Future<SaleReceipt?> completeSale(
    String userId, {
    String? cashierName,
  }) async {
    if (_lines.isEmpty) return null;

    final snapshot = SaleReceipt.beforeComplete(
      lines: _lines,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid > 0 ? amountPaid : total,
      changeGiven: change,
      cashierName: cashierName,
      clientPhone: clientPhone,
    );

    lastInvoice = await _repository.completeSale(
      userId: userId,
      lines: _lines,
      subtotal: subtotal,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
      total: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid > 0 ? amountPaid : total,
      changeGiven: change,
      clientPhone: clientPhone,
    );

    clearCart();
    notifyListeners();
    return snapshot.withInvoice(lastInvoice!);
  }
}
