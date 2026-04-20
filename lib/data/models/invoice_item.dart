class InvoiceItem {
  final int productId;
  final String productName;
  final double qty;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productId: json['productId'],
      productName: json['productName']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'unit': unit,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }
}
