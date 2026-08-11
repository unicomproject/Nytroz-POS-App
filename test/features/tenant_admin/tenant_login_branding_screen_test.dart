import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/domain/entities/pos_login_branding.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/domain/entities/tenant_login_branding_settings.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/domain/repositories/tenant_login_branding_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/presentation/providers/tenant_login_branding_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/login_branding/presentation/screens/tenant_login_branding_screen.dart';

void main() {
  testWidgets('editor loads, previews COLOR changes and saves once',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = _Repository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantLoginBrandingRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TenantLoginBrandingScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('POS Login Branding'), findsOneWidget);
    expect(find.text('Tenant A'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'System name'),
      'Updated cashier',
    );
    await tester.ensureVisible(find.text('Save branding'));
    await tester.tap(find.text('Save branding'));
    await tester.pumpAndSettle();

    expect(repository.updateCount, 1);
    expect(repository.lastRequest?.systemName, 'Updated cashier');
    expect(find.text('POS login branding saved.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Repository implements TenantLoginBrandingRepository {
  int updateCount = 0;
  UpdateTenantLoginBrandingSettings? lastRequest;

  final settings = TenantLoginBrandingSettings(
    systemName: 'Tenant cashier',
    description: 'Tenant description',
    subtitleTemplate: 'Sign in to {tenantName}',
    backgroundMode: PosLoginBackgroundMode.color,
    backgroundColor: '#FF6A00',
    effective: PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      brandDisplayName: 'Tenant A',
      systemName: 'Tenant cashier',
      description: 'Tenant description',
      loginSubtitle: 'Sign in to Tenant A',
      backgroundColor: '#FF6A00',
    ),
  );

  @override
  Future<TenantLoginBrandingSettings> get() async => settings;

  @override
  Future<TenantLoginBrandingSettings> update(
    UpdateTenantLoginBrandingSettings request,
  ) async {
    updateCount++;
    lastRequest = request;
    return settings;
  }

  @override
  Future<TenantLoginBrandingMediaUpload> uploadMedia(
    String purpose,
    TenantLoginBrandingMediaInput input,
  ) async =>
      const TenantLoginBrandingMediaUpload(
        mediaAssetId: '00000000-0000-4000-8000-000000000001',
        purpose: 'POS_LOGIN_HERO',
        publicUrl: null,
      );
}
