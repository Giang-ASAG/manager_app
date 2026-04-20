class Branch {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String status;

  Branch({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    required this.status,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      status: json['status'] ?? 'Active',
    );
  }
}