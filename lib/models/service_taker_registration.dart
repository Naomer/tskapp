class ServiceTakerRegistration {
  String? name;
  String? email;
  String? password;
  String? phoneNumber;
  String role = 'serviceTaker';
  String mainProfession = 'serviceTaker';

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  String toString() {
    return 'ServiceTakerRegistration(role: $role, name: $name, email: $email, phoneNumber: $phoneNumber)';
  }
}
