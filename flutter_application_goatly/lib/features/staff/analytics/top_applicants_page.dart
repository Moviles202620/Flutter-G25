import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/settings_state.dart';
import '../../../models/top_applicant_model.dart';
import '../../../services/api_service.dart';

class TopApplicantsPage extends StatefulWidget {
  const TopApplicantsPage({super.key});

  @override
  State<TopApplicantsPage> createState() => _TopApplicantsPageState();
}

class _TopApplicantsPageState extends State<TopApplicantsPage> {
  late Future<List<TopApplicantModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getTopApplicants();
  }

  void _reload() {
    setState(() {
      _future = ApiService.getTopApplicants();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<TopApplicantModel>>(
      future: _future,
      builder: (context, snapshot) {
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: isDark ? AppColors.darkGreyText : AppColors.greyText),
                const SizedBox(height: 12),
                Text(context.t('error_loading')),
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
        if (data.isEmpty) {
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
          onRefresh: () async => _reload(),
          color: AppColors.primaryYellow,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: data.length,
            itemBuilder: (context, index) =>
                _LeaderboardCard(rank: index + 1, applicant: data[index], isDark: isDark),
          ),
        );
      },
    );
  }
}

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
    if (rank == 1) return const Color(0xFFFFD700); // gold
    if (rank == 2) return const Color(0xFFC0C0C0); // silver
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
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
              border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.35)),
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${applicant.career} • Sem. ${applicant.semester}',
                  style: TextStyle(
                      color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                      fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (accepted > 0)
                      _MiniChip(label: '$accepted ✓', color: AppColors.success),
                    if (accepted > 0) const SizedBox(width: 6),
                    if (rejected > 0)
                      _MiniChip(label: '$rejected ✗', color: AppColors.danger),
                    if (rejected > 0) const SizedBox(width: 6),
                    if (pending > 0)
                      _MiniChip(label: '$pending ⏳', color: AppColors.greyText),
                  ],
                ),
              ],
            ),
          ),

          // GPA badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    color: isDark ? AppColors.darkGreyText : AppColors.greyText,
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
