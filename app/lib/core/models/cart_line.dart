import 'package:souma_parfumerie/core/models/product_model.dart';

class CartLine {
  CartLine({
    required this.product,
    this.quantity = 1,
  });

  final ProductModel product;
  int quantity;

  double get lineTotal => product.salePrice * quantity;
}
