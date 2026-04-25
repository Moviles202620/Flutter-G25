class TopApplicantModel {
  final String applicantName;
  final String career;
  final int semester;
  final double gpa;
  final int totalApplications;
  final List<String> offersApplied;
  final Map<String, int> statusSummary;

  const TopApplicantModel({
    required this.applicantName,
    required this.career,
    required this.semester,
    required this.gpa,
    required this.totalApplications,
    required this.offersApplied,
    required this.statusSummary,
  });

  factory TopApplicantModel.fromJson(Map<String, dynamic> json) {
    return TopApplicantModel(
      applicantName: json['applicant_name'] as String,
      career: json['career'] as String,
      semester: json['semester'] as int,
      gpa: (json['gpa'] as num).toDouble(),
      totalApplications: json['total_applications'] as int,
      offersApplied: List<String>.from(json['offers_applied'] as List),
      statusSummary: Map<String, int>.from(
        (json['status_summary'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'applicant_name': applicantName,
        'career': career,
        'semester': semester,
        'gpa': gpa,
        'total_applications': totalApplications,
        'offers_applied': offersApplied,
        'status_summary': statusSummary,
      };

  String get initials {
    final parts = applicantName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
