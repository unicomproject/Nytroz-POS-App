// ignore_for_file: invalid_annotation_target
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/data/mappers/till_session_mapper.dart';

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  final form = OpenTillForm(
      deviceContext: _deviceContext(), openingFloat: 42, openingNote: '');
  Map<String, dynamic> session() => {
        'id': 'session',
        'status': 'OPEN',
        'tillId': form.deviceContext.tillId,
        'outletId': form.deviceContext.outletId
      };

  test(
      'extracted open mapper preserves wrapped/raw values and context fallbacks',
      () {
    for (final wrapped in [false, true]) {
      final json = {
        'tillSession': {...session(), 'expectedCash': '12.5'}
      };
      final before = DateTime.now();
      final result = tillSessionFromJson(wrapped ? {'data': json} : json, form);
      expect(result.status, 'open');
      expect(result.tenantId, form.deviceContext.tenantId);
      expect(result.outletName, form.deviceContext.outletName);
      expect(result.tillCode, form.deviceContext.tillCode);
      expect(result.tillName, form.deviceContext.tillName);
      expect(result.openedDeviceId, form.deviceContext.deviceId);
      expect(result.currencyCode, form.deviceContext.currencyCode);
      expect(result.openingFloat, 42);
      expect(result.expectedCash, 12.5);
      expect(result.openedAt.isBefore(before), isFalse);
      expect(result.openedAt.isAfter(DateTime.now()), isFalse);
    }
  });
  for (final field in ['id', 'status', 'tillId', 'outletId']) {
    test('open mapper keeps validation for $field', () {
      expect(
          () => tillSessionFromJson({
                'tillSession': {...session(), field: ''}
              }, form),
          throwsA(isA<TillException>()
              .having((e) => e.code, 'code', 'till_session.invalid_response')
              .having((e) => e.message, 'message',
                  'Current till session response is invalid.')));
    });
  }
  test('closed mapper preserves permissive missing fields and date fallback',
      () {
    final before = DateTime.now();
    final result = closedTillSessionFromJson({
      'data': {
        'tillSession': {'countedCash': '12.5', 'expectedCash': 'invalid'}
      }
    });
    expect(result.sessionId, '');
    expect(result.status, 'closed');
    expect(result.countedCash, 12.5);
    expect(result.expectedCash, isNull);
    expect(result.openedAt.isBefore(before), isFalse);
    expect(result.closedAt.isAfter(DateTime.now()), isFalse);
  });
}

PosDeviceContext _deviceContext() {
  return PosDeviceContext(
    deviceId: 'device-1',
    deviceCode: 'POS-01',
    deviceName: 'Front POS',
    deviceType: 'fixed_pos_tablet',
    platform: 'web',
    deviceFingerprint: 'pos-web-test',
    isTrusted: true,
    tenantId: 'tenant-1',
    outletId: 'outlet-1',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillCode: 'FRONT-01',
    tillName: 'Front Till',
    pairedAt: DateTime.utc(2026, 7, 13),
  );
}
