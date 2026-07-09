import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';

void main() {
  group('OpenTill use case', () {
    test('opens till through repository', () async {
      final expectedSession = TillSession(
        sessionId: 'session-1',
        tenantId: 'tenant-1',
        outletId: 'outlet-1',
        outletName: 'Main Outlet',
        tillId: 'till-1',
        tillCode: 'TILL-001',
        tillName: 'Front Till',
        openedDeviceId: 'device-1',
        openingFloat: 150,
        status: 'open',
        openedAt: _openedAt,
        openingNote: 'Morning shift',
      );
      final repository = _FakeTillRepository(openSession: expectedSession);
      final openTill = OpenTill(repository);
      final form = OpenTillForm(
        deviceContext: _deviceContext,
        openingFloat: 150,
        openingNote: 'Morning shift',
      );

      final result = await openTill(form);

      expect(result, expectedSession);
      expect(repository.lastOpeningFloat, 150);
    });

    test('returns current open session when one exists', () async {
      final currentSession = TillSession(
        sessionId: 'session-1',
        tenantId: 'tenant-1',
        outletId: 'outlet-1',
        outletName: 'Main Outlet',
        tillId: 'till-1',
        tillCode: 'TILL-001',
        tillName: 'Front Till',
        openedDeviceId: 'device-1',
        openingFloat: 150,
        status: 'open',
        openedAt: _openedAt,
      );
      final repository = _FakeTillRepository(currentSession: currentSession);
      final openTill = OpenTill(repository);
      final form = OpenTillForm(
        deviceContext: _deviceContext,
        openingFloat: 0,
        openingNote: '',
      );

      final result = await openTill.currentSession(form);

      expect(result, currentSession);
    });
  });
}

class _FakeTillRepository implements TillRepository {
  _FakeTillRepository({
    this.openSession,
    this.currentSession,
  });

  final TillSession? openSession;
  final TillSession? currentSession;
  double? lastOpeningFloat;

  @override
  Future<TillSession> openTill(OpenTillForm form) async {
    lastOpeningFloat = form.openingFloat;
    return openSession!;
  }

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async {
    return currentSession;
  }

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) async {
    throw UnimplementedError();
  }
}

final _openedAt = DateTime.utc(2026, 6, 16, 9);

final _deviceContext = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'DEV-001',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'web',
  deviceFingerprint: 'test-device-fingerprint',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  pairedAt: _openedAt,
);
