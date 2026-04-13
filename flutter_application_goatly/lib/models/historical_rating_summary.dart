class HistoricalRatingSummary {
  final double averageRating;
  /// Weighted average: quality 40%, punctuality 30%, attitude 30%.
  final double weightedRating;
  final int ratedJobsCount;
  final double? lastRating;
  final DateTime? lastRatedAt;

  const HistoricalRatingSummary({
    required this.averageRating,
    required this.weightedRating,
    required this.ratedJobsCount,
    this.lastRating,
    this.lastRatedAt,
  });

  const HistoricalRatingSummary.empty()
      : averageRating = 0,
        weightedRating = 0,
        ratedJobsCount = 0,
        lastRating = null,
        lastRatedAt = null;

  bool get hasHistory => ratedJobsCount > 0;
}
