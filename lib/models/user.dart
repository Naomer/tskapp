class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isPhoneNumberVerified;
  final String role;
  final List<dynamic> services;
  final List<dynamic> paymentMethod;
  final int jobsCompleted;
  final Map<String, dynamic> ratings;
  final String? profileImage;
  final String? country;
  final String? dateOfBirth;
  final String? bio;

  double? get averageRating => ratings['averageRating']?.toDouble();

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isPhoneNumberVerified,
    required this.role,
    required this.services,
    required this.paymentMethod,
    required this.jobsCompleted,
    required this.ratings,
    this.profileImage,
    this.country,
    this.dateOfBirth,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isPhoneNumberVerified: json['isPhoneNumberVerified'] ?? false,
      role: json['role'] ?? '',
      services: json['services'] ?? [],
      paymentMethod: json['paymentMethod'] ?? [],
      jobsCompleted: json['jobsCompleted'] ?? 0,
      ratings: json['ratings'] ?? {},
      profileImage: json['profileImage'],
      country: json['country'],
      dateOfBirth: json['dateOfBirth'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'isPhoneNumberVerified': isPhoneNumberVerified,
      'role': role,
      'services': services,
      'paymentMethod': paymentMethod,
      'jobsCompleted': jobsCompleted,
      'ratings': ratings,
      'profileImage': profileImage,
      'country': country,
      'dateOfBirth': dateOfBirth,
      'bio': bio,
    };
  }
}
