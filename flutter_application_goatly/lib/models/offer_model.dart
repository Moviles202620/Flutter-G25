class OfferModel {
  final String id;
  final String title;
  final String category;
  final int valueCop;
  final DateTime dateTime;
  final int durationHours;
  final bool isOnSite;

  OfferModel({
    required this.id,
    required this.title,
    required this.category,
    required this.valueCop,
    required this.dateTime,
    required this.durationHours,
    required this.isOnSite,
  });
}
