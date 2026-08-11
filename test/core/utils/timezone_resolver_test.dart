import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/utils/timezone_resolver.dart';

void main() {
  setUpAll(() {
    TimezoneResolver.ensureInitialized();
  });

  group('TimezoneResolver Tests', () {
    test('resolves Asia/Colombo timezone (+05:30) correctly', () {
      final serverNowUtc = DateTime.utc(2026, 8, 8, 5, 20, 0);
      final receivedAt = DateTime.utc(2026, 8, 8, 5, 20, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: 'Asia/Colombo',
        nowUtc: receivedAt,
      );

      // Colombo is UTC+5:30 -> 10:50 AM
      expect(resolved.year, 2026);
      expect(resolved.month, 8);
      expect(resolved.day, 8);
      expect(resolved.hour, 10);
      expect(resolved.minute, 50);
    });

    test(
        'resolves DST-aware America/New_York in daylight saving time (EDT, UTC-4)',
        () {
      // In August, New York is in EDT (UTC-4)
      final serverNowUtc = DateTime.utc(2026, 8, 8, 12, 0, 0);
      final receivedAt = DateTime.utc(2026, 8, 8, 12, 0, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: 'America/New_York',
        nowUtc: receivedAt,
      );

      expect(resolved.year, 2026);
      expect(resolved.month, 8);
      expect(resolved.day, 8);
      expect(resolved.hour, 8); // 12:00 UTC - 4h = 08:00 EDT
      expect(resolved.minute, 0);
    });

    test('resolves DST-aware America/New_York in standard time (EST, UTC-5)',
        () {
      // In January, New York is in EST (UTC-5)
      final serverNowUtc = DateTime.utc(2026, 1, 15, 12, 0, 0);
      final receivedAt = DateTime.utc(2026, 1, 15, 12, 0, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: 'America/New_York',
        nowUtc: receivedAt,
      );

      expect(resolved.year, 2026);
      expect(resolved.month, 1);
      expect(resolved.day, 15);
      expect(resolved.hour, 7); // 12:00 UTC - 5h = 07:00 EST
      expect(resolved.minute, 0);
    });

    test('resolves non-DST Asia/Dubai (+04:00) correctly', () {
      final serverNowUtc = DateTime.utc(2026, 8, 8, 10, 0, 0);
      final receivedAt = DateTime.utc(2026, 8, 8, 10, 0, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: 'Asia/Dubai',
        nowUtc: receivedAt,
      );

      expect(resolved.year, 2026);
      expect(resolved.month, 8);
      expect(resolved.day, 8);
      expect(resolved.hour, 14); // 10:00 UTC + 4h = 14:00
      expect(resolved.minute, 0);
    });

    test(
        'resolves DST-aware Europe/London in BST (summer, UTC+1) and GMT (winter, UTC+0)',
        () {
      // Summer (August - BST, UTC+1)
      final summerUtc = DateTime.utc(2026, 8, 8, 12, 0, 0);
      final summerResolved =
          TimezoneResolver.toTimezone(summerUtc, 'Europe/London');
      expect(summerResolved.hour, 13);

      // Winter (December - GMT, UTC+0)
      final winterUtc = DateTime.utc(2026, 12, 15, 12, 0, 0);
      final winterResolved =
          TimezoneResolver.toTimezone(winterUtc, 'Europe/London');
      expect(winterResolved.hour, 12);
    });

    test(
        'gracefully falls back to anchored UTC when timezone identifier is invalid or unknown',
        () {
      final serverNowUtc = DateTime.utc(2026, 8, 8, 5, 20, 0);
      final receivedAt = DateTime.utc(2026, 8, 8, 5, 20, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: 'Invalid/NonExistent_Zone',
        nowUtc: receivedAt,
      );

      expect(resolved.year, 2026);
      expect(resolved.month, 8);
      expect(resolved.day, 8);
      expect(resolved.hour, 5);
      expect(resolved.minute, 20);
    });

    test(
        'gracefully falls back to anchored UTC when timezone is null or whitespace',
        () {
      final serverNowUtc = DateTime.utc(2026, 8, 8, 5, 20, 0);
      final receivedAt = DateTime.utc(2026, 8, 8, 5, 20, 0);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: receivedAt,
        outletTimezone: '   ',
        nowUtc: receivedAt,
      );

      expect(resolved.year, 2026);
      expect(resolved.hour, 5);
      expect(resolved.minute, 20);
    });

    test(
        'falls back to fallbackNow when serverNowUtc or serverTimeReceivedAt is null',
        () {
      final fallback = DateTime(2026, 8, 8, 10, 43);

      final resolved = TimezoneResolver.resolveOutletNow(
        serverNowUtc: null,
        serverTimeReceivedAt: null,
        outletTimezone: 'Asia/Colombo',
        fallbackNow: fallback,
      );

      expect(resolved, fallback);
    });
  });
}
