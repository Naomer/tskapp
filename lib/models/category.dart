class Category {
  final String id;
  final String name;
  final String description;
  final String? parentCategory;
  final CategoryImage? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.parentCategory,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      parentCategory: json['parentCategory'],
      image:
          json['image'] != null ? CategoryImage.fromJson(json['image']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class CategoryImage {
  final String id;
  final String data;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryImage({
    required this.id,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) {
    return CategoryImage(
      id: json['_id'] ?? '',
      data: json['data'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
