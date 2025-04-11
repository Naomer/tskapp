class Job {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isEmergency;
  final String status;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isEmergency,
    required this.status,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      isEmergency: json['isEmergency'] ?? false,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class JobApplication {
  final String id;
  final Job job;
  final int bidAmount;
  final DateTime proposedCompletionDate;
  final String status;
  final String message;
  final DateTime createdAt;

  JobApplication({
    required this.id,
    required this.job,
    required this.bidAmount,
    required this.proposedCompletionDate,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    final appliedDate = DateTime.parse(json['appliedDate']);

    // Create a Job object from the flattened job data
    final job = Job(
      id: '', // API doesn't provide job ID
      title: json['jobTitle'] ?? '',
      description: json['jobDescription'] ?? '',
      category: '', // API doesn't provide category
      isEmergency: false, // API doesn't provide isEmergency
      status: 'pending', // Default status
      createdAt: appliedDate,
    );

    return JobApplication(
      id: '', // API doesn't provide application ID
      job: job,
      bidAmount: int.tryParse(json['bidAmount'] ?? '0') ?? 0,
      proposedCompletionDate: json['proposedCompletionDate'] != null
          ? DateTime.parse(json['proposedCompletionDate'])
          : appliedDate,
      status: 'pending', // Default status
      message: json['message'] ?? '',
      createdAt: appliedDate,
    );
  }
}

class PostedBy {
  final String name;
  final String email;

  PostedBy({
    required this.name,
    required this.email,
  });

  factory PostedBy.fromJson(Map<String, dynamic> json) {
    return PostedBy(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
