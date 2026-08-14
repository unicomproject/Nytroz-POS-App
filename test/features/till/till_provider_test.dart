import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

void main() {
  test('backend refresh cannot be overwritten by stale persisted session',
      () async {
    final storage = _DelayedTillSessionStorage();
    final controller = TillController(
      OpenTill(_NoCurrentTillRepository()),
      storage,
    );

    final refresh = controller.refreshCurrentSession(
      deviceContext: _device,
      force: true,
    );

    storage.completeRead(_staleSession);

    expect(await refresh, isFalse);
    expect(controller.state.session, isNull);
    expect(controller.state.hasOpenSession, isFalse);
    expect(storage.clearCount, 1);
  });
}

class _NoCurrentTillRepository implements TillRepository {
  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async => null;

  @override
  Future<TillSession> openTill(OpenTillForm form) => throw UnimplementedError();

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) =>
      throw UnimplementedError();
}

class _DelayedTillSessionStorage extends TillSessionStorage {
  _DelayedTillSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final _readCompleter = Completer<TillSession?>();
  int clearCount = 0;

  void completeRead(TillSession? session) => _readCompleter.complete(session);

  @override
  Future<TillSession?> read() => _readCompleter.future;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {
    clearCount++;
  }
}

final _device = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'POS-01',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'test',
  deviceFingerprint: 'fingerprint-1',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till 01',
  pairedAt: DateTime.utc(2026, 8, 14),
  currencyCode: 'LKR',
);

final _staleSession = TillSession(
  sessionId: 'stale-session',
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till 01',
  openedDeviceId: 'device-1',
  openingFloat: 1000,
  status: 'open',
  openedAt: DateTime.utc(2026, 8, 13),
);
