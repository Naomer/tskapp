class ServiceProvider {
  final String id;
  final String name;
  final String? profession;
  final String? imageUrl;
  final String? phoneNumber;
  final List<String> services;
  final String? experience;
  final String? serviceArea;
  final String? workingHour;
  final double? hourlyRate;
  final int? minimumHour;
  final bool? isNegotiable;
  final double? rating;
  final String? status;

  ServiceProvider({
    required this.id,
    required this.name,
    this.profession,
    this.imageUrl,
    this.phoneNumber,
    required this.services,
    this.experience,
    this.serviceArea,
    this.workingHour,
    this.hourlyRate,
    this.minimumHour,
    this.isNegotiable,
    this.rating,
    this.status,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      profession: json['mainProfession'],
      imageUrl: json['image'],
      phoneNumber: json['phoneNumber'],
      services: List<String>.from(json['services'] ?? []),
      experience: json['experience'],
      serviceArea: json['serviceArea'],
      workingHour: json['workingHour'],
      hourlyRate: json['hourlyRate']?.toDouble(),
      minimumHour: json['minimumHour'],
      isNegotiable: json['isNegotiable'],
      rating: json['ratings']?['averageRating']?.toDouble(),
      status: json['status'],
    );
  }
}
