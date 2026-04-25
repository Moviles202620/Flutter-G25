import 'package:flutter/material.dart';

final RegExp _emojiRegex = RegExp(
  r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
  unicode: true,
);

String normalizeOfferTitle(String rawTitle) {
  return rawTitle.trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool containsEmoji(String value) => _emojiRegex.hasMatch(value);

// Legacy alias kept for backward compatibility
bool titleContainsEmoji(String value) => containsEmoji(value);

/// Validates title using translated error messages.
/// Pass [context.t] as [t].
String? validateOfferTitleLocalized(
  String? rawTitle,
  String Function(String) t,
) {
  final normalized = normalizeOfferTitle(rawTitle ?? '');
  if (normalized.isEmpty) return t('err_title_required');
  if (containsEmoji(normalized)) return t('err_title_emoji');
  if (normalized.length < 3) return t('err_title_min');
  return null;
}

/// Validates description using translated error messages.
String? validateDescriptionLocalized(
  String? value,
  String Function(String) t,
) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return t('err_description_required');
  if (containsEmoji(text)) return t('err_description_emoji');
  if (text.length < 10) return t('err_description_min');
  return null;
}

/// Validates requirements using translated error messages.
String? validateRequirementsLocalized(
  String? value,
  String Function(String) t,
) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return t('err_requirements_required');
  if (containsEmoji(text)) return t('err_requirements_emoji');
  return null;
}

// Legacy (Spanish-only) — kept so existing callers don't break
String? validateOfferTitle(String? rawTitle) {
  final normalized = normalizeOfferTitle(rawTitle ?? '');
  if (normalized.isEmpty) return 'El título es obligatorio';
  if (containsEmoji(normalized)) return 'El título no puede contener emojis';
  if (normalized.length < 3) return 'Mínimo 3 caracteres';
  return null;
}

DateTime? buildScheduledDateTime({
  required DateTime? date,
  required TimeOfDay? time,
}) {
  if (date == null || time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Returns a translated error string or null if valid.
/// Pass [context.t] as [t].
String? validateScheduledDateTimeLocalized({
  required DateTime? date,
  required TimeOfDay? time,
  required String Function(String) t,
  DateTime? now,
}) {
  if (date == null) return t('err_select_date');
  if (time == null) return t('err_select_time');
  final scheduledDateTime = buildScheduledDateTime(date: date, time: time);
  final currentTime = now ?? DateTime.now();
  if (scheduledDateTime == null || scheduledDateTime.isBefore(currentTime)) {
    return t('err_past_datetime');
  }
  return null;
}

// Legacy Spanish-only
String? validateScheduledDateTime({
  required DateTime? date,
  required TimeOfDay? time,
  DateTime? now,
}) {
  if (date == null) return 'Selecciona la fecha del trabajo';
  if (time == null) return 'Selecciona la hora del trabajo';
  final scheduledDateTime = buildScheduledDateTime(date: date, time: time);
  final currentTime = now ?? DateTime.now();
  if (scheduledDateTime == null || scheduledDateTime.isBefore(currentTime)) {
    return 'La fecha y hora del trabajo no pueden ser anteriores al momento actual';
  }
  return null;
}
