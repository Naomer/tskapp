class Provider {
  final String id;
  final String name;
  final String? image;
  final String? profession;
  final double? rating;

  Provider({
    required this.id,
    required this.name,
    this.image,
    this.profession,
    this.rating,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      profession: json['profession'],
      rating: json['rating']?.toDouble(),
    );
  }
}
