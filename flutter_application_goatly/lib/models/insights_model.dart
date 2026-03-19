class InsightsModel {
  final int totalOffers;
  final int totalApplications;
  final double overallAcceptanceRate;
  final String mostPopularOffer;
  final int mostPopularOfferApplications;
  final String leastPopularOffer;
  final int leastPopularOfferApplications;
  final double avgApplicationsPerOffer;

  InsightsModel({
    required this.totalOffers,
    required this.totalApplications,
    required this.overallAcceptanceRate,
    required this.mostPopularOffer,
    required this.mostPopularOfferApplications,
    required this.leastPopularOffer,
    required this.leastPopularOfferApplications,
    required this.avgApplicationsPerOffer,
  });

  factory InsightsModel.fromJson(Map<String, dynamic> j) => InsightsModel(
        totalOffers: j['total_offers'] as int,
        totalApplications: j['total_applications'] as int,
        overallAcceptanceRate:
            (j['overall_acceptance_rate'] as num).toDouble(),
        mostPopularOffer: j['most_popular_offer'] as String,
        mostPopularOfferApplications:
            j['most_popular_offer_applications'] as int,
        leastPopularOffer: j['least_popular_offer'] as String,
        leastPopularOfferApplications:
            j['least_popular_offer_applications'] as int,
        avgApplicationsPerOffer:
            (j['avg_applications_per_offer'] as num).toDouble(),
      );
}
