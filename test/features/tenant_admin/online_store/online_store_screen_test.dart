import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/domain/entities/online_store.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/domain/repositories/online_store_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/presentation/providers/online_store_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/presentation/screens/online_store_setup_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

void main() {
  testWidgets('renders all nine backend-driven Online Store screens',
      (tester) async {
    for (final entry in _expectedHeaders.entries) {
      await tester.pumpWidget(_appForStep(entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value.toUpperCase()), findsOneWidget);
      expect(
        find.byKey(ValueKey('online-store-step-${entry.key}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('online-store-progress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('online-store-bottom-actions')),
        findsOneWidget,
      );
    }
  });

  testWidgets('renders responsive Online Store layout without overflow',
      (tester) async {
    final sizes = [
      const Size(1024, 768),
      const Size(1280, 800),
      const Size(1440, 900),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_appForStep(7));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURE CLICK & COLLECT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders branding, preview and banner manager at target widths',
      (tester) async {
    for (final size in const [
      Size(1024, 768),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_appForStep(5));
      await tester.pumpAndSettle();

      expect(find.text('BRANDING & BANNERS'), findsOneWidget);
      expect(find.text('STEP 5 OF 9'), findsOneWidget);
      expect(find.text('Branding Assets'), findsOneWidget);
      expect(find.text('Brand Assets'), findsNothing);
      expect(find.text('Brand Appearance'), findsNothing);
      expect(find.text('Primary Colour'), findsOneWidget);
      expect(find.text('Secondary Colour'), findsOneWidget);
      expect(find.text('Storefront Preview'), findsOneWidget);
      expect(find.text('Banner Manager'), findsOneWidget);
      expect(find.text('Hero Banner'), findsWidgets);
      expect(find.text('Add Banner'), findsOneWidget);
      expect(find.text('Select colour'), findsNWidgets(2));
      expect(find.text('#123456'), findsNothing);
      expect(find.text('#ABCDEF'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('branding colours are selected from a palette without hex input',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_appForStep(5));
    await tester.pumpAndSettle();

    final primaryPicker =
        find.byKey(const ValueKey('online-store-primary-colour-picker'));
    await tester.ensureVisible(primaryPicker);
    await tester.pumpAndSettle();
    await tester.tap(primaryPicker);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.bySemanticsLabel('Colour option 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Colour option 2'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner manager remains visible for an empty banner list',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester
        .pumpWidget(_appForStep(5, repository: _EmptyBannerRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Banner Manager'), findsOneWidget);
    expect(find.text('No storefront banners yet'), findsOneWidget);
    expect(find.text('Add Banner'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders backend-driven contact support at target widths',
      (tester) async {
    for (final size in const [
      Size(1024, 768),
      Size(1280, 800),
      Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_appForStep(6));
      await tester.pumpAndSettle();

      expect(find.text('CONTACT & SUPPORT'), findsOneWidget);
      expect(find.text('STEP 6 OF 9'), findsOneWidget);
      expect(find.text('Customer Contact'), findsOneWidget);
      expect(find.text('Support Settings'), findsOneWidget);
      expect(find.text('Customer Support Preview'), findsOneWidget);
      expect(
          find.widgetWithText(TextField, 'help@example.test'), findsOneWidget);
      expect(find.widgetWithText(TextField, '+94110000000'), findsOneWidget);
      expect(find.widgetWithText(TextField, '+94770000000'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'https://support.example.test'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Example support address'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          TextField,
          'Mon - Fri: 9:00 AM - 6:00 PM',
        ),
        findsOneWidget,
      );
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('All changes saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Step 6 Back navigates to Step 5', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeOnlineStoreRepository();
    await tester.pumpWidget(_routerAppForSupport(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('step-5-target'), findsOneWidget);
    expect(repository.supportUpdateCount, 0);
  });

  testWidgets('Step 6 clean Continue navigates without PUT', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeOnlineStoreRepository();
    await tester.pumpWidget(_routerAppForSupport(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('step-7-target'), findsOneWidget);
    expect(repository.supportUpdateCount, 0);
  });

  testWidgets('Step 6 dirty Continue waits for successful PUT', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeOnlineStoreRepository();
    await tester.pumpWidget(_routerAppForSupport(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'help@example.test'),
      'changed@example.test',
    );
    await tester.pump();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.supportUpdateCount, 1);
    expect(find.text('step-7-target'), findsOneWidget);
  });

  testWidgets('Step 6 failed dirty save remains on Step 6', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeOnlineStoreRepository(failSupportUpdate: true);
    await tester.pumpWidget(_routerAppForSupport(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'help@example.test'),
      'changed@example.test',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.supportUpdateCount, 1);
    expect(find.text('CONTACT & SUPPORT'), findsOneWidget);
    expect(find.text('Changes not saved'), findsOneWidget);
    expect(find.text('step-7-target'), findsNothing);
  });

  testWidgets('renders premium overview dashboard at tablet landscape width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appForStep(1));
    await tester.pumpAndSettle();

    expect(find.text('ONLINE STORE OVERVIEW'), findsOneWidget);
    expect(find.text('Setup Readiness'), findsOneWidget);
    expect(find.text('Setup Insights'), findsOneWidget);
    expect(find.text('Build. Configure. Launch.'), findsOneWidget);
    expect(find.text('Next Steps'), findsOneWidget);
    expect(find.text('Preview Storefront'), findsOneWidget);
    expect(find.text('Continue Setup'), findsOneWidget);
    expect(find.text('All changes saved'), findsOneWidget);
    expect(find.text('Store Setup Summary'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders premium activation layout at tablet landscape width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appForStep(2));
    await tester.pumpAndSettle();

    expect(find.text('ONLINE STORE ACTIVATION'), findsOneWidget);
    expect(find.text('STEP 2 OF 9'), findsOneWidget);
    expect(
      find.text('Your store remains private until you publish it.'),
      findsOneWidget,
    );
    expect(find.text('Launch Configuration'), findsOneWidget);
    expect(find.text('Online Store Enabled'), findsOneWidget);
    expect(find.text('Release Scope'), findsOneWidget);
    expect(find.text('Checkout Mode'), findsOneWidget);
    expect(find.text('Email Verification'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Setup Readiness'), findsOneWidget);
    expect(find.text('Channel Entitlement'), findsOneWidget);
    expect(find.text('Authentication Ready'), findsOneWidget);
    expect(find.text('Email Service Ready'), findsOneWidget);
    expect(find.text('Collection Outlet Requirement'), findsOneWidget);
    expect(find.text('Private Until Published'), findsOneWidget);
    expect(find.text('Back to Overview'), findsOneWidget);
    expect(find.text('Save & Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders backend-driven Store Identity contract', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appForStep(3));
    await tester.pumpAndSettle();

    expect(find.text('STORE IDENTITY'), findsOneWidget);
    expect(find.text('STEP 3 OF 9'), findsOneWidget);
    expect(
      find.textContaining('Online Store Name', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Business Display Name', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Store Description', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Order Notification Email', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Support Tagline', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Release 1 Checkout Rules'), findsOneWidget);
    expect(find.text('Customer Account'), findsOneWidget);
    expect(find.text('Guest Checkout'), findsOneWidget);
    expect(find.text('Email Verification'), findsOneWidget);
    expect(find.text('Fulfilment Mode'), findsOneWidget);
    expect(find.text('Payment Mode'), findsOneWidget);
    expect(find.text('Registration required'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('Click & Collect'), findsOneWidget);
    expect(find.text('Pay at Pickup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders backend-driven Storefront URL and Domain contract',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appForStep(4));
    await tester.pumpAndSettle();

    expect(find.text('STOREFRONT URL & DOMAIN'), findsOneWidget);
    expect(find.text('STEP 4 OF 9'), findsOneWidget);
    expect(find.text('Storefront URL'), findsOneWidget);
    expect(find.text('Domain Verification'), findsOneWidget);
    expect(
        find.textContaining('Store Slug', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Default Store URL', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Custom Domain (Optional)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Manage Domains'), findsOneWidget);
    expect(find.text('DNS Verification'), findsOneWidget);
    expect(find.text('TXT Record'), findsOneWidget);
    expect(find.text('SSL Certificate'), findsOneWidget);
    expect(find.text('Primary Domain'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'short tablet overview scrolls through fulfilment launch and insights',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appForStep(1));
    await tester.pumpAndSettle();

    final scrollable = find.byKey(
      const ValueKey('online-store-content-scroll'),
    );
    expect(scrollable, findsOneWidget);
    expect(find.text('FULFILMENT'), findsOneWidget);
    expect(find.text('LAUNCH'), findsOneWidget);

    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.text('Setup Insights'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('online-store-bottom-actions')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows backend error state with retry action', (tester) async {
    await tester.pumpWidget(
      _appForStep(
        1,
        repository: _FakeOnlineStoreRepository(throwOverview: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Online Store data unavailable'), findsOneWidget);
    expect(find.text('Bad state: backend unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

const _expectedHeaders = {
  1: 'Online Store Overview',
  2: 'Online Store Activation',
  3: 'Store Identity',
  4: 'Storefront URL & Domain',
  5: 'Branding & Banners',
  6: 'Contact & Support',
  7: 'Configure Click & Collect',
  8: 'Products & Policies',
  9: 'Review & Publish',
};

Widget _appForStep(
  int stepNumber, {
  _FakeOnlineStoreRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      tenantAdminAccessCheckerProvider.overrideWith(
        (ref) async => TenantAdminAccessChecker(_accessContext()),
      ),
      onlineStoreRepositoryProvider.overrideWithValue(
        repository ?? _FakeOnlineStoreRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: OnlineStoreSetupScreen(stepNumber: stepNumber),
        ),
      ),
    ),
  );
}

Widget _routerAppForSupport(_FakeOnlineStoreRepository repository) {
  final router = GoRouter(
    initialLocation: '/tenant-admin/online-store/support',
    routes: [
      GoRoute(
        path: '/tenant-admin/online-store/branding',
        builder: (_, __) => const Scaffold(body: Text('step-5-target')),
      ),
      GoRoute(
        path: '/tenant-admin/online-store/support',
        builder: (_, __) => const Scaffold(
          body: SizedBox.expand(
            child: OnlineStoreSetupScreen(stepNumber: 6),
          ),
        ),
      ),
      GoRoute(
        path: '/tenant-admin/online-store/click-collect',
        builder: (_, __) => const Scaffold(body: Text('step-7-target')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      tenantAdminAccessCheckerProvider.overrideWith(
        (ref) async => TenantAdminAccessChecker(_accessContext()),
      ),
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

TenantAdminContext _accessContext() {
  const permissions = [
    TenantAdminPermissionCodes.onlineStoreView,
    TenantAdminPermissionCodes.onlineStoreManage,
    TenantAdminPermissionCodes.onlineStorePublish,
    TenantAdminPermissionCodes.onlineStoreDomainsManage,
    TenantAdminPermissionCodes.onlineStoreBrandingManage,
    TenantAdminPermissionCodes.onlineStoreSupportManage,
    TenantAdminPermissionCodes.onlineStoreFulfillmentManage,
    TenantAdminPermissionCodes.onlineStoreCatalogManage,
    TenantAdminPermissionCodes.onlineStorePoliciesManage,
  ];

  return TenantAdminContext(
    tenantId: 'tenant-1',
    tenantName: 'Tenant',
    userId: 'user-1',
    userDisplayName: 'Admin',
    roles: const [],
    roleNames: const [],
    outletScope: const [],
    featureEntitlements: const [
      TenantAdminFeatureEntitlement(
        featureCode: TenantAdminFeatureCodes.onlineStore,
        featureName: 'Online Store',
        enabled: true,
      ),
      TenantAdminFeatureEntitlement(
        featureCode: TenantAdminFeatureCodes.clickCollect,
        featureName: 'Click & Collect',
        enabled: true,
      ),
    ],
    permissions: [
      for (final permission in permissions)
        TenantAdminPermission(
          permissionCode: permission,
          permissionName: permission,
        ),
    ],
    runtimeFlags: const [],
  );
}

class _FakeOnlineStoreRepository implements OnlineStoreRepository {
  _FakeOnlineStoreRepository({
    this.throwOverview = false,
    this.failSupportUpdate = false,
  });

  final bool throwOverview;
  final bool failSupportUpdate;
  int supportUpdateCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<OnlineStoreOverview> getOverview() async {
    if (throwOverview) {
      throw StateError('backend unavailable');
    }
    return const OnlineStoreOverview(
      salesChannelId: 'channel-1',
      storeStatus: 'DRAFT',
      channelStatus: 'INACTIVE',
      setupEnabled: true,
      visibility: 'NOT_LIVE',
      storeSlug: 'tenant-store',
      hostedUrl: 'https://tenant-store.oneverz.shop',
      completedSteps: 6,
      totalSteps: 9,
      setupProgressPercent: 66,
      steps: _steps,
      readiness: _readiness,
    );
  }

  @override
  Future<OnlineStoreReadiness> getReadiness() async => _readiness;

  @override
  Future<OnlineStoreActivation> getActivation() async {
    return const OnlineStoreActivation(
      setupEnabled: true,
      storeStatus: 'DRAFT',
      channelStatus: 'INACTIVE',
      visibility: 'NOT_LIVE',
      releaseScope: 'CLICK_COLLECT_ONLY',
      checkoutMode: 'REGISTRATION_REQUIRED',
      emailVerificationRequired: true,
      paymentMode: 'PAY_AT_PICKUP',
      notificationsStatus: 'READY',
      privateUntilPublished: true,
      entitlements: [
        OnlineStoreEntitlement(
          featureCode: TenantAdminFeatureCodes.onlineStore,
          status: 'ENABLED',
        ),
        OnlineStoreEntitlement(
          featureCode: TenantAdminFeatureCodes.clickCollect,
          status: 'ENABLED',
        ),
      ],
      readiness: [
        OnlineStoreActivationReadinessItem(
          code: 'channel_entitlement',
          label: 'Channel Entitlement',
          status: 'READY',
          message: 'Your tenant is entitled to Online Store.',
        ),
        OnlineStoreActivationReadinessItem(
          code: 'authentication_ready',
          label: 'Authentication Ready',
          status: 'READY',
          message: 'Registered customer authentication is available.',
        ),
        OnlineStoreActivationReadinessItem(
          code: 'email_service_ready',
          label: 'Email Service Ready',
          status: 'READY',
          message: 'Email service is configured and active.',
        ),
        OnlineStoreActivationReadinessItem(
          code: 'collection_outlet_requirement',
          label: 'Collection Outlet Requirement',
          status: 'REQUIRED',
          message:
              'Configure at least one eligible collection outlet in Step 7.',
        ),
      ],
    );
  }

  @override
  Future<OnlineStoreIdentity> getIdentity() async {
    return const OnlineStoreIdentity(
      salesChannelId: 'channel-1',
      storeName: 'Backend Store',
      businessDisplayName: 'Backend Store',
      currencyCode: 'LKR',
      timezone: 'Asia/Colombo',
      storeEmail: 'support@example.com',
      storePhone: '+94771234567',
    );
  }

  @override
  Future<OnlineStoreCheckoutRules> getCheckoutRules() async {
    return const OnlineStoreCheckoutRules(
      release: 'R1',
      customerAccount: OnlineStoreCustomerAccountRule(
        registrationRequired: true,
        mode: 'REGISTRATION_REQUIRED',
        label: 'Registration required',
      ),
      guestCheckout: OnlineStoreGuestCheckoutRule(
        available: false,
        mode: 'NOT_AVAILABLE',
        label: 'Not available',
      ),
      emailVerification: OnlineStoreEmailVerificationRule(
        required: true,
        mode: 'REQUIRED',
        label: 'Required',
      ),
      fulfilment: OnlineStoreFulfilmentRule(
        mode: 'CLICK_COLLECT',
        label: 'Click & Collect',
        featureEnabled: true,
        configured: true,
      ),
      payment: OnlineStorePaymentRule(
        mode: 'PAY_AT_PICKUP',
        label: 'Pay at Pickup',
      ),
    );
  }

  @override
  Future<OnlineStoreUrlDomain> getUrlDomain() async {
    return const OnlineStoreUrlDomain(
      storeSlug: 'tenant-store',
      hostedUrl: 'https://tenant-store.oneverz.shop',
      domains: [
        OnlineStoreDomain(
          id: 'domain-1',
          domainType: 'HOSTED',
          domainName: 'tenant-store.oneverz.shop',
          isPrimary: true,
          verificationStatus: 'VERIFIED',
          sslStatus: 'ACTIVE',
          status: 'ACTIVE',
        ),
        OnlineStoreDomain(
          id: 'domain-2',
          domainType: 'CUSTOM',
          domainName: 'store.example.com',
          isPrimary: false,
          verificationStatus: 'PENDING',
          sslStatus: 'NOT_REQUESTED',
          status: 'ACTIVE',
        ),
      ],
    );
  }

  @override
  Future<OnlineStoreBranding> getBranding() async {
    return const OnlineStoreBranding(
      logoMediaAssetId: 'logo-1',
      faviconMediaAssetId: 'favicon-1',
      logoImageUrl: 'https://cdn.example.com/logo.png',
      faviconImageUrl: 'https://cdn.example.com/favicon.ico',
      primaryColor: '#123456',
      secondaryColor: '#ABCDEF',
      banners: [
        OnlineStoreBanner(
          id: 'banner-1',
          bannerType: 'HERO',
          title: 'Hero Banner',
          sortOrder: 1,
          status: 'ACTIVE',
        ),
      ],
    );
  }

  @override
  Future<OnlineStoreSupport> getSupport() async {
    return const OnlineStoreSupport(
      email: 'help@example.test',
      phone: '+94110000000',
      whatsapp: '+94770000000',
      helpUrl: 'https://support.example.test',
      contactUsEnabled: true,
      supportHours: 'Mon - Fri: 9:00 AM - 6:00 PM',
      businessAddress: 'Example support address',
    );
  }

  @override
  Future<OnlineStoreClickCollect> getClickCollect() async {
    return const OnlineStoreClickCollect(
      enabled: true,
      outletCount: 1,
      outlets: [
        OnlineStoreCollectionOutlet(
          outletId: 'outlet-1',
          outletName: 'Main Outlet',
          outletStatus: 'ACTIVE',
          businessHoursConfigured: true,
          preparationLeadMinutes: 120,
          pickupWindowMinutes: 120,
          cutoffTime: '19:00',
          status: 'ACTIVE',
        ),
      ],
    );
  }

  @override
  Future<OnlineStoreCatalogSummary> getCatalogSummary() async {
    return const OnlineStoreCatalogSummary(
      totalProducts: 10,
      visibleOnline: 6,
      notVisible: 4,
      orderable: 6,
      lowStockProducts: 1,
      outOfStockProducts: 0,
    );
  }

  @override
  Future<List<OnlineStorePolicy>> listPolicies() async {
    return const [
      OnlineStorePolicy(
        id: 'policy-1',
        policyType: 'TERMS',
        title: 'Terms & Conditions',
        content: 'Terms',
        version: 'v1',
        status: 'PUBLISHED',
      ),
    ];
  }

  @override
  Future<OnlineStorePublishResult> publish(String idempotencyKey) async {
    return OnlineStorePublishResult(
      storeStatus: 'PUBLISHED',
      channelStatus: 'ACTIVE',
      publishedAt: DateTime.utc(2026, 8, 14),
      readiness: _readiness,
    );
  }

  @override
  Future<List<OnlineStoreBanner>> listBanners() async =>
      (await getBranding()).banners;

  @override
  Future<List<OnlineStoreCollectionOutlet>> listClickCollectOutlets() async =>
      (await getClickCollect()).outlets;

  @override
  Future<List<OnlineStoreDomain>> listDomains() async =>
      (await getUrlDomain()).domains;

  @override
  Future<OnlineStoreCatalogProductList> listCatalogProducts({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return OnlineStoreCatalogProductList(
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalCount: 0,
      items: const [],
    );
  }

  @override
  Future<void> deleteMedia(String mediaAssetId) async {}

  @override
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled) =>
      getActivation();

  @override
  Future<OnlineStoreBranding> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) =>
      getBranding();

  @override
  Future<OnlineStoreClickCollect> updateClickCollect(bool enabled) =>
      getClickCollect();

  @override
  Future<OnlineStoreIdentity> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) =>
      getIdentity();

  @override
  Future<OnlineStoreSupport> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) async {
    supportUpdateCount += 1;
    if (failSupportUpdate) throw StateError('support update failed');
    return OnlineStoreSupport(
      email: email,
      phone: phone,
      whatsapp: whatsapp,
      helpUrl: helpUrl,
      contactUsEnabled: contactUsEnabled,
      supportHours: supportHours,
      businessAddress: businessAddress,
    );
  }

  @override
  Future<OnlineStoreUrlDomain> updateUrl(String storeSlug) => getUrlDomain();

  @override
  Future<OnlineStoreMedia> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    return OnlineStoreMedia(
      mediaAssetId: 'media-1',
      purpose: purpose,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
    );
  }
}

class _EmptyBannerRepository extends _FakeOnlineStoreRepository {
  @override
  Future<OnlineStoreBranding> getBranding() async {
    final branding = await super.getBranding();
    return OnlineStoreBranding(
      logoMediaAssetId: branding.logoMediaAssetId,
      faviconMediaAssetId: branding.faviconMediaAssetId,
      logoImageUrl: branding.logoImageUrl,
      faviconImageUrl: branding.faviconImageUrl,
      primaryColor: branding.primaryColor,
      secondaryColor: branding.secondaryColor,
      banners: const [],
    );
  }
}

const _steps = [
  OnlineStoreStep(
    stepNumber: 1,
    code: 'OVERVIEW',
    label: 'Overview',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 2,
    code: 'ACTIVATION',
    label: 'Activation',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 3,
    code: 'IDENTITY',
    label: 'Identity',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 4,
    code: 'DOMAIN',
    label: 'Domain',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 5,
    code: 'BRANDING',
    label: 'Branding',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 6,
    code: 'SUPPORT',
    label: 'Support',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 7,
    code: 'CLICK_COLLECT',
    label: 'Click & Collect',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 8,
    code: 'PRODUCTS_POLICIES',
    label: 'Products & Policies',
    status: 'PASS',
    blockingReasons: [],
  ),
  OnlineStoreStep(
    stepNumber: 9,
    code: 'REVIEW',
    label: 'Review & Publish',
    status: 'PASS',
    blockingReasons: [],
  ),
];

const _readiness = OnlineStoreReadiness(
  canPublish: true,
  blockingReasons: [],
  steps: _steps,
);
