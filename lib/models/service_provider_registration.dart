class ServiceProviderRegistration {
  String? name;
  String? email;
  String? password;
  String? phoneNumber;
  List<String> services = [];
  String? experience;
  String? serviceArea;
  String? workingHour;
  String? serviceLicense;
  String? passport;
  String? cv;
  String? mainProfession;
  String role = 'serviceProvider';
  int? hourlyRate;
  int? minimumHour;
  bool? isNegotiable;

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'services': services,
      'experience': experience,
      'serviceArea': serviceArea,
      'workingHour': workingHour,
      'serviceLicense': serviceLicense,
      'passport': passport,
      'cv': cv,
      'mainProfession': mainProfession,
      'hourlyRate': hourlyRate,
      'minimumHour': minimumHour,
      'isNegotiable': isNegotiable,
    };
  }

  @override
  String toString() {
    return 'ServiceProviderRegistration(role: $role, name: $name, email: $email, phoneNumber: $phoneNumber, services: $services, experience: $experience, serviceArea: $serviceArea, workingHour: $workingHour, serviceLicense: $serviceLicense, passport: $passport, cv: $cv, mainProfession: $mainProfession, hourlyRate: $hourlyRate, minimumHour: $minimumHour, isNegotiable: $isNegotiable)';
  }
}
