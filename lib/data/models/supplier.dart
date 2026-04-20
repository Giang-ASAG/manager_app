class Supplier {
  final int? id;
  final String name;
  final String? contactPerson;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String status;
  final String? createdAt;

  Supplier({
    this.id,
    required this.name,
    this.contactPerson,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.status = 'Active',
    this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'],
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'status': status,
    };
  }
}