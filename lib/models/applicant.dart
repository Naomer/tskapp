class Applicant {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String mainProfession;
  final List<String> services;
  final String experience;
  final String serviceArea;
  final String workingHour;
  final String status;
  final DateTime createdAt;

  Applicant({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.mainProfession,
    required this.services,
    required this.experience,
    required this.serviceArea,
    required this.workingHour,
    required this.status,
    required this.createdAt,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      mainProfession: json['mainProfession'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      experience: json['experience'] ?? '',
      serviceArea: json['serviceArea'] ?? '',
      workingHour: json['workingHour'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
