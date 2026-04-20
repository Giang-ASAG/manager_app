// lib/features/category/data/models/category.dart
class Category {
  final int id;
  final String name;
  final String? description;
  final String status;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}