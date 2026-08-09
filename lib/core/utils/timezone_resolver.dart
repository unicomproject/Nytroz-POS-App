import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Authoritative timezone resolver that converts UTC instants into target IANA timezone DateTime values.
///
/// Supports all IANA timezone identifiers (e.g. 'Asia/Colombo', 'America/New_York', 'Europe/London'),
/// dynamic Daylight Saving Time (DST) transitions, and safe fallbacks for null or unrecognized timezones.
class TimezoneResolver {
  const TimezoneResolver._();

  static bool _isInitialized = false;

  /// Ensures that IANA timezone database is initialized.
  static void ensureInitialized() {
    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }
  }

  /// Resolves the current local [DateTime] for an [outletTimezone] IANA identifier,
  /// anchored to [serverNowUtc] and the elapsed duration since [serverTimeReceivedAt].
  ///
  /// If server time is unavailable, falls back to [fallbackNow] or [DateTime.now].
  /// If [outletTimezone] is unrecognized or empty, returns the anchored UTC time.
  static DateTime resolveOutletNow({
    required DateTime? serverNowUtc,
    required DateTime? serverTimeReceivedAt,
    required String? outletTimezone,
    DateTime? fallbackNow,
    DateTime? nowUtc,
  }) {
    if (serverNowUtc == null || serverTimeReceivedAt == null) {
      return fallbackNow ?? (nowUtc?.toLocal() ?? DateTime.now());
    }

    final currentNowUtc = (nowUtc ?? DateTime.now()).toUtc();
    final elapsed =
        currentNowUtc.difference(serverTimeReceivedAt.toUtc());
    final anchoredUtc = serverNowUtc.toUtc().add(elapsed);

    final zone = outletTimezone?.trim();
    if (zone == null || zone.isEmpty) {
      return anchoredUtc;
    }

    try {
      ensureInitialized();
      final location = tz.getLocation(zone);
      return tz.TZDateTime.from(anchoredUtc, location);
    } catch (_) {
      // If the IANA timezone is invalid or unrecognized, gracefully fall back to anchored UTC.
      return anchoredUtc;
    }
  }

  /// Converts a [utcDateTime] into a timezone-aware [DateTime] in the specified [timezoneId].
  static DateTime toTimezone(DateTime utcDateTime, String? timezoneId) {
    final zone = timezoneId?.trim();
    if (zone == null || zone.isEmpty) {
      return utcDateTime.toUtc();
    }

    try {
      ensureInitialized();
      final location = tz.getLocation(zone);
      return tz.TZDateTime.from(utcDateTime.toUtc(), location);
    } catch (_) {
      return utcDateTime.toUtc();
    }
  }
}
