// lib/features/product/data/models/product.dart
class Product {
  final int id;
  final String? categoryId;
  final String name;
  final String? displayName;
  final String? sku;
  final String? specifications;
  final String? thinkness;
  final double? weight;
  final String? description;
  final String unit;
  final String? packagingUnit;
  final int? unitsPerPack;
  final String? billableUnit;
  final double purchasePrice;
  final double sellingPrice;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.displayName,
    this.sku,
    this.specifications,
    this.thinkness,
    this.weight,
    this.description,
    required this.unit,
    this.packagingUnit,
    this.unitsPerPack,
    this.billableUnit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Từ JSON (khi gọi API)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      displayName: json['displayName'],
      sku: json['sku'],
      specifications: json['specifications'],
      thinkness: json['thinkness'],
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      description: json['description'],
      unit: json['unit'],
      packagingUnit: json['packagingUnit'],
      unitsPerPack: json['unitsPerPack'],
      billableUnit: json['billableUnit'],
      purchasePrice: double.tryParse(json['purchasePrice'].toString()) ?? 0.0,
      sellingPrice: double.tryParse(json['sellingPrice'].toString()) ?? 0.0,
      status: json['status'] ?? 'Active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  // Chuyển sang JSON (khi gửi lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': categoryId,
      'name': name,
      'displayName': displayName,
      'sku': sku,
      'specifications': specifications,
      'thinkness': thinkness,
      'weight': weight,
      'description': description,
      'unit': unit,
      'packagingUnit': packagingUnit,
      'unitsPerPack': unitsPerPack,
      'billableUnit': billableUnit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'status': status,
    };
  }
}
