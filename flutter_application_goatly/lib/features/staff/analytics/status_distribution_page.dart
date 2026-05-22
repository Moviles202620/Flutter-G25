import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart'; // compute()
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../services/connectivity_service.dart';

// ── Top-level function so compute() can send it to a background isolate ──────
// Sorts per_offer list by total (descending) — keeps heavy work off the UI thread.
Map<String, dynamic> _processPayload(Map<String, dynamic> raw) {
  final perOffer = List<Map<String, dynamic>>.from(
    (raw['per_offer'] as List<dynamic>).cast<Map<String, dynamic>>(),
  );
  perOffer.sort((a, b) {
    final tA = (a['total'] as num?)?.toInt() ?? 0;
    final tB = (b['total'] as num?)?.toInt() ?? 0;
    return tB.compareTo(tA);
  });
  return {
    'semester': raw['semester'],
    'total_applications': raw['total_applications'],
    'distribution': raw['distribution'],
    'per_offer': perOffer,
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class StatusDistributionPage extends StatefulWidget {
  const StatusDistributionPage({super.key});

  @override
  State<StatusDistributionPage> createState() => _StatusDistributionPageState();
}

class _StatusDistributionPageState extends State<StatusDistributionPage> {
  static const _cacheKey = 'status_distribution';
  late Future<Map<String, dynamic>> _future;
  bool _servedFromCache = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Stale-while-revalidate + Isolate (compute):
  /// 1. Load from LRU/disk cache immediately — fast, offline-safe.
  /// 2. If offline and cache exists → return cache; otherwise throw NetworkException.
  /// 3. If online → fetch fresh data, sort in a background isolate, persist to cache.
  Future<Map<String, dynamic>> _load() async {
    final cached = await CacheService.loadAnalytics(_cacheKey);

    if (!ConnectivityService.isOnline) {
      if (cached != null) {
        _servedFromCache = true;
        return Map<String, dynamic>.from(cached);
      }
      throw const NetworkException();
    }

    try {
      final fresh = await ApiService.getStatusDistribution();
      // compute() runs _processPayload in a background isolate — no UI jank.
      final processed = await compute(_processPayload, fresh);
      await CacheService.saveAnalytics(_cacheKey, processed);
      _servedFromCache = false;
      return processed;
    } catch (_) {
      if (cached != null) {
        _servedFromCache = true;
        return Map<String, dynamic>.from(cached);
      }
      rethrow;
    }
  }

  void _reload() {
    setState(() {
      _servedFromCache = false;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryYellow),
                const SizedBox(height: 12),
                Text(context.t('loading')),
              ],
            ),
          );
        }

        // ── Error ────────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          final isNetwork =
              snapshot.error is NetworkException || !ConnectivityService.isOnline;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNetwork ? Icons.wifi_off_rounded : Icons.error_outline,
                  size: 48,
                  color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                ),
                const SizedBox(height: 12),
                Text(
                  isNetwork
                      ? context.t('no_cache_offline')
                      : context.t('error_loading'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.t('retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final distribution =
            (data['distribution'] as List<dynamic>).cast<Map<String, dynamic>>();
        final perOffer =
            (data['per_offer'] as List<dynamic>).cast<Map<String, dynamic>>();
        final semester = data['semester'] as String? ?? '';
        final totalApps = (data['total_applications'] as num?)?.toInt() ?? 0;

        // ── Empty ────────────────────────────────────────────────────────────
        if (totalApps == 0) {
          return Center(
            child: Text(
              context.t('no_status_data'),
              style: TextStyle(
                color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                fontSize: 16,
              ),
            ),
          );
        }

        // ── Main content ─────────────────────────────────────────────────────
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          color: AppColors.primaryYellow,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Offline banner
              if (_servedFromCache && !ConnectivityService.isOnline)
                _OfflineBanner(message: context.t('status_offline_banner')),

              // Last updated label
              _LastUpdatedLabel(cacheKey: _cacheKey, isDark: isDark, prefix: context.t('last_updated')),

              // Title + semester chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('status_distribution_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryYellow.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      semester,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.t('status_distribution_subtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 24),

              // Donut chart
              _DonutSection(
                distribution: distribution,
                totalApps: totalApps,
                isDark: isDark,
              ),

              const SizedBox(height: 28),

              // Per-offer breakdown header
              Text(
                context.t('per_offer_breakdown'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),

              // Offer cards
              ...perOffer.map(
                (row) => _OfferBreakdownCard(row: row, isDark: isDark),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Donut chart section ───────────────────────────────────────────────────────

class _DonutSection extends StatelessWidget {
  final List<Map<String, dynamic>> distribution;
  final int totalApps;
  final bool isDark;

  const _DonutSection({
    required this.distribution,
    required this.totalApps,
    required this.isDark,
  });

  Color _colorFor(String status) => switch (status) {
        'accepted' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => const Color(0xFFF5A623), // pending — amber/yellow
      };

  String _labelKey(String status, BuildContext context) => switch (status) {
        'accepted' => context.t('accepted_label'),
        'rejected' => context.t('rejected_label'),
        _ => context.t('pending_label'),
      };

  @override
  Widget build(BuildContext context) {
    final sections = distribution
        .where((d) => ((d['count'] as num?)?.toInt() ?? 0) > 0)
        .map((d) {
      final status = d['status'] as String;
      final pct = (d['percentage'] as num?)?.toDouble() ?? 0.0;
      return PieChartSectionData(
        value: pct,
        color: _colorFor(status),
        radius: 54,
        showTitle: false,
      );
    }).toList();

    // Fallback: if all zeros, show a single grey slice
    final chartSections = sections.isEmpty
        ? [PieChartSectionData(value: 1, color: AppColors.border, radius: 54, showTitle: false)]
        : sections;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: chartSections,
                  centerSpaceRadius: 66,
                  sectionsSpace: 3,
                  startDegreeOffset: -90,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalApps',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.t('total_applications'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: distribution.map((d) {
            final status = d['status'] as String;
            final count = (d['count'] as num?)?.toInt() ?? 0;
            final pct = (d['percentage'] as num?)?.toDouble() ?? 0.0;
            final color = _colorFor(status);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_labelKey(status, context)}: $count (${pct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkModeText : AppColors.darkText,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Per-offer breakdown card ───────────────────────────────────────────────────

class _OfferBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isDark;

  const _OfferBreakdownCard({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final title = row['offer_title'] as String? ?? '';
    final category = row['category'] as String? ?? '';
    final pending = (row['pending'] as num?)?.toInt() ?? 0;
    final accepted = (row['accepted'] as num?)?.toInt() ?? 0;
    final rejected = (row['rejected'] as num?)?.toInt() ?? 0;
    final total = (row['total'] as num?)?.toInt() ?? 0;

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final greyText = isDark ? AppColors.darkGreyText : AppColors.greyText;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(category,
                style: TextStyle(color: greyText, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusChip(
                label: context.t('pending_label'),
                count: pending,
                color: const Color(0xFFF5A623),
              ),
              _StatusChip(
                label: context.t('accepted_label'),
                count: accepted,
                color: AppColors.success,
              ),
              _StatusChip(
                label: context.t('rejected_label'),
                count: rejected,
                color: AppColors.danger,
              ),
              _StatusChip(
                label: context.t('total_applications'),
                count: total,
                color: greyText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final String message;
  const _OfflineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedLabel extends StatelessWidget {
  final String cacheKey;
  final bool isDark;
  final String prefix;

  const _LastUpdatedLabel({
    required this.cacheKey,
    required this.isDark,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: CacheService.getAnalyticsTimestamp(cacheKey),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '$prefix: ${snap.data}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkGreyText : AppColors.greyText,
            ),
          ),
        );
      },
    );
  }
}
