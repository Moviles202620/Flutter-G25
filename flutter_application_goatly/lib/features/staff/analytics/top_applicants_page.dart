import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/top_applicant_model.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';

class TopApplicantsPage extends StatefulWidget {
  const TopApplicantsPage({super.key});

  @override
  State<TopApplicantsPage> createState() => _TopApplicantsPageState();
}

class _TopApplicantsPageState extends State<TopApplicantsPage> {
  List<TopApplicantModel>? _items;
  String? _lastUpdated;
  bool _loading = false;
  String? _error;

  static const _endpoint = 'top_applicants';

  @override
  void initState() {
    super.initState();
    _loadWithCache();
  }

  // ── Cache-first load ───────────────────────────────────────────────────────

  Future<void> _loadWithCache() async {
    final cached = await CacheService.loadAnalytics(_endpoint);
    final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
    if (cached != null) {
      final list = (cached['data'] as List)
          .map((e) => TopApplicantModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _items = list; _lastUpdated = ts; });
    } else {
      if (mounted) setState(() => _loading = true);
    }
    await _refreshFromNetwork();
  }

  Future<void> _refreshFromNetwork() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      // Multi-threading: ApiService.getTopApplicants() corre en el
      // event loop de Dart sin bloquear el UI thread (async I/O concurrente).
      final fresh = await ApiService.getTopApplicants();
      final payload = {'data': fresh.map((e) => e.toJson()).toList()};
      await CacheService.saveAnalytics(_endpoint, payload);
      final ts = await CacheService.getAnalyticsTimestamp(_endpoint);
      if (mounted) setState(() { _items = fresh; _lastUpdated = ts; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_items == null) _error = 'Sin conexión y sin datos en caché.';
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
    context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_error != null && _items == null) {
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

    if (_items == null && _loading) {
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

    final items = _items ?? [];

    if (items.isEmpty && !_loading) {
      return Center(
        child: Text(
          context.t('no_top_data'),
          style: TextStyle(
            color: isDark ? AppColors.darkGreyText : AppColors.greyText,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFromNetwork,
      color: AppColors.primaryYellow,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length + 1, // +1 for last-updated header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LastUpdatedRow(
              lastUpdated: _fmtTimestamp(_lastUpdated),
              loading: _loading,
              context: context,
            );
          }
          return _LeaderboardCard(
              rank: index, applicant: items[index - 1], isDark: isDark);
        },
      ),
    );
  }
}

// ── Last updated row ──────────────────────────────────────────────────────────

class _LastUpdatedRow extends StatelessWidget {
  final String lastUpdated;
  final bool loading;
  final BuildContext context;

  const _LastUpdatedRow({
    required this.lastUpdated,
    required this.loading,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    if (lastUpdated.isEmpty && !loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (lastUpdated.isNotEmpty) ...[
            const Icon(Icons.update_rounded,
                size: 13, color: AppColors.greyText),
            const SizedBox(width: 5),
            Text(
              '${context.t('last_updated')}: $lastUpdated',
              style:
                  const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
          ],
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
    );
  }
}

// ── Leaderboard card ──────────────────────────────────────────────────────────

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final TopApplicantModel applicant;
  final bool isDark;

  const _LeaderboardCard({
    required this.rank,
    required this.applicant,
    required this.isDark,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.greyText;
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final accepted = applicant.statusSummary['accepted'] ?? 0;
    final rejected = applicant.statusSummary['rejected'] ?? 0;
    final pending = applicant.statusSummary['pending'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3 ? _rankColor.withValues(alpha: 0.5) : borderColor,
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: _rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar initials
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryYellow.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                applicant.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9A5B00),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.applicantName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${applicant.career} • Sem. ${applicant.semester}',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.darkGreyText
                          : AppColors.greyText,
                      fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (accepted > 0)
                      _MiniChip(
                          label: '$accepted ✓', color: AppColors.success),
                    if (accepted > 0) const SizedBox(width: 6),
                    if (rejected > 0)
                      _MiniChip(
                          label: '$rejected ✗', color: AppColors.danger),
                    if (rejected > 0) const SizedBox(width: 6),
                    if (pending > 0)
                      _MiniChip(
                          label: '$pending ⏳',
                          color: AppColors.greyText),
                  ],
                ),
              ],
            ),
          ),

          // GPA badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  applicant.gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9A5B00),
                  ),
                ),
                Text(
                  'GPA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkGreyText
                        : AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
