class ApplicationSearchModel {
  final int id;
  final int offerId;
  final String offerTitle;
  final String applicantName;
  final String career;
  final int semester;
  final double gpa;
  final String availability;
  final String status;
  final DateTime createdAt;

  const ApplicationSearchModel({
    required this.id,
    required this.offerId,
    required this.offerTitle,
    required this.applicantName,
    required this.career,
    required this.semester,
    required this.gpa,
    required this.availability,
    required this.status,
    required this.createdAt,
  });

  factory ApplicationSearchModel.fromJson(Map<String, dynamic> json) {
    return ApplicationSearchModel(
      id: json['id'] as int,
      offerId: json['offer_id'] as int,
      offerTitle: json['offer_title'] as String,
      applicantName: json['applicant_name'] as String,
      career: json['career'] as String,
      semester: json['semester'] as int,
      gpa: (json['gpa'] as num).toDouble(),
      availability: json['availability'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get initials {
    final parts = applicantName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
