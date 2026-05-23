import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../services/hive_cache_service.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _StaffMember {
  final int staffId;
  final String staffName;
  final String? department;
  final int offersInWindow;
  final int totalOffers;

  const _StaffMember({
    required this.staffId,
    required this.staffName,
    required this.department,
    required this.offersInWindow,
    required this.totalOffers,
  });

  factory _StaffMember.fromJson(Map<String, dynamic> json) => _StaffMember(
        staffId: (json['staff_id'] as num).toInt(),
        staffName: json['staff_name'] as String? ?? '',
        department: json['department'] as String?,
        offersInWindow: (json['offers_in_window'] as num?)?.toInt() ?? 0,
        totalOffers: (json['total_offers'] as num?)?.toInt() ?? 0,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// BQ17 (Guillermo Hernández): Staff Activity Leaderboard.
///
/// Answers: "Which staff members have the highest offer-creation rate in the
/// last 30 days?" — helps administrators spot engagement patterns and detect
/// drop-offs in offer publication among staff.
///
/// Multi-threading: fetched in parallel with other BQs via Future.wait
/// inside AnalyticsShell._prefetchGuillermosData().
///
/// Cache strategy (LRU → Hive → SharedPreferences):
///   1. Tier 1 (LRU, in-memory) — served instantly, no I/O.
///   2. Tier 2 (Hive, fast disk) — survives hot-restart.
///   3. Tier 3 (SharedPreferences) — survives cold-start.
///   SharedPreferences key: cached_analytics_bq17_staff_activity
///
/// Eventual connectivity: renders last cached data with offline banner +
/// "Last updated: [timestamp]" label.
class StaffActivityLeaderboardScreen extends StatefulWidget {
  const StaffActivityLeaderboardScreen({super.key});

  @override
  State<StaffActivityLeaderboardScreen> createState() =>
      _StaffActivityLeaderboardScreenState();
}

class _StaffActivityLeaderboardScreenState
    extends State<StaffActivityLeaderboardScreen> {
  List<_StaffMember>? _members;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  // Cache key used across all three storage tiers.
  static const _cacheKey = 'bq17_staff_activity';

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
      final members = _parseMembers(hiveData);
      if (mounted) setState(() { _members = members; _lastUpdated = hiveTs; });
    } else {
      // Tier 3: SharedPreferences (LRU is checked internally first).
      final cached = await CacheService.loadAnalytics(_cacheKey);
      final ts = await CacheService.getAnalyticsTimestamp(_cacheKey);
      if (cached != null) {
        final members = _parseMembers(cached);
        if (mounted) setState(() { _members = members; _lastUpdated = ts; });
      } else {
        if (mounted) setState(() => _loading = true);
      }
    }
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      // Multi-threading: getStaffActivity() runs concurrently with other
      // analytics fetches via Future.wait in AnalyticsShell._prefetchGuillermosData().
      final raw = await ApiService.getStaffActivity(days: 30);
      final wrapper = <String, dynamic>{'members': raw};
      await HiveCacheService.saveAnalytics(_cacheKey, wrapper);
      await CacheService.saveAnalytics(_cacheKey, wrapper);
      final ts = await CacheService.getAnalyticsTimestamp(_cacheKey);
      final members = raw.map(_StaffMember.fromJson).toList();
      if (mounted) {
        setState(() { _members = members; _lastUpdated = ts; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_members == null) _error = 'Sin conexión y sin datos en caché.';
        });
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<_StaffMember> _parseMembers(Map<String, dynamic> data) {
    final raw = data['members'] as List<dynamic>? ?? [];
    return raw
        .map((e) => _StaffMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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

    // Error state — no cache and no network
    if (_error != null && _members == null) {
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

    // Initial loading — no cached data yet
    if (_members == null && _loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    return Column(
      children: [
        // ── Offline banner ────────────────────────────────────────────────
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
                // Header
                _BQ17Header(
                  isDark: isDark,
                  lastUpdated: _fmtTimestamp(_lastUpdated),
                  loading: _loading,
                  ctx: context,
                ),

                // Empty state
                if (_members == null || _members!.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        context.t('no_staff_activity_data'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkGreyText
                              : AppColors.greyText,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ..._members!.asMap().entries.map(
                    (entry) => _StaffActivityCard(
                      rank: entry.key + 1,
                      member: entry.value,
                      isDark: isDark,
                      windowLabel: context.t('staff_activity_offers_window'),
                      totalLabel: context.t('staff_activity_total'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _BQ17Header extends StatelessWidget {
  final bool isDark;
  final String lastUpdated;
  final bool loading;
  final BuildContext ctx;

  const _BQ17Header({
    required this.isDark,
    required this.lastUpdated,
    required this.loading,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final mutedText = isDark ? AppColors.darkGreyText : AppColors.greyText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BQ label chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'BQ17',
              style: TextStyle(
                color: Color(0xFF9A5B00),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ctx.t('staff_activity_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            ctx.t('staff_activity_subtitle'),
            style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
          ),
          if (lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update_rounded,
                    size: 13, color: AppColors.greyText),
                const SizedBox(width: 5),
                Text(
                  '${ctx.t('last_updated')}: $lastUpdated',
                  style: const TextStyle(
                      color: AppColors.greyText, fontSize: 12),
                ),
                if (loading) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primaryYellow),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Staff rank card ───────────────────────────────────────────────────────────

class _StaffActivityCard extends StatelessWidget {
  final int rank;
  final _StaffMember member;
  final bool isDark;
  final String windowLabel;
  final String totalLabel;

  const _StaffActivityCard({
    required this.rank,
    required this.member,
    required this.isDark,
    required this.windowLabel,
    required this.totalLabel,
  });

  Color get _medalColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return AppColors.greyText;
    }
  }

  IconData get _rankIcon {
    return rank <= 3
        ? Icons.emoji_events_rounded
        : Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final accentColor = rank <= 3 ? _medalColor : AppColors.primaryYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3
              ? _medalColor.withValues(alpha: 0.45)
              : borderColor,
          width: rank <= 3 ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // ── Rank badge ──────────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_rankIcon, color: _medalColor, size: 22),
                const SizedBox(height: 2),
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _medalColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Staff info ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.staffName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                ),
                if (member.department != null &&
                    member.department!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.department!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkGreyText
                          : AppColors.greyText,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${member.totalOffers} $totalLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkGreyText
                        : AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),

          // ── Offers-in-window counter ────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                member.offersInWindow.toString(),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                windowLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.greyText,
                    height: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
