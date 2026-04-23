class PurchaseItem {
  final int id;
  final int productId;
  final String productName;
  final String unit;
  final double qty;
  final double? packagingUnitsQty;
  final double? unitsPerPack;
  final double? totalUnits;
  final double billableQty;
  final double unitPrice;
  final double unitCost;
  final double lineTotal;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.qty,
    this.packagingUnitsQty,
    this.unitsPerPack,
    this.totalUnits,
    required this.billableQty,
    required this.unitPrice,
    required this.unitCost,
    required this.lineTotal,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      unit: json['unit'] as String,
      qty: (json['qty'] as num).toDouble(),
      packagingUnitsQty: (json['packagingUnitsQty'] as num?)?.toDouble(),
      unitsPerPack: (json['unitsPerPack'] as num?)?.toDouble(),
      totalUnits: (json['totalUnits'] as num?)?.toDouble(),
      billableQty: (json['billableQty'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'qty': qty,
        'packagingUnitsQty': packagingUnitsQty,
        'unitsPerPack': unitsPerPack,
        'totalUnits': totalUnits,
        'billableQty': billableQty,
        'unitPrice': unitPrice,
        'unitCost': unitCost,
        'lineTotal': lineTotal,
      };
}
