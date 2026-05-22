import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../data/app_state.dart';
import '../../../models/offer_model.dart';
import '../../../services/api_service.dart';
import 'edit_offer_page.dart';

/// Public offer card widget for the staff offers list.
///
/// Memory optimisations applied:
///   • Wrapped in RepaintBoundary — Flutter skips repainting this subtree
///     when neighbouring list items scroll into/out of view.
///   • CachedNetworkImage uses memCacheWidth/Height: 160 px, so only a
///     downscaled bitmap is kept in the image cache (not the full resolution).
///   • maxWidthDiskCache / maxHeightDiskCache: 160 px caps what is written
///     to the on-disk LRU managed by cached_network_image.
class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isDark;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isDark,
  });

  String _fmtDateTime(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = (d.hour % 12 == 0 ? 12 : d.hour % 12).toString();
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$mm/$dd ${hh.padLeft(2, '0')}:$min $ampm';
  }

  Future<void> _deleteOffer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.t('delete_offer_confirm'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(context.t('delete_offer_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('cancel'),
                style: const TextStyle(color: AppColors.greyText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('delete'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ApiService.deleteOffer(offer.id);
      if (context.mounted) {
        context.read<AppState>().removeOffer(offer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('offer_deleted')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Sin conexión — no se pudo eliminar la oferta';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final location = offer.isOnSite
        ? context.t('on_site')
        : context.t('remote');
    final when = _fmtDateTime(offer.dateTime);

    // RepaintBoundary prevents this card from being repainted when the
    // surrounding list scrolls or a neighbouring card changes state.
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Image thumbnail — wrapped in its own RepaintBoundary so the
                // image load/fade-in does not trigger a repaint of the text area.
                if (offer.imageUrl != null)
                  RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: offer.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          // Keeps a 160×160 px bitmap in RAM — not the
                          // full-resolution image decoded from the network.
                          memCacheWidth: 160,
                          memCacheHeight: 160,
                          // Limits what is persisted to the disk LRU cache.
                          maxWidthDiskCache: 160,
                          maxHeightDiskCache: 160,
                          placeholder: (_, _) => Container(
                            width: 48,
                            height: 48,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                            child: const Icon(Icons.image_not_supported,
                                size: 20, color: AppColors.greyText),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(offer.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                OfferLifecycleBadge(offer: offer),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primaryYellow,
                  tooltip: context.t('edit_offer'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditOfferPage(offer: offer),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  tooltip: context.t('delete_offer'),
                  onPressed: () => _deleteOffer(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${offer.category} • \$${offer.valueCop} COP',
              style: const TextStyle(color: AppColors.greyText, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              '$when • ${offer.durationHours}h • $location',
              style: const TextStyle(color: AppColors.greyText, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lifecycle badge ───────────────────────────────────────────────────────────

class OfferLifecycleBadge extends StatelessWidget {
  final OfferModel offer;
  const OfferLifecycleBadge({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (label, color, icon) = switch (offer.offerState) {
      OfferState.upcoming => (
          context.t('state_badge_upcoming'),
          const Color(0xFF3B82F6),
          Icons.schedule_outlined,
        ),
      OfferState.active when offer.endTime.difference(now).inHours < 24 => (
          context.t('state_badge_closing_soon'),
          const Color(0xFFF5A623),
          Icons.warning_amber_rounded,
        ),
      OfferState.active => (
          context.t('state_badge_active'),
          AppColors.success,
          Icons.circle,
        ),
      OfferState.closed => (
          context.t('state_badge_closed'),
          AppColors.greyText,
          Icons.lock_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
