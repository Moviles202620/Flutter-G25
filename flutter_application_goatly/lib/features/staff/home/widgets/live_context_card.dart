import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization.dart';
import '../../../../app/theme.dart';
import '../../../../data/settings_state.dart';
import '../../../../models/offer_model.dart';
import '../../../../services/live_context_service.dart';

class LiveContextCard extends StatefulWidget {
  final bool isDark;
  final OfferState offerState;

  const LiveContextCard({super.key, required this.isDark, required this.offerState});

  @override
  State<LiveContextCard> createState() => _LiveContextCardState();
}

class _LiveContextCardState extends State<LiveContextCard> {
  StreamSubscription<StabilityStatus>? _stabilitySubscription;
  StreamSubscription<Object?>? _proximitySubscription;
  Timer? _presenceTimer;
  Timer? _hysteresisTimer;

  StabilityStatus _stabilityStatus = StabilityStatus.unavailable;
  int _stableReadings = 0;

  bool _isAwaitingPresenceGesture = false;
  bool _presenceConfirmed = false;
  bool _proximityAvailable = true;
  Object? _proximityBaseline;

  static const int _stableReadingsRequired = 3;
  static const Duration _presenceTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _subscribeToStability();
  }

  @override
  void dispose() {
    _stabilitySubscription?.cancel();
    _proximitySubscription?.cancel();
    _presenceTimer?.cancel();
    _hysteresisTimer?.cancel();
    super.dispose();
  }

  void _subscribeToStability() {
    if (!LiveContextService.isSupportedMobilePlatform) return;

    _stabilitySubscription = LiveContextService.watchStability().listen(
      (status) {
        if (!mounted) return;

        // Hysteresis: require 3 consecutive stable readings before
        // switching from moving → stable, to avoid rapid toggling.
        if (status == StabilityStatus.stable) {
          _stableReadings++;
          if (_stableReadings >= _stableReadingsRequired &&
              _stabilityStatus != StabilityStatus.stable) {
            setState(() => _stabilityStatus = StabilityStatus.stable);
          }
        } else {
          _stableReadings = 0;
          if (_stabilityStatus != status) {
            setState(() => _stabilityStatus = status);
          }
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _stabilityStatus = StabilityStatus.unavailable);
      },
    );
  }

  Future<void> _startPresenceConfirmation() async {
    if (_isAwaitingPresenceGesture || _presenceConfirmed) return;

    setState(() {
      _isAwaitingPresenceGesture = true;
      _proximityAvailable = true;
      _proximityBaseline = null;
    });

    await _proximitySubscription?.cancel();
    _presenceTimer?.cancel();

    _proximitySubscription = LiveContextService.watchProximityEvents().listen(
      (event) {
        if (!mounted || !_isAwaitingPresenceGesture) return;
        if (_proximityBaseline == null) {
          setState(() => _proximityBaseline = event);
          return;
        }
        // Any change from baseline = gesture detected
        if (event != _proximityBaseline) {
          _finishPresenceConfirmation(confirmed: true);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _proximityAvailable = false;
          _isAwaitingPresenceGesture = false;
        });
      },
    );

    // Auto-cancel after timeout
    _presenceTimer = Timer(_presenceTimeout, () {
      if (!mounted || !_isAwaitingPresenceGesture) return;
      setState(() => _isAwaitingPresenceGesture = false);
      _proximitySubscription?.cancel();
    });
  }

  void _finishPresenceConfirmation({required bool confirmed}) {
    _presenceTimer?.cancel();
    _proximitySubscription?.cancel();
    if (!mounted) return;

    setState(() {
      _isAwaitingPresenceGesture = false;
      _presenceConfirmed = confirmed;
    });

    if (confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('presence_confirmed_snack')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData get _stabilityIcon => switch (_stabilityStatus) {
        StabilityStatus.stable => Icons.check_circle_outline_rounded,
        StabilityStatus.moving => Icons.screen_rotation_alt_outlined,
        StabilityStatus.unavailable => Icons.sensors_off_outlined,
      };

  String _stabilityLabel(BuildContext context) => switch (_stabilityStatus) {
        StabilityStatus.stable => context.t('device_stable_label'),
        StabilityStatus.moving => context.t('high_movement_label'),
        StabilityStatus.unavailable => context.t('stability_unavailable_label'),
      };

  Color get _stabilityColor => switch (_stabilityStatus) {
        StabilityStatus.stable => AppColors.success,
        StabilityStatus.moving => AppColors.primaryYellow,
        StabilityStatus.unavailable => AppColors.greyText,
      };

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final surface = widget.isDark ? AppColors.darkSurface : AppColors.surface;
    final border = widget.isDark ? AppColors.darkBorder : AppColors.border;
    final mutedText = widget.isDark ? AppColors.darkGreyText : AppColors.greyText;

    if (!LiveContextService.isSupportedMobilePlatform ||
        widget.offerState != OfferState.active) {
      return const SizedBox.shrink();
    }

    final presenceBtnLabel = _isAwaitingPresenceGesture
        ? context.t('move_hand_sensor')
        : _presenceConfirmed
            ? context.t('already_confirmed_label')
            : context.t('confirm_presence_btn');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_outlined, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              Text(
                context.t('live_context_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t('live_context_desc'),
            style: TextStyle(color: mutedText, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ContextChip(
                icon: _stabilityIcon,
                label: _stabilityLabel(context),
                color: _stabilityColor,
              ),
              if (_presenceConfirmed)
                _ContextChip(
                  icon: Icons.verified_rounded,
                  label: context.t('presence_confirmed_label'),
                  color: AppColors.success,
                ),
            ],
          ),
          if (_proximityAvailable) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      widget.isDark ? AppColors.darkModeText : AppColors.darkText,
                  side: BorderSide(color: border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_isAwaitingPresenceGesture || _presenceConfirmed)
                    ? null
                    : _startPresenceConfirmation,
                icon: const Icon(Icons.waving_hand_outlined),
                label: Text(
                  presenceBtnLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
