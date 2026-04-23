class Warehouse {
  final int id;
  final int branchId;
  final String branchName;
  final String code;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String status;
  final DateTime createdAt;

  Warehouse({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.code,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.status,
    required this.createdAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      branchId: json['branchId'],
      branchName: json['branchName'],
      code: json['code'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'branchName': branchName,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<Warehouse> listFromJson(List<dynamic> list) {
    return list.map((e) => Warehouse.fromJson(e)).toList();
  }
}