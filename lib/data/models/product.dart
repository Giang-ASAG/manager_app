// lib/features/product/data/models/product.dart

class Product {
  final int id;
  final String? category;
  final String name;
  final String? displayName;
  final String? sku;
  final String? specifications;
  final String? thickness; // Sửa chính tả: thinkness → thickness
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

  // Thêm field quantity vì JSON có trường này
  final int? quantity;

  Product({
    required this.id,
    this.category,
    required this.name,
    this.displayName,
    this.sku,
    this.specifications,
    this.thickness,
    this.weight,
    this.description,
    required this.unit,
    this.packagingUnit,
    this.unitsPerPack,
    this.billableUnit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.quantity,
    this.status = 'Active', // Default value
    this.createdAt,
    this.updatedAt,
  });

  // Từ JSON (khi gọi API)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      category: json['category'],
      name: json['name'] ?? '',
      displayName: json['displayName'],
      sku: json['sku'],
      specifications: json['specifications'],
      thickness: json['thinkness'] ?? json['thickness'],
      // hỗ trợ cả 2 tên
      weight: _parseDouble(json['weight']),
      description: json['description'],
      unit: json['unit'] ?? '',
      packagingUnit: json['packagingUnit'],
      unitsPerPack: json['unitsPerPack'],
      billableUnit: json['billableUnit'],
      purchasePrice: _parseDouble(json['purchasePrice']) ?? 0.0,
      sellingPrice: _parseDouble(json['sellingPrice']) ?? 0.0,
      quantity: json['quantity'],
      status: json['status'] ?? 'Active',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  // Chuyển sang JSON (khi gửi lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'displayName': displayName,
      'sku': sku,
      'specifications': specifications,
      'thickness': thickness, // dùng tên đúng
      'weight': weight,
      'description': description,
      'unit': unit,
      'packagingUnit': packagingUnit,
      'unitsPerPack': unitsPerPack,
      'billableUnit': billableUnit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'status': status,
      // Không gửi createdAt/updatedAt lên server trừ khi cần
    };
  }

  // Helper functions để code sạch và an toàn hơn
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
