class Warehouse {
  final int id;
  final int? branchId;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String status;

  Warehouse({
    required this.id,
    this.branchId,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.city,
    required this.status,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      branchId: json['branch_id'],
      code: json['code'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      status: json['status'] ?? 'Active',
    );
  }
}