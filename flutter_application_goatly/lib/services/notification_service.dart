import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps [flutter_local_notifications] to show OS-level notification banners.
///
/// Triggers:
///  • Staff publishes an offer          → banner for staff + simulated student banner
///  • Staff accepts an application      → banner confirming action + student simulation
///  • Staff rejects an application      → banner confirming action
///  • Staff submits a rating            → confirmation banner
///  • New application arrives (mock)    → banner to staff
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Android notification channel
  static const _channelId = 'goatly_main';
  static const _channelName = 'Goatly';
  static const _channelDesc = 'Notificaciones de Goatly';

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Request POST_NOTIFICATIONS permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Core show ─────────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Domain helpers (call these from UI / state) ───────────────────────────

  /// Fired when staff publishes a new offer.
  /// Also fires a simulated student banner (Ana, Psicología).
  static Future<void> onOfferPublished(String offerTitle) async {
    await _show(
      id: 1,
      title: 'Oferta publicada',
      body: '"$offerTitle" ya está visible para los estudiantes.',
    );
    // Simulate student receiving a job-match push
    await _show(
      id: 2,
      title: 'Goatly para estudiantes',
      body: 'Ana (Psicología, 19) recibió una alerta sobre "$offerTitle".',
    );
  }

  /// Fired when staff accepts an application.
  static Future<void> onApplicationAccepted(
      String applicantName, String offerTitle) async {
    await _show(
      id: 3,
      title: 'Aplicación aceptada',
      body: '$applicantName fue aceptado/a para "$offerTitle".',
    );
    // Simulate student receiving their acceptance notification
    await _show(
      id: 4,
      title: 'Goatly para estudiantes',
      body:
          '$applicantName recibió su notificación de aceptación en "$offerTitle".',
    );
  }

  /// Fired when staff rejects an application.
  static Future<void> onApplicationRejected(
      String applicantName, String offerTitle) async {
    await _show(
      id: 5,
      title: 'Aplicación rechazada',
      body: '$applicantName fue rechazado/a de "$offerTitle".',
    );
  }

  /// Fired when staff submits a rating.
  static Future<void> onRatingSubmitted(
      String applicantName, double rating) async {
    final stars = rating.toStringAsFixed(1);
    await _show(
      id: 6,
      title: 'Calificación enviada',
      body: 'Calificaste a $applicantName con $stars estrellas.',
    );
  }

  /// Fired when a new application arrives (simulated from mock seed).
  static Future<void> onNewApplication(
      String applicantName, String offerTitle) async {
    await _show(
      id: 7,
      title: 'Nueva postulación',
      body: '$applicantName aplicó a "$offerTitle".',
    );
  }
}
