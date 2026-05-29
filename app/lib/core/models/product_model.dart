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
    this.categoryNameFr,
    this.categoryNameAr,
    this.minStockLevel = 5,
    this.expiresAt,
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
  final String? categoryNameFr;
  final String? categoryNameAr;
  final int minStockLevel;
  final DateTime? expiresAt;

  String displayName(String locale) =>
      locale.startsWith('ar') ? nameAr : nameFr;

  String? categoryName(String locale) {
    final fr = categoryNameFr;
    final ar = categoryNameAr;
    if (locale.startsWith('ar')) return ar ?? fr;
    return fr ?? ar;
  }

  bool get isLowStock => stockQuantity <= minStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;

  bool get isExpired {
    if (expiresAt == null) return false;
    final today = DateTime.now();
    final exp = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    final now = DateTime(today.year, today.month, today.day);
    return exp.isBefore(now);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    DateTime? expires;
    final raw = map['expires_at'];
    if (raw is DateTime) {
      expires = raw;
    } else if (raw != null) {
      expires = DateTime.tryParse(raw.toString());
    }

    return ProductModel(
      id: map['id'] as String,
      barcode: map['barcode']?.toString() ?? '',
      nameFr: map['name_fr'] as String,
      nameAr: map['name_ar'] as String,
      salePrice: _toDouble(map['sale_price']),
      purchasePrice: _toDouble(map['purchase_price']),
      brand: map['brand'] as String?,
      volumeMl: map['volume_ml'] as int?,
      stockQuantity:
          map['quantity'] as int? ?? map['stock_quantity'] as int? ?? 0,
      categoryId: map['category_id'] as String?,
      categoryNameFr: map['category_name_fr'] as String?,
      categoryNameAr: map['category_name_ar'] as String?,
      minStockLevel: map['min_stock_level'] as int? ?? 5,
      expiresAt: expires,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
