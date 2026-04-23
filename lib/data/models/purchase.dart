import 'package:manager/data/models/payments.dart';
import 'purchase_item.dart';

class Purchase {
  final int id;
  final String purchaseNumber;
  final int supplierId;
  final String supplierName;
  final int warehouseId;
  final String warehouseName;
  final DateTime date;
  final double subtotal;
  final double discount;
  final double total;
  final double paymentMade;
  final double balanceDue;
  final double amount;
  final String status;
  final DateTime createdAt;
  final List<PurchaseItem> items;
  final List<Payment> payments;

  const Purchase({
    required this.id,
    required this.purchaseNumber,
    required this.supplierId,
    required this.supplierName,
    required this.warehouseId,
    required this.warehouseName,
    required this.date,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMade,
    required this.balanceDue,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.payments,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as int,
      purchaseNumber: json['purchaseNumber'] as String,
      supplierId: json['supplierId'] as int,
      supplierName: json['supplierName'] as String,
      warehouseId: json['warehouseId'] as int,
      warehouseName: json['warehouseName'] as String,
      date: DateTime.parse(json['date'] as String),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMade: (json['paymentMade'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'purchaseNumber': purchaseNumber,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'warehouseId': warehouseId,
        'warehouseName': warehouseName,
        'date': date.toIso8601String().split('T').first,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paymentMade': paymentMade,
        'balanceDue': balanceDue,
        'amount': amount,
        'status': status,
        'createdAt': createdAt.toIso8601String().split('T').first,
        'items': items.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
      };
}
