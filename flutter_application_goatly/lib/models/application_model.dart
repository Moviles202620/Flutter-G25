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
  final double gpa;
  final int semester;
  final String career;
  final String availability; // 'full_time' | 'part_time' | 'flexible'
  final String motivationLetter;

  // ── Rating / completion (Feature 8) ──────────────────────────────────────
  bool isCompleted;
  double? rating;            // overall 1.0 – 5.0
  String? ratingFeedback;
  double? ratingPunctuality;
  double? ratingQuality;
  double? ratingAttitude;
  DateTime? ratedAt;

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
    this.isCompleted = false,
    this.rating,
    this.ratingFeedback,
    this.ratingPunctuality,
    this.ratingQuality,
    this.ratingAttitude,
    this.ratedAt,
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
      isCompleted: j['is_completed'] as bool? ?? false,
      rating: (j['rating'] as num?)?.toDouble(),
      ratingFeedback: j['rating_feedback'] as String?,
      ratingPunctuality: (j['rating_punctuality'] as num?)?.toDouble(),
      ratingQuality: (j['rating_quality'] as num?)?.toDouble(),
      ratingAttitude: (j['rating_attitude'] as num?)?.toDouble(),
      ratedAt: j['rated_at'] != null
          ? DateTime.parse(j['rated_at'] as String)
          : null,
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
        'is_completed': isCompleted,
        'rating': rating,
        'rating_feedback': ratingFeedback,
        'rating_punctuality': ratingPunctuality,
        'rating_quality': ratingQuality,
        'rating_attitude': ratingAttitude,
        'rated_at': ratedAt?.toIso8601String(),
      };
}
