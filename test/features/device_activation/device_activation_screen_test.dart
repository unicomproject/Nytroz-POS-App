import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/pos_login_branding.dart';
import 'package:nytroz_pos/features/auth/domain/repositories/pos_login_branding_repository.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/pos_login_branding_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/widgets/pos_login_branding_panel.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/screens/device_activation_screen.dart';

void main() {
  testWidgets('existing activation screen reuses shared Login branding panel',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceActivationRepositoryProvider.overrideWithValue(
            _DeviceRepository(),
          ),
          deviceContextStorageProvider.overrideWithValue(
            _DeviceStorage(_deviceContext),
          ),
          posLoginBrandingRepositoryProvider.overrideWithValue(
            _BrandingRepository(),
          ),
        ],
        child: const MaterialApp(home: DeviceActivationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DeviceActivationScreen), findsOneWidget);
    expect(find.byType(PosLoginBrandingPanel), findsOneWidget);
    expect(find.text('Tenant OneVerz'), findsOneWidget);
    expect(find.text('Activate Device'), findsWidgets);
    expect(
      find.text('Enter your device activation code to continue.'),
      findsOneWidget,
    );
    expect(find.text('Device Activation Code'), findsOneWidget);
    expect(find.text('Enter device activation code'), findsOneWidget);
    expect(find.byIcon(Icons.key), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Nytroz POS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _BrandingRepository implements PosLoginBrandingRepository {
  @override
  Future<PosLoginBranding?> readCached(String tenantSlug) async => null;

  @override
  Future<PosLoginBranding> refresh(String tenantSlug) async =>
      PosLoginBranding.packagedDefault.copyWith(
        tenantSlug: tenantSlug,
        brandDisplayName: 'Tenant OneVerz',
      );
}

class _DeviceRepository implements DeviceActivationRepository {
  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async =>
      _deviceContext;

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async =>
      _deviceContext;
}

class _DeviceStorage extends DeviceContextStorage {
  _DeviceStorage(this.context)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext context;

  @override
  Future<PosDeviceContext?> read() async => context;
}

final _deviceContext = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'POS-01',
  deviceName: 'Test POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'android',
  deviceFingerprint: 'fingerprint-test',
  isTrusted: true,
  tenantId: 'tenant-1',
  tenantSlug: 'arenasports',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'T01',
  tillName: 'Till 01',
  pairedAt: DateTime.utc(2026, 8, 11),
);
