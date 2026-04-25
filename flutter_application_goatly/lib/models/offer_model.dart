enum OfferState { upcoming, active, closed }

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String requirements;
  final String? category;
  final int valueCop;
  final DateTime dateTime;
  final DateTime? deadline;
  final int durationHours;
  final bool isOnSite;
  final String location;
  final DateTime? closedAt;
  final bool closedEarly;
  final String state; // 'upcoming' | 'active' | 'closed' from backend
  final DateTime createdAt;

  OfferModel({
    required this.id,
    required this.title,
    this.description = '',
    this.requirements = '',
    this.category,
    required this.valueCop,
    required this.dateTime,
    this.deadline,
    required this.durationHours,
    required this.isOnSite,
    this.location = '',
    this.closedAt,
    this.closedEarly = false,
    this.state = 'upcoming',
    required this.createdAt,
  });

  /// Parsed enum for use in switch expressions.
  OfferState get offerState => switch (state) {
        'active' => OfferState.active,
        'closed' => OfferState.closed,
        _ => OfferState.upcoming,
      };

  /// Computed end time (used as display fallback).
  DateTime get endTime => dateTime.add(Duration(hours: durationHours));

  factory OfferModel.fromJson(Map<String, dynamic> j) => OfferModel(
        id: j['id'].toString(),
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        requirements: j['requirements'] as String? ?? '',
        category: j['category'] as String?,
        valueCop: j['value_cop'] as int,
        dateTime: DateTime.parse(j['date_time'] as String),
        deadline: j['deadline'] != null ? DateTime.parse(j['deadline'] as String) : null,
        durationHours: j['duration_hours'] as int,
        isOnSite: j['is_on_site'] as bool,
        location: j['location'] as String? ?? '',
        closedAt: j['closed_at'] != null ? DateTime.parse(j['closed_at'] as String) : null,
        closedEarly: j['closed_early'] as bool? ?? false,
        state: j['state'] as String? ?? 'upcoming',
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'requirements': requirements,
        'category': category,
        'value_cop': valueCop,
        'date_time': dateTime.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'duration_hours': durationHours,
        'is_on_site': isOnSite,
        'location': location,
      };
}
