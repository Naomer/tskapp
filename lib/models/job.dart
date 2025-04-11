class Job {
  final String id;
  final String title;
  final String description;
  final Category category;
  final PostedBy postedBy;
  final bool isEmergency;
  final String status;
  final Location location;
  final String budget;
  final DateTime completionDate;
  final List<Applicant> applicants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acceptedApplicant;
  final String formattedCompletionDate;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.postedBy,
    required this.isEmergency,
    required this.status,
    required this.location,
    required this.budget,
    required this.completionDate,
    required this.applicants,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedApplicant,
    required this.formattedCompletionDate,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      category: Category.fromJson(json['category']),
      postedBy: PostedBy.fromJson(json['postedBy']),
      isEmergency: json['isEmergency'],
      status: json['status'],
      location: Location.fromJson(json['location']),
      budget: json['budget'],
      completionDate: DateTime.parse(json['completionDate']),
      applicants: (json['applicants'] as List)
          .map((x) => Applicant.fromJson(x))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      acceptedApplicant: json['acceptedApplicant'],
      formattedCompletionDate: json['formattedCompletionDate'],
    );
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
    );
  }
}

class PostedBy {
  final String id;

  PostedBy({required this.id});

  factory PostedBy.fromJson(Map<String, dynamic> json) {
    return PostedBy(
      id: json['_id'],
    );
  }
}

class Location {
  final String address;
  final List<double> coordinates;

  Location({required this.address, required this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    final List<dynamic> coords = json['coordinates'] as List;
    return Location(
      address: json['address'],
      coordinates: coords.map<double>((e) => (e as num).toDouble()).toList(),
    );
  }
}

class Applicant {
  final String userId;
  final DateTime applicationDate;
  final String message;
  final String id;

  Applicant({
    required this.userId,
    required this.applicationDate,
    required this.message,
    required this.id,
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      userId: json['userId'],
      applicationDate: DateTime.parse(json['applicationDate']),
      message: json['message'],
      id: json['_id'],
    );
  }
}
