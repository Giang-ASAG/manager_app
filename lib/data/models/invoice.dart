import 'package:manager/data/models/payments.dart';
import 'package:manager/data/models/invoice_item.dart'; // Đảm bảo bạn đã có model này

class Invoice {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final String? customerPhone; // Thêm từ JSON
  final String? customerAddress; // Thêm từ JSON
  final DateTime date;
  final DateTime? createdAt;
  final double subtotal;
  final double discount;
  final double total;
  final double amount;
  final double paymentReceived;
  final double balanceDue;
  final String status;
  final List<Payment> payments;
  final List<InvoiceItem> items; // Thêm danh sách items từ JSON

  Invoice({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.date,
    this.createdAt,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.amount,
    required this.paymentReceived,
    required this.balanceDue,
    required this.status,
    required this.payments,
    required this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    print("DEBUG DATA TYPE: ${json.runtimeType}");
    print("DEBUG DATA CONTENT: $json");
    // Hàm phụ để xử lý các trường có thể bị trả về dạng Object/Map thay vì String
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is Map)
        return value.toString(); // Chống lỗi Map không phải String
      return value.toString();
    }

    return Invoice(
      id: json['id'] ?? 0,
      invoiceNumber: parseString(json['invoiceNumber']),
      customerId: json['customerId'] is int ? json['customerId'] : null,
      customerName: parseString(json['customerName']),
      customerPhone: parseString(json['customerPhone']),
      customerAddress: parseString(json['customerAddress']),

      // Parse ngày tháng an toàn
      date: json['date'] != null
          ? (json['date'] is String
              ? DateTime.parse(json['date'])
              : DateTime.now())
          : DateTime.now(),
      createdAt: json['createdAt'] != null && json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : null,

      // Ép kiểu số thực an toàn
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentReceived: (json['paymentReceived'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0.0,

      status: parseString(json['status'] ?? 'Draft'),

      // Parse List an toàn (tránh lỗi as List)
      payments: (json['payments'] is List)
          ? (json['payments'] as List).map((i) => Payment.fromJson(i)).toList()
          : [],
      items: (json['items'] is List)
          ? (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      // Format về YYYY-MM-DD để gửi lên server
      'date': date.toIso8601String().split('T')[0],
      'createdAt': createdAt?.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'amount': amount,
      'paymentReceived': paymentReceived,
      'balanceDue': balanceDue,
      'status': status,
      // Map list objects sang list json
      'payments': payments.map((p) => p.toJson()).toList(),
      'items': items
          .map(
            (e) => e.toJson(),
          )
          .toList()
    };
  }
}
