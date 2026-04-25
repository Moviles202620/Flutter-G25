class GpaAnalyticsModel {
  final int offerId;
  final String offerTitle;
  final String? category;
  final int totalApplicants;
  final double averageGpa;
  final double minGpa;
  final double maxGpa;

  const GpaAnalyticsModel({
    required this.offerId,
    required this.offerTitle,
    this.category,
    required this.totalApplicants,
    required this.averageGpa,
    required this.minGpa,
    required this.maxGpa,
  });

  factory GpaAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return GpaAnalyticsModel(
      offerId: json['offer_id'] as int,
      offerTitle: json['offer_title'] as String,
      category: json['category'] as String?,
      totalApplicants: json['total_applicants'] as int,
      averageGpa: (json['average_gpa'] as num).toDouble(),
      minGpa: (json['min_gpa'] as num).toDouble(),
      maxGpa: (json['max_gpa'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'offer_id': offerId,
        'offer_title': offerTitle,
        'category': category,
        'total_applicants': totalApplicants,
        'average_gpa': averageGpa,
        'min_gpa': minGpa,
        'max_gpa': maxGpa,
      };
}
