import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../services/hive_cache_service.dart';

// ── Isolate helpers ───────────────────────────────────────────────────────────

/// Data model produced by the isolate computation.
class _LifecycleStats {
  final double averageDays;
  final int minDays;
  final int maxDays;
  final int totalOffers;

  const _LifecycleStats({
    required this.averageDays,
    required this.minDays,
    required this.maxDays,
    required this.totalOffers,
  });
}

/// Top-level function required by compute() — runs in a separate Dart isolate.
/// Parses and validates the raw JSON map returned by the backend so the main
/// UI thread is never blocked by JSON decoding or type-casting.
_LifecycleStats _computeLifecycleStats(Map<String, dynamic> raw) {
  final averageDays = (raw['average_days'] as num?)?.toDouble() ?? 0.0;
  final minDays = (raw['min_days'] as num?)?.toInt() ?? 0;
  final maxDays = (raw['max_days'] as num?)?.toInt() ?? 0;
  final totalOffers = (raw['total_offers'] as num?)?.toInt() ?? 0;
  return _LifecycleStats(
    averageDays: averageDays,
    minDays: minDays,
    maxDays: maxDays,
    totalOffers: totalOffers,
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// BQ11 (Santiago Reyes): Offer Lifecycle Analytics Screen.
///
/// Displays: average, min, max days an offer stays open + total closed offers.
///
/// Cache strategy (LRU → Hive → SharedPreferences):
///   1. Tier 1 (LRU, in-memory) — served instantly, no I/O.
///   2. Tier 2 (Hive, fast disk) — survives hot-restart.
///   3. Tier 3 (SharedPreferences) — survives cold-start.
///   SharedPreferences key: cached_analytics_bq11_offer_lifecycle
///
/// Offline: renders last cached data with a "Last updated: [timestamp]" banner.
class OfferLifecycleScreen extends StatefulWidget {
  const OfferLifecycleScreen({super.key});

  @override
  State<OfferLifecycleScreen> createState() => _OfferLifecycleScreenState();
}

class _OfferLifecycleScreenState extends State<OfferLifecycleScreen> {
  _LifecycleStats? _stats;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  // Cache key used by all three tiers.
  static const _cacheKey = 'bq11_offer_lifecycle';

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  // ── Cache-first load ──────────────────────────────────────────────────────

  Future<void> _loadWithCache() async {
    // Tier 2: Hive (synchronous after init — no await needed for reads).
    final hiveData = HiveCacheService.loadAnalytics(_cacheKey);
    final hiveTs = HiveCacheService.getTimestamp(_cacheKey);
    if (hiveData != null) {
      final s = await compute(_computeLifecycleStats, hiveData);
      if (mounted) setState(() { _stats = s; _lastUpdated = hiveTs; });
    } else {
      // Tier 3: SharedPreferences (LRU is checked internally first).
      final cached = await CacheService.loadAnalytics(_cacheKey);
      final ts = await CacheService.getAnalyticsTimestamp(_cacheKey);
      if (cached != null) {
        final s = await compute(_computeLifecycleStats, cached);
        if (mounted) setState(() { _stats = s; _lastUpdated = ts; });
      } else {
        if (mounted) setState(() => _loading = true);
      }
    }
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final raw = await ApiService.getOfferLifecycle();
      // compute() runs _computeLifecycleStats in a background isolate so the
      // main thread is not blocked by JSON parsing or arithmetic.
      final s = await compute(_computeLifecycleStats, raw);
      await HiveCacheService.saveAnalytics(_cacheKey, raw);
      await CacheService.saveAnalytics(_cacheKey, raw);
      final ts = await CacheService.getAnalyticsTimestamp(_cacheKey);
      if (mounted) {
        setState(() { _stats = s; _lastUpdated = ts; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_stats == null) _error = 'Sin conexión y sin datos en caché.';
        });
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtTimestamp(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$min';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isOnline = context.watch<AppState>().isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_error != null && _stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? AppColors.darkGreyText : AppColors.greyText),
            const SizedBox(height: 12),
            Text(context.t('no_cache_offline')),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadWithCache,
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

    if (_stats == null && _loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    final stats = _stats;

    return Column(
      children: [
        // Offline banner
        if (!isOnline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sin conexión — mostrando datos en caché',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFromNetwork,
            color: AppColors.primaryYellow,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _BQ11Header(
                  isDark: isDark,
                  lastUpdated: _fmtTimestamp(_lastUpdated),
                  loading: _loading,
                  context: context,
                ),
                if (stats != null)
                  _BQ11Card(stats: stats, isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _BQ11Header extends StatelessWidget {
  final bool isDark;
  final String lastUpdated;
  final bool loading;
  final BuildContext context;

  const _BQ11Header({
    required this.isDark,
    required this.lastUpdated,
    required this.loading,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final mutedText = isDark ? AppColors.darkGreyText : AppColors.greyText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('offer_lifecycle_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('offer_lifecycle_subtitle'),
            style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
          ),
          if (lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update_rounded, size: 13, color: AppColors.greyText),
                const SizedBox(width: 5),
                Text(
                  '${context.t('last_updated')}: $lastUpdated',
                  style: const TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.primaryYellow),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _BQ11Card extends StatelessWidget {
  final _LifecycleStats stats;
  final bool isDark;

  const _BQ11Card({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BQ label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BQ11',
              style: TextStyle(
                color: Color(0xFF9A5B00),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            context.t('offer_lifecycle_title'),
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('offer_lifecycle_subtitle'),
            style: const TextStyle(
                color: AppColors.greyText, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Main metric — average days
          Center(
            child: Column(
              children: [
                Text(
                  stats.averageDays.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryYellow,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t('offer_lifecycle_avg_label'),
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.greyText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sub-metrics row
          Row(
            children: [
              Expanded(
                child: _SubMetric(
                  value: stats.minDays.toString(),
                  label: context.t('offer_lifecycle_min'),
                  color: AppColors.success,
                  borderColor: borderColor,
                ),
              ),
              Container(width: 1, height: 48, color: borderColor),
              Expanded(
                child: _SubMetric(
                  value: stats.maxDays.toString(),
                  label: context.t('offer_lifecycle_max'),
                  color: AppColors.danger,
                  borderColor: borderColor,
                ),
              ),
              Container(width: 1, height: 48, color: borderColor),
              Expanded(
                child: _SubMetric(
                  value: stats.totalOffers.toString(),
                  label: context.t('offer_lifecycle_total'),
                  color: AppColors.primaryYellow,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color borderColor;

  const _SubMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.greyText, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
