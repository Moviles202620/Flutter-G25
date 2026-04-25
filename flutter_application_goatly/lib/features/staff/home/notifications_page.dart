import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../data/settings_state.dart';
import '../../../models/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    context.watch<SettingsState>();
    final notifications = appState.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.t('notifications_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () =>
                  context.read<AppState>().markAllNotificationsRead(),
              child: Text(
                context.t('mark_all_read'),
                style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = notifications[i];
                return _NotificationCard(
                  notification: n,
                  surface: surface,
                  border: border,
                  isDark: isDark,
                  onTap: () =>
                      context.read<AppState>().markNotificationRead(n.id),
                );
              },
            ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final Color surface;
  final Color border;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.surface,
    required this.border,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon => switch (notification.type) {
        NotificationType.newApplication => Icons.person_add_outlined,
        NotificationType.appAccepted => Icons.check_circle_outline,
        NotificationType.appRejected => Icons.cancel_outlined,
        NotificationType.jobMatch => Icons.notifications_active_outlined,
        NotificationType.offerPublished => Icons.work_outline,
        NotificationType.ratingSubmitted => Icons.star_outline_rounded,
      };

  Color get _iconColor => switch (notification.type) {
        NotificationType.newApplication => const Color(0xFF3B82F6),
        NotificationType.appAccepted => AppColors.success,
        NotificationType.appRejected => AppColors.danger,
        NotificationType.jobMatch => AppColors.primaryYellow,
        NotificationType.offerPublished => const Color(0xFF8B5CF6),
        NotificationType.ratingSubmitted => const Color(0xFFF59E0B),
      };

  String _timeAgo(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.t('time_just_now');
    final prefix = context.t('time_ago_prefix');
    final prefixPart = prefix.isEmpty ? '' : '$prefix ';
    if (diff.inMinutes < 60) {
      return '$prefixPart${diff.inMinutes} ${context.t('time_min_unit')}';
    }
    if (diff.inHours < 24) {
      return '$prefixPart${diff.inHours} ${context.t('time_hour_unit')}';
    }
    return '$prefixPart${diff.inDays} ${context.t('time_day_unit')}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final unread = !notification.isRead;
    final secondaryColor =
        isDark ? AppColors.darkGreyText : AppColors.greyText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: unread ? _iconColor.withValues(alpha: 0.06) : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread ? _iconColor.withValues(alpha: 0.3) : border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                unread ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                        color: secondaryColor, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt, context),
                    style: TextStyle(color: secondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: AppColors.greyText.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('no_notifications'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('no_notifications_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.greyText, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
