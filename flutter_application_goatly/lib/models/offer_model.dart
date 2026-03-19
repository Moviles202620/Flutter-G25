class OfferModel {
  final String id;
  final String title;
  final String description;
  final String requirements;
  final String category;
  final int valueCop;
  final DateTime dateTime;
  final DateTime? deadline;
  final int durationHours;
  final bool isOnSite;
  final String location;

  OfferModel({
    required this.id,
    required this.title,
    this.description = '',
    this.requirements = '',
    required this.category,
    required this.valueCop,
    required this.dateTime,
    this.deadline,
    required this.durationHours,
    required this.isOnSite,
    this.location = '',
  });

  factory OfferModel.fromJson(Map<String, dynamic> j) => OfferModel(
        id: j['id'].toString(),
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        requirements: j['requirements'] as String? ?? '',
        category: j['category'] as String,
        valueCop: j['value_cop'] as int,
        dateTime: DateTime.parse(j['date_time'] as String),
        deadline: j['deadline'] != null
            ? DateTime.parse(j['deadline'] as String)
            : null,
        durationHours: j['duration_hours'] as int,
        isOnSite: j['is_on_site'] as bool,
        location: j['location'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
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
