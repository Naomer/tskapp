class ServiceRequest {
  final String id;
  final String title;
  final String description;
  final String status;
  final String customerId;
  final String? providerId;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String serviceType;
  final String location;

  ServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.customerId,
    this.providerId,
    required this.createdAt,
    this.scheduledFor,
    required this.serviceType,
    required this.location,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      customerId: json['customerId'],
      providerId: json['providerId'],
      createdAt: DateTime.parse(json['createdAt']),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      serviceType: json['serviceType'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'customerId': customerId,
      'providerId': providerId,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'serviceType': serviceType,
      'location': location,
    };
  }
}
