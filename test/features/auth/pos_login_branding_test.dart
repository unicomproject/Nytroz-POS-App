import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/pos_login_branding_cache_datasource.dart';
import 'package:nytroz_pos/features/auth/data/models/pos_login_branding_dto.dart';
import 'package:nytroz_pos/features/auth/domain/entities/pos_login_branding.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/pos_login_branding_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/widgets/pos_login_branding_panel.dart';
import 'package:nytroz_pos/features/auth/presentation/widgets/pos_login_form.dart';
import 'package:nytroz_pos/shared/widgets/app_cached_network_image.dart';

void main() {
  test('DTO maps IMAGE and normalizes malformed optional values safely', () {
    final branding = PosLoginBrandingDto({
      'tenantSlug': 'tenant-a',
      'brandDisplayName': 'Tenant A',
      'systemName': 'Cashier',
      'description': 'Fast checkout',
      'loginSubtitle': 'Sign in to Tenant A',
      'backgroundMode': 'IMAGE',
      'backgroundColor': 'invalid',
      'updatedAt': 'invalid',
    }).toDomain();

    expect(branding.backgroundMode, PosLoginBackgroundMode.image);
    expect(branding.backgroundColor, '#000E2B');
    expect(branding.logoUrl, isNull);
    expect(branding.updatedAt, PosLoginBranding.packagedDefault.updatedAt);
  });

  test('DTO resolves API-relative branding media URLs', () {
    final branding = PosLoginBrandingDto(
      {
        'tenantSlug': 'tenant-a',
        'logoUrl': '/development-fixtures/pos-login/logo.png',
        'backgroundImageUrl': '/development-fixtures/pos-login/background.png',
        'heroImageUrl': '/development-fixtures/pos-login/hero.png',
      },
      apiBaseUrl: 'http://10.0.2.2:5150/api/v1/',
    ).toDomain();

    expect(
      branding.logoUrl,
      'http://10.0.2.2:5150/development-fixtures/pos-login/logo.png',
    );
    expect(
      branding.backgroundImageUrl,
      'http://10.0.2.2:5150/development-fixtures/pos-login/background.png',
    );
    expect(
      branding.heroImageUrl,
      'http://10.0.2.2:5150/development-fixtures/pos-login/hero.png',
    );
  });

  test('tenant-scoped cache never returns another tenant branding', () async {
    final storage = _MemoryStorage();
    final cache = PosLoginBrandingCacheDatasource(storage);
    final tenantA = PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      brandDisplayName: 'Tenant A',
    );

    await cache.write(tenantA, 'etag-a');

    expect(
        (await cache.read('tenant-a'))?.branding.brandDisplayName, 'Tenant A');
    expect(await cache.read('tenant-b'), isNull);
    expect(storage.values.keys, contains('pos.login.branding.tenant-a'));
    expect(storage.values.keys, isNot(contains('pos.login.branding.tenant-b')));
  });

  testWidgets('branding panel renders dynamic COLOR content without overflow',
      (tester) async {
    final branding = PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      brandDisplayName: 'A very long tenant trading name for tablet checkout',
      systemName: 'Tenant Cashier System',
      description: 'Line one\nLine two with a longer tenant message.',
      backgroundColor: '#FF6A00',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PosLoginBrandingPanel(branding: branding, compact: false),
          ),
        ),
      ),
    );

    expect(find.text('Tenant Cashier System'), findsOneWidget);
    expect(find.textContaining('Line one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unprovisioned branding composes packaged logo and hero fallbacks',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PosLoginBrandingPanel(
              branding: PosLoginBranding.packagedDefault,
              compact: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppCachedNetworkImage), findsNothing);
    expect(find.text('Smart Cashier System'), findsOneWidget);
    expect(find.textContaining('Powering every sale.'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/logo.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/images/log-screen-terminal.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('IMAGE mode without URLs retains packaged content fallbacks',
      (tester) async {
    final branding = PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      backgroundMode: PosLoginBackgroundMode.image,
      backgroundColor: '#123456',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PosLoginBrandingPanel(branding: branding, compact: false),
          ),
        ),
      ),
    );

    expect(find.byType(AppCachedNetworkImage), findsNothing);
    expect(
      find.image(const AssetImage('assets/images/logo.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/images/log-screen-terminal.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('OneVerz brand name renders as plain backend text',
      (tester) async {
    final branding = PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      brandDisplayName: 'OneVerz',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PosLoginBrandingPanel(branding: branding, compact: false),
          ),
        ),
      ),
    );

    expect(find.text('OneVerz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backend media URLs render through network image widgets',
      (tester) async {
    final branding = PosLoginBranding.packagedDefault.copyWith(
      tenantSlug: 'tenant-a',
      brandDisplayName: 'OneVerz',
      backgroundMode: PosLoginBackgroundMode.image,
      logoUrl: 'https://cdn.example.test/logo.png',
      backgroundImageUrl: 'https://cdn.example.test/background.png',
      heroImageUrl: 'https://cdn.example.test/hero.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 800,
            child: PosLoginBrandingPanel(branding: branding, compact: false),
          ),
        ),
      ),
    );

    expect(find.byType(AppCachedNetworkImage), findsNWidgets(3));
    expect(find.text('OneVerz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('device tenant slug wins over empty stored/web defaults', () async {
    final slug = await resolvePosLoginBrandingTenantSlug(
      deviceTenantSlug: 'oneverce',
      readStoredTenantSlug: () async => 'arenasports',
    );
    expect(slug, 'oneverce');
  });

  test('debug web falls back to seeded development branding tenant', () async {
    final slug = await resolvePosLoginBrandingTenantSlug(
      deviceTenantSlug: null,
      readStoredTenantSlug: () async => null,
    );
    if (kIsWeb && kDebugMode) {
      expect(slug, 'arenasports');
    } else if (!kIsWeb) {
      expect(slug, isEmpty);
    }
  });

  testWidgets('login form safely wraps a long dynamic subtitle',
      (tester) async {
    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: PosLoginForm(
                formKey: GlobalKey<FormState>(),
                emailController: email,
                passwordController: password,
                subtitle:
                    'Sign in to continue to a tenant point of sale with a deliberately long display name',
                isWide: true,
                obscurePassword: true,
                submitting: false,
                onTogglePassword: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
        find.textContaining('deliberately long display name'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryStorage extends AppSecureStorage {
  _MemoryStorage() : super(const FlutterSecureStorage());

  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
