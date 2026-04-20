class Payment {
  final int id;
  final DateTime date;
  final double amount;
  final String method;
  final String? reference;
  final String? notes;
  final bool isInitial;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
    this.isInitial = false,
  });

  // Chuyển từ JSON (API) sang Object Flutter
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      // Xử lý parse ngày tháng an toàn
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      // Đảm bảo amount luôn là double kể cả khi server trả về int
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] ?? '',
      reference: json['reference'],
      notes: json['notes'],
      isInitial: json['isInitial'] ?? false,
    );
  }

  // Chuyển từ Object Flutter sang JSON để gửi lên API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // Lấy định dạng yyyy-MM-dd
      'amount': amount,
      'method': method,
      'reference': reference,
      'notes': notes,
      'isInitial': isInitial,
    };
  }
}