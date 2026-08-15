import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(find.text('CLICK & COLLECT CONFIGURATION'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
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
  2: 'Activation & Access',
  3: 'Store Identity',
  4: 'Storefront URL & Domain',
  5: 'Branding & Appearance',
  6: 'Contact & Support',
  7: 'Click & Collect Configuration',
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
  const _FakeOnlineStoreRepository({this.throwOverview = false});

  final bool throwOverview;

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
      ],
    );
  }

  @override
  Future<OnlineStoreBranding> getBranding() async {
    return const OnlineStoreBranding(
      logoMediaAssetId: 'logo-1',
      faviconMediaAssetId: 'favicon-1',
      primaryColor: '#FF6A00',
      secondaryColor: '#000000',
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
      email: 'support@example.com',
      phone: '+94771234567',
      whatsapp: '+94771234567',
      helpUrl: 'https://example.com/help',
      contactUsEnabled: true,
      supportHours: 'Mon - Fri',
      businessAddress: 'Main Street',
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
  }) =>
      getSupport();

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
