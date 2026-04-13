import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/application_model.dart';
import '../home/application_detail_page.dart';
import 'edit_profile_page.dart';

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

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

    final accepted = state.acceptedApplications;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final statValueColor = isDark ? AppColors.darkModeText : AppColors.darkText;

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
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'FU',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
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
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: context.t('stat_accepted'),
                      value: state.acceptedApplications.length.toString(),
                      valueColor: AppColors.primaryYellow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: context.t('stat_pending'),
                      value: state.pendingApplications.length.toString(),
                      valueColor: statValueColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: context.t('stat_posts'),
                      value: state.offers.length.toString(),
                      valueColor: statValueColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Accepted applications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.t('accepted_applications'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.t('today'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF9A5B00)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: borderColor),

                    if (accepted.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.t('no_accepted'),
                            style: const TextStyle(
                                color: AppColors.greyText, height: 1.3),
                          ),
                        ),
                      )
                    else
                      ..._buildAcceptedList(context, accepted),
                  ],
                ),
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

  List<Widget> _buildAcceptedList(
      BuildContext context, List<ApplicationModel> accepted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return accepted
        .map(
          (a) => Column(
            children: [
              _ProfileListTile(
                initials: a.applicantInitials,
                name: a.applicantName,
                role: a.offerTitle,
                isCompleted: a.isCompleted,
                rating: a.rating,
                completedLabel: context.t('completed_label'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ApplicationDetailPage(app: a)),
                  );
                },
              ),
              Divider(height: 1, color: borderColor),
            ],
          ),
        )
        .toList();
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

class _ProfileListTile extends StatelessWidget {
  final String initials;
  final String name;
  final String role;
  final VoidCallback onTap;
  final bool isCompleted;
  final double? rating;
  final String completedLabel;

  const _ProfileListTile({
    required this.initials,
    required this.name,
    required this.role,
    required this.onTap,
    required this.completedLabel,
    this.isCompleted = false,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9A5B00)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(role,
                      style: const TextStyle(
                          color: AppColors.greyText, fontSize: 14)),
                  if (isCompleted && rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = (i + 1) <= rating!.round();
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: filled
                                ? const Color(0xFFF59E0B)
                                : AppColors.border,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            completedLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA4B2)),
          ],
        ),
      ),
    );
  }
}
