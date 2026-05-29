/// Ligne demandée pour un retour (quantité par produit).
class SaleReturnLineRequest {
  const SaleReturnLineRequest({
    required this.saleLineId,
    required this.productId,
    required this.quantitySold,
    required this.quantityToReturn,
  });

  final String saleLineId;
  final String productId;
  final int quantitySold;
  final int quantityToReturn;
}
