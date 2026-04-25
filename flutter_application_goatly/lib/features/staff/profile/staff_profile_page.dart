import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import 'edit_profile_page.dart';

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  String _initialsFor(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return 'FU';
    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.t('logout_confirm_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(context.t('logout_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(
              context.t('logout'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppState>().logout();
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    context.watch<SettingsState>();
    final user = state.user;
    final profileImageBytes = state.profileImageBytes;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 18),

            // Avatar
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                  image: profileImageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(profileImageBytes),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImageBytes == null
                    ? Center(
                        child: Text(
                          _initialsFor(user?.name),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: Text(
                user?.name ?? 'Funcionario Uniandes',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                user?.department ?? 'Administrativo',
                style: const TextStyle(color: AppColors.greyText, fontSize: 15),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                user?.university ?? 'Universidad de los Andes',
                style: const TextStyle(color: AppColors.greyText, fontSize: 15),
              ),
            ),
            const SizedBox(height: 14),

            // Buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _SoftButton(
                      text: context.t('edit_profile'),
                      filled: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SoftButton(
                      text: context.t('settings'),
                      filled: false,
                      onTap: () {
                        Navigator.pushNamed(context, Routes.settings);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: borderColor),

            // Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('profile_stats_title'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkGreyText : AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: context.t('stat_total_offers'),
                          value: state.offers.length.toString(),
                          valueColor: AppColors.primaryYellow,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: context.t('stat_total_rated'),
                          value: _totalRated(state).toString(),
                          valueColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          title: context.t('stat_avg_rating'),
                          value: _avgRating(state),
                          valueColor: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout button — red with confirmation dialog
            InkWell(
              onTap: () => _confirmLogout(context),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(
                      context.t('logout'),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  int _totalRated(AppState state) =>
      state.applications
          .where((a) => a.isCompleted && a.rating != null)
          .length;

  String _avgRating(AppState state) {
    final rated = state.applications
        .where((a) => a.isCompleted && a.rating != null)
        .toList();
    if (rated.isEmpty) return '—';
    final avg =
        rated.fold(0.0, (sum, a) => sum + (a.rating ?? 0)) / rated.length;
    return avg.toStringAsFixed(1);
  }
}

class _SoftButton extends StatelessWidget {
  final String text;
  final bool filled;
  final VoidCallback onTap;

  const _SoftButton({
    required this.text,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = filled
        ? AppColors.primaryYellow.withValues(alpha: 0.2)
        : (isDark ? AppColors.darkSurface : Colors.white);
    final border =
        filled ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.border);
    final color = filled ? const Color(0xFF9A5B00) : AppColors.greyText;

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: color,
          side: BorderSide(color: border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final titleColor = isDark ? AppColors.darkGreyText : AppColors.greyText;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 12, color: titleColor, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: valueColor),
          ),
        ],
      ),
    );
  }
}
