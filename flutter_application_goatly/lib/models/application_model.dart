enum ApplicationStatus { pending, accepted, rejected }

class ApplicationModel {
  final String id;
  final String applicantName;
  final String applicantInitials;
  final String offerId;
  final String offerTitle;
  final DateTime createdAt;
  ApplicationStatus status;

  ApplicationModel({
    required this.id,
    required this.applicantName,
    required this.applicantInitials,
    required this.offerId,
    required this.offerTitle,
    required this.createdAt,
    required this.status,
  });
}
