import 'package:flutter/foundation.dart';
import 'package:souma_parfumerie/core/models/cart_line.dart';
import 'package:souma_parfumerie/core/models/product_model.dart';
import 'package:souma_parfumerie/features/pos/data/pos_repository.dart';
import 'package:souma_parfumerie/core/config/loyalty_config.dart';
import 'package:souma_parfumerie/features/clients/data/clients_repository.dart';
import 'package:souma_parfumerie/features/settings/data/store_settings_repository.dart';
import 'package:souma_parfumerie/features/pos/models/sale_receipt.dart';

class PosProvider extends ChangeNotifier {
  PosProvider(this._repository);

  final PosRepository _repository;
  final _storeRepo = StoreSettingsRepository();
  final _clientsRepo = ClientsRepository();
  final List<CartLine> _lines = [];

  String paymentMethod = 'cash';
  double discountAmount = 0;
  double discountPercent = 0;
  double amountPaid = 0;
  String? clientPhone;
  String? lastInvoice;
  String? stockError;

  List<CartLine> get lines => List.unmodifiable(_lines);

  double get subtotal => _lines.fold(0, (sum, l) => sum + l.lineTotal);

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
    var product = await _repository.findByBarcode(barcode);
    if (product == null) {
      final expired = await _repository.findByBarcodeAllowExpired(barcode);
      if (expired != null && expired.isExpired) {
        stockError = 'expired';
        notifyListeners();
        return;
      }
      stockError = 'not_found';
      notifyListeners();
      return;
    }
    _addProductToCart(product, allowOverride: allowOverride);
  }

  void addProduct(ProductModel product, {bool allowOverride = false}) {
    stockError = null;
    _addProductToCart(product, allowOverride: allowOverride);
  }

  void _addProductToCart(ProductModel product, {bool allowOverride = false}) {
    if (product.stockQuantity <= 0 && !allowOverride) {
      stockError = 'outOfStock';
      notifyListeners();
      return;
    }

    final existing =
        _lines.where((l) => l.product.id == product.id).firstOrNull;
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

    final linesSnapshot = _lines
        .map((l) => CartLine(product: l.product, quantity: l.quantity))
        .toList();

    // Capturer les montants AVANT de vider le panier (sinon total = 0).
    final savedSubtotal = subtotal;
    final savedDiscountAmount = discountAmount;
    final savedDiscountPercent = discountPercent;
    final savedTotal = total;
    final savedPayment = paymentMethod;
    final savedPhone = clientPhone;
    final paid = amountPaid > 0 ? amountPaid : savedTotal;
    final savedChange = savedPayment == 'cash' && paid > savedTotal
        ? paid - savedTotal
        : 0.0;

    final store = await _storeRepo.load();
    final snapshot = SaleReceipt.beforeComplete(
      lines: linesSnapshot,
      subtotal: savedSubtotal,
      discountAmount: savedDiscountAmount,
      total: savedTotal,
      paymentMethod: savedPayment,
      amountPaid: paid,
      changeGiven: savedChange,
      cashierName: cashierName,
      clientPhone: savedPhone,
      store: store,
    );

    late final ({String invoiceNumber, String? clientId}) saleResult;
    try {
      saleResult = await _repository.completeSale(
        userId: userId,
        lines: linesSnapshot,
        subtotal: savedSubtotal,
        discountAmount: savedDiscountAmount,
        discountPercent: savedDiscountPercent,
        total: savedTotal,
        paymentMethod: savedPayment,
        amountPaid: paid,
        changeGiven: savedChange,
        clientPhone: savedPhone,
      );
      lastInvoice = saleResult.invoiceNumber;

      if (saleResult.clientId != null) {
        await _clientsRepo.addLoyaltyValidation(saleResult.clientId!);
      }
    } catch (e) {
      _lines.addAll(linesSnapshot);
      discountAmount = savedDiscountAmount;
      discountPercent = savedDiscountPercent;
      paymentMethod = savedPayment;
      clientPhone = savedPhone;
      amountPaid = paid;
      notifyListeners();
      debugPrint('completeSale error: $e');
      rethrow;
    }

    clearCart();
    notifyListeners();

    var receipt = snapshot.withInvoice(lastInvoice!);
    if (saleResult.clientId != null) {
      final stamps = await _clientsRepo.getLoyaltyPoints(saleResult.clientId!);
      receipt = receipt.withLoyalty(
        stamps: stamps,
        giftEligible: stamps >= LoyaltyConfig.giftThreshold,
      );
    }
    return receipt;
  }
}
