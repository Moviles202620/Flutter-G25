enum NotificationType {
  newApplication,   // Staff: a student applied to your offer
  appAccepted,      // Staff confirmation: accepted [name]
  appRejected,      // Staff confirmation: rejected [name]
  jobMatch,         // Student-side simulation: Ana received a relevant job alert
  offerPublished,   // Staff: offer went live
  ratingSubmitted,  // Staff: you rated [name]
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  /// ID of the related offer or application (used for navigation on tap).
  final String? relatedId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });
}
