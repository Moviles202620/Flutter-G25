enum ApplicationStatus { pending, accepted, rejected }

class ApplicationModel {
  final String id;
  final String applicantName;
  final String applicantInitials;
  final String offerId;
  final String offerTitle;
  final DateTime createdAt;
  ApplicationStatus status;

  // Rich applicant data (populated from backend)
  final double gpa;          // 0.0 – 5.0 Colombian scale
  final int semester;        // 1 – 10
  final String career;
  final String availability; // 'full_time' | 'part_time' | 'flexible'
  final String motivationLetter;

  ApplicationModel({
    required this.id,
    required this.applicantName,
    required this.applicantInitials,
    required this.offerId,
    required this.offerTitle,
    required this.createdAt,
    required this.status,
    this.gpa = 0.0,
    this.semester = 1,
    this.career = '',
    this.availability = 'flexible',
    this.motivationLetter = '',
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> j) {
    final name = j['applicant_name'] as String;
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : parts[0].substring(0, 2);

    return ApplicationModel(
      id: j['id'].toString(),
      applicantName: name,
      applicantInitials: initials.toUpperCase(),
      offerId: j['offer_id'].toString(),
      offerTitle: j['offer_title'] as String? ?? '',
      createdAt: DateTime.parse(j['created_at'] as String),
      status: _statusFromString(j['status'] as String? ?? 'pending'),
      gpa: (j['gpa'] as num?)?.toDouble() ?? 0.0,
      semester: j['semester'] as int? ?? 1,
      career: j['career'] as String? ?? '',
      availability: j['availability'] as String? ?? 'flexible',
      motivationLetter: j['motivation_letter'] as String? ?? '',
    );
  }

  static ApplicationStatus _statusFromString(String s) => switch (s) {
        'accepted' => ApplicationStatus.accepted,
        'rejected' => ApplicationStatus.rejected,
        _ => ApplicationStatus.pending,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicant_name': applicantName,
        'offer_id': offerId,
        'offer_title': offerTitle,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'gpa': gpa,
        'semester': semester,
        'career': career,
        'availability': availability,
        'motivation_letter': motivationLetter,
      };
}
