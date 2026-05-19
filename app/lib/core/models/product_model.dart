class ProductModel {
  const ProductModel({
    required this.id,
    required this.barcode,
    required this.nameFr,
    required this.nameAr,
    required this.salePrice,
    required this.purchasePrice,
    this.brand,
    this.volumeMl,
    this.stockQuantity = 0,
    this.categoryId,
    this.minStockLevel = 5,
  });

  final String id;
  final String barcode;
  final String nameFr;
  final String nameAr;
  final double salePrice;
  final double purchasePrice;
  final String? brand;
  final int? volumeMl;
  final int stockQuantity;
  final String? categoryId;
  final int minStockLevel;

  String displayName(String locale) =>
      locale.startsWith('ar') ? nameAr : nameFr;

  bool get isLowStock => stockQuantity <= minStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      nameFr: map['name_fr'] as String,
      nameAr: map['name_ar'] as String,
      salePrice: _toDouble(map['sale_price']),
      purchasePrice: _toDouble(map['purchase_price']),
      brand: map['brand'] as String?,
      volumeMl: map['volume_ml'] as int?,
      stockQuantity: map['quantity'] as int? ?? map['stock_quantity'] as int? ?? 0,
      categoryId: map['category_id'] as String?,
      minStockLevel: map['min_stock_level'] as int? ?? 5,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
