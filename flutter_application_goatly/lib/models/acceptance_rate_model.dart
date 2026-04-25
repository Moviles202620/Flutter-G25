class AcceptanceRateModel {
  final int offerId;
  final String offerTitle;
  final String category;
  final int totalApplications;
  final int accepted;
  final int rejected;
  final int pending;
  final double acceptanceRate;

  AcceptanceRateModel({
    required this.offerId,
    required this.offerTitle,
    required this.category,
    required this.totalApplications,
    required this.accepted,
    required this.rejected,
    required this.pending,
    required this.acceptanceRate,
  });

  factory AcceptanceRateModel.fromJson(Map<String, dynamic> j) =>
      AcceptanceRateModel(
        offerId: j['offer_id'] as int,
        offerTitle: j['offer_title'] as String,
        category: j['category'] as String,
        totalApplications: j['total_applications'] as int,
        accepted: j['accepted'] as int,
        rejected: j['rejected'] as int,
        pending: j['pending'] as int,
        acceptanceRate: (j['acceptance_rate'] as num).toDouble(),
      );
}
