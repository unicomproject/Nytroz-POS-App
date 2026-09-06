import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';

void main() {
  group('TillSession.fromJson expectedCash compatibility', () {
    test('leaves expectedCash null when expectedCash is missing', () {
      final session = TillSession.fromJson(_sessionJson());

      expect(session.expectedCash, isNull);
    });

    test('leaves expectedCash null when expectedCash is null', () {
      final session = TillSession.fromJson(
        _sessionJson(expectedCash: null, includeExpectedCash: true),
      );

      expect(session.expectedCash, isNull);
    });

    test('parses numeric expectedCash', () {
      final session = TillSession.fromJson(
        _sessionJson(expectedCash: 1250.75, includeExpectedCash: true),
      );

      expect(session.expectedCash, 1250.75);
    });

    test('parses numeric-string expectedCash', () {
      final session = TillSession.fromJson(
        _sessionJson(expectedCash: '1250.75', includeExpectedCash: true),
      );

      expect(session.expectedCash, 1250.75);
    });
  });
}

Map<String, dynamic> _sessionJson({
  Object? expectedCash,
  bool includeExpectedCash = false,
}) {
  return <String, dynamic>{
    'sessionId': 'session-1',
    'tenantId': 'tenant-1',
    'outletId': 'outlet-1',
    'outletName': 'Development Main Store',
    'tillId': 'till-1',
    'tillCode': 'TILL-01',
    'tillName': 'Front Till 01',
    'openedDeviceId': 'device-1',
    'openingFloat': 1000,
    'status': 'open',
    'openedAt': '2026-08-15T08:00:00Z',
    if (includeExpectedCash) 'expectedCash': expectedCash,
  };
}
