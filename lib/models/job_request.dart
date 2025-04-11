class JobRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isEmergency;
  final String status;
  final DateTime createdAt;
  final String postedBy;

  JobRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isEmergency,
    required this.status,
    required this.createdAt,
    required this.postedBy,
  });

  factory JobRequest.fromJson(Map<String, dynamic> json) {
    return JobRequest(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      isEmergency: json['isEmergency'] ?? false,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      postedBy: json['postedBy'] ?? '',
    );
  }
}

class ServiceTaker {
  final String id;
  final String name;
  final String email;

  ServiceTaker({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ServiceTaker.fromJson(Map<String, dynamic> json) {
    return ServiceTaker(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class JobDetails {
  final String title;
  final String description;
  final String location;

  JobDetails({
    required this.title,
    required this.description,
    required this.location,
  });

  factory JobDetails.fromJson(Map<String, dynamic> json) {
    return JobDetails(
      title: json['title'],
      description: json['description'],
      location: json['location'],
    );
  }
}
