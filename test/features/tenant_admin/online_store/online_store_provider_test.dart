import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/domain/entities/online_store.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/domain/repositories/online_store_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/presentation/providers/online_store_providers.dart';

void main() {
  test('products and policies provider combines backend-driven data', () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(
      overrides: [
        onlineStoreRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final data =
        await container.read(onlineStoreProductsPoliciesProvider.future);

    expect(data.summary.totalProducts, 12);
    expect(data.policies.single.policyType, 'TERMS');
  });

  test('url domain provider combines summary with canonical domain list',
      () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    final data = await container.read(onlineStoreUrlDomainProvider.future);

    expect(data.storeSlug, 'tenant-store');
    expect(data.domains.single.domainName, 'store.example.com');
  });

  test('domain editor tracks dirty save and one-time DNS token', () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreDomainEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(onlineStoreDomainEditorProvider.notifier);

    controller.initialize(await repository.getUrlDomain());
    controller.updateStoreSlug('updated-store');
    expect(container.read(onlineStoreDomainEditorProvider).isDirty, isTrue);

    expect(await controller.saveIfNeeded(), isTrue);
    expect(repository.updatedSlug, 'updated-store');
    expect(container.read(onlineStoreDomainEditorProvider).isDirty, isFalse);

    expect(await controller.createDomain('new.example.com'), isTrue);
    expect(
      container
          .read(onlineStoreDomainEditorProvider)
          .verificationTokens['domain-new'],
      'dns-token',
    );
  });

  test('branding editor saves backend-supported colours and clears dirty state',
      () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreBrandingEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreBrandingEditorProvider.notifier);

    controller.initialize(await repository.getBranding());
    controller.updatePrimaryColor('#123456');
    controller.updateSecondaryColor('#ABCDEF');

    expect(container.read(onlineStoreBrandingEditorProvider).isDirty, isTrue);
    expect(await controller.saveIfNeeded(), isTrue);
    expect(repository.brandingUpdates.single.primaryColor, '#123456');
    expect(repository.brandingUpdates.single.secondaryColor, '#ABCDEF');
    expect(container.read(onlineStoreBrandingEditorProvider).isDirty, isFalse);
  });

  test('branding upload attaches new asset then deletes replaced asset',
      () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreBrandingEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreBrandingEditorProvider.notifier);
    controller.initialize(await repository.getBranding());

    final succeeded = await controller.uploadAndAttach(
      purpose: OnlineStoreBrandingEditorController.logoPurpose,
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'new-logo.png',
      mimeType: 'image/png',
    );

    expect(succeeded, isTrue);
    expect(repository.uploadedPurposes, ['ONLINE_STORE_LOGO']);
    expect(repository.brandingUpdates.single.logoMediaAssetId, 'uploaded-1');
    expect(repository.deletedMediaIds, ['logo-old']);
    expect(
      container.read(onlineStoreBrandingEditorProvider).logoMediaAssetId,
      'uploaded-1',
    );
  });

  test('branding attach failure preserves previous asset and cleans upload',
      () async {
    final repository = _FakeOnlineStoreRepository()
      ..failNextBrandingUpdate = true;
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreBrandingEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreBrandingEditorProvider.notifier);
    controller.initialize(await repository.getBranding());

    final succeeded = await controller.uploadAndAttach(
      purpose: OnlineStoreBrandingEditorController.logoPurpose,
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'new-logo.png',
      mimeType: 'image/png',
    );

    expect(succeeded, isFalse);
    expect(repository.deletedMediaIds, ['uploaded-1']);
    expect(
      container.read(onlineStoreBrandingEditorProvider).logoMediaAssetId,
      'logo-old',
    );
  });

  test('branding removal detaches asset before deleting media', () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreBrandingEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreBrandingEditorProvider.notifier);
    controller.initialize(await repository.getBranding());

    final succeeded = await controller.removeAsset(
      OnlineStoreBrandingEditorController.faviconPurpose,
    );

    expect(succeeded, isTrue);
    expect(repository.brandingUpdates.single.faviconMediaAssetId, isNull);
    expect(repository.deletedMediaIds, ['favicon-old']);
    expect(
      container.read(onlineStoreBrandingEditorProvider).faviconMediaAssetId,
      isNull,
    );
  });

  test('branding duplicate upload is rejected while first request is active',
      () async {
    final repository = _FakeOnlineStoreRepository()
      ..uploadCompleter = Completer<OnlineStoreMedia>();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreBrandingEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreBrandingEditorProvider.notifier);
    controller.initialize(await repository.getBranding());

    final first = controller.uploadAndAttach(
      purpose: OnlineStoreBrandingEditorController.logoPurpose,
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'logo.png',
      mimeType: 'image/png',
    );
    final second = await controller.uploadAndAttach(
      purpose: OnlineStoreBrandingEditorController.logoPurpose,
      bytes: Uint8List.fromList([4, 5, 6]),
      fileName: 'other.png',
      mimeType: 'image/png',
    );

    expect(second, isFalse);
    expect(repository.uploadedPurposes, hasLength(1));
    repository.uploadCompleter!.complete(
      const OnlineStoreMedia(
        mediaAssetId: 'uploaded-1',
        purpose: 'ONLINE_STORE_LOGO',
        fileName: 'logo.png',
        mimeType: 'image/png',
        fileSizeBytes: 3,
      ),
    );
    expect(await first, isTrue);
  });

  test('support editor applies backend normalization after successful save',
      () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreSupportEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreSupportEditorProvider.notifier);
    controller.initialize(await repository.getSupport());

    controller.updatePhone(' +94 11 000 0000 ');
    expect(container.read(onlineStoreSupportEditorProvider).isDirty, isTrue);
    expect(await controller.saveIfNeeded(), isTrue);

    expect(repository.supportUpdateCount, 1);
    expect(
        container.read(onlineStoreSupportEditorProvider).phone, '+94110000000');
    expect(container.read(onlineStoreSupportEditorProvider).isDirty, isFalse);
  });

  test('support save failure preserves dirty form values', () async {
    final repository = _FakeOnlineStoreRepository()..failSupportUpdate = true;
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreSupportEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreSupportEditorProvider.notifier);
    controller.initialize(await repository.getSupport());
    controller.updateEmail('changed@example.test');

    expect(await controller.saveIfNeeded(), isFalse);
    final state = container.read(onlineStoreSupportEditorProvider);
    expect(state.email, 'changed@example.test');
    expect(state.isDirty, isTrue);
    expect(state.errorMessage, isNotNull);
  });

  test('support duplicate save shares one backend request', () async {
    final repository = _FakeOnlineStoreRepository()
      ..supportCompleter = Completer<OnlineStoreSupport>();
    final container = ProviderContainer(overrides: [
      onlineStoreRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreSupportEditorProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    final controller =
        container.read(onlineStoreSupportEditorProvider.notifier);
    controller.initialize(await repository.getSupport());
    controller.updateBusinessAddress('Updated support address');

    final first = controller.saveIfNeeded();
    final second = controller.saveIfNeeded();
    expect(repository.supportUpdateCount, 1);
    repository.supportCompleter!.complete(
      const OnlineStoreSupport(
        email: 'help@example.test',
        phone: '+94110000000',
        whatsapp: '+94770000000',
        helpUrl: 'https://support.example.test',
        contactUsEnabled: true,
        supportHours: 'Mon - Fri: 9:00 AM - 6:00 PM',
        businessAddress: 'Updated support address',
      ),
    );
    expect(await first, isTrue);
    expect(await second, isTrue);
  });

  test('publish double tap sends one request with one idempotency key',
      () async {
    final repository = _FakeOnlineStoreRepository();
    final publishCompleter = Completer<OnlineStorePublishResult>();
    repository.publishCompleter = publishCompleter;
    final container = ProviderContainer(
      overrides: [
        onlineStoreRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreMutationControllerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final controller =
        container.read(onlineStoreMutationControllerProvider.notifier);
    final first = controller.publish();
    final second = controller.publish();

    expect(second, same(first));
    expect(repository.publishKeys, hasLength(1));

    publishCompleter.complete(_publishResult());
    await first;

    expect(repository.publishKeys.single, startsWith('online-store-publish-'));
  });

  test('publish timeout retry reuses same idempotency key', () async {
    final repository = _FakeOnlineStoreRepository()
      ..nextPublishError = DioException(
        requestOptions: RequestOptions(path: '/publish'),
        type: DioExceptionType.receiveTimeout,
      );
    final container = ProviderContainer(
      overrides: [
        onlineStoreRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreMutationControllerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final controller =
        container.read(onlineStoreMutationControllerProvider.notifier);
    await expectLater(controller.publish(), throwsA(isA<DioException>()));

    await controller.publish();

    expect(repository.publishKeys, hasLength(2));
    expect(repository.publishKeys[1], repository.publishKeys[0]);
  });

  test('publish success completes key lifecycle before next attempt', () async {
    final repository = _FakeOnlineStoreRepository();
    final container = ProviderContainer(
      overrides: [
        onlineStoreRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      onlineStoreMutationControllerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final controller =
        container.read(onlineStoreMutationControllerProvider.notifier);
    await controller.publish();
    await Future<void>.delayed(const Duration(microseconds: 1));
    await controller.publish();

    expect(repository.publishKeys, hasLength(2));
    expect(repository.publishKeys[1], isNot(repository.publishKeys[0]));
  });
}

OnlineStorePublishResult _publishResult() {
  return OnlineStorePublishResult(
    storeStatus: 'PUBLISHED',
    channelStatus: 'ACTIVE',
    publishedAt: DateTime.utc(2026, 8, 14),
    readiness: const OnlineStoreReadiness(
      canPublish: true,
      blockingReasons: [],
      steps: [],
    ),
  );
}

class _FakeOnlineStoreRepository implements OnlineStoreRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final List<String> publishKeys = [];
  Completer<OnlineStorePublishResult>? publishCompleter;
  Object? nextPublishError;
  String? updatedSlug;
  bool failNextBrandingUpdate = false;
  final List<_BrandingUpdate> brandingUpdates = [];
  final List<String> uploadedPurposes = [];
  final List<String> deletedMediaIds = [];
  Completer<OnlineStoreMedia>? uploadCompleter;
  Completer<OnlineStoreSupport>? supportCompleter;
  bool failSupportUpdate = false;
  int supportUpdateCount = 0;

  @override
  Future<OnlineStoreCatalogSummary> getCatalogSummary() async {
    return const OnlineStoreCatalogSummary(
      totalProducts: 12,
      visibleOnline: 8,
      notVisible: 4,
      orderable: 7,
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
        title: 'Terms',
        content: 'Terms body',
        version: 'v1',
        status: 'PUBLISHED',
      ),
    ];
  }

  @override
  Future<OnlineStorePublishResult> publish(String idempotencyKey) async {
    publishKeys.add(idempotencyKey);
    final error = nextPublishError;
    if (error != null) {
      nextPublishError = null;
      throw error;
    }
    final completer = publishCompleter;
    if (completer != null) {
      publishCompleter = null;
      return completer.future;
    }
    return _publishResult();
  }

  @override
  Future<OnlineStoreActivation> getActivation() => throw UnimplementedError();

  @override
  Future<OnlineStoreBranding> getBranding() async => const OnlineStoreBranding(
        logoMediaAssetId: 'logo-old',
        faviconMediaAssetId: 'favicon-old',
        logoImageUrl: 'https://cdn.example.com/logo-old.png',
        faviconImageUrl: 'https://cdn.example.com/favicon-old.ico',
        primaryColor: '#FF6A00',
        secondaryColor: '#000000',
        banners: [],
      );

  @override
  Future<OnlineStoreClickCollect> getClickCollect() =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreIdentity> getIdentity() => throw UnimplementedError();

  @override
  Future<OnlineStoreOverview> getOverview() => throw UnimplementedError();

  @override
  Future<OnlineStoreReadiness> getReadiness() => throw UnimplementedError();

  @override
  Future<OnlineStoreUrlDomain> getUrlDomain() async =>
      const OnlineStoreUrlDomain(
        storeSlug: 'tenant-store',
        hostedUrl: 'https://tenant-store.oneverz.shop',
        domains: [],
      );

  @override
  Future<List<OnlineStoreBanner>> listBanners() => throw UnimplementedError();

  @override
  Future<OnlineStoreCatalogProductList> listCatalogProducts({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<OnlineStoreCollectionOutlet>> listClickCollectOutlets() =>
      throw UnimplementedError();

  @override
  Future<List<OnlineStoreDomain>> listDomains() async => const [
        OnlineStoreDomain(
          id: 'domain-1',
          domainType: 'CUSTOM',
          domainName: 'store.example.com',
          isPrimary: false,
          verificationStatus: 'PENDING',
          sslStatus: 'NOT_REQUESTED',
          status: 'ACTIVE',
        ),
      ];

  @override
  Future<OnlineStoreDomainToken> createDomain({
    required String domainName,
    required String domainType,
    required bool isPrimary,
  }) async =>
      OnlineStoreDomainToken(
        domainId: 'domain-new',
        domainName: domainName,
        verificationToken: 'dns-token',
      );

  @override
  Future<void> deleteMedia(String mediaAssetId) async {
    deletedMediaIds.add(mediaAssetId);
  }

  @override
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreBranding> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) async {
    if (failNextBrandingUpdate) {
      failNextBrandingUpdate = false;
      throw StateError('update failed');
    }
    brandingUpdates.add(
      _BrandingUpdate(
        logoMediaAssetId: logoMediaAssetId,
        faviconMediaAssetId: faviconMediaAssetId,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
    );
    return OnlineStoreBranding(
      logoMediaAssetId: logoMediaAssetId,
      faviconMediaAssetId: faviconMediaAssetId,
      logoImageUrl: logoMediaAssetId == null
          ? null
          : 'https://cdn.example.com/$logoMediaAssetId.png',
      faviconImageUrl: faviconMediaAssetId == null
          ? null
          : 'https://cdn.example.com/$faviconMediaAssetId.ico',
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      banners: const [],
    );
  }

  @override
  Future<OnlineStoreClickCollect> updateClickCollect(bool enabled) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreIdentity> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) =>
      throw UnimplementedError();

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
    final completer = supportCompleter;
    if (completer != null) return completer.future;
    final normalizedPhone = phone == null
        ? null
        : '${phone.trim().startsWith('+') ? '+' : ''}${phone.replaceAll(RegExp(r'\D'), '')}';
    return OnlineStoreSupport(
      email: email?.trim(),
      phone: normalizedPhone,
      whatsapp: whatsapp?.trim(),
      helpUrl: helpUrl?.trim(),
      contactUsEnabled: contactUsEnabled,
      supportHours: supportHours?.trim(),
      businessAddress: businessAddress?.trim(),
    );
  }

  @override
  Future<OnlineStoreUrlDomain> updateUrl(String storeSlug) async {
    updatedSlug = storeSlug;
    return OnlineStoreUrlDomain(
      storeSlug: storeSlug,
      hostedUrl: 'https://$storeSlug.oneverz.shop',
      domains: const [],
    );
  }

  @override
  Future<OnlineStoreMedia> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploadedPurposes.add(purpose);
    onProgress?.call(bytes.length, bytes.length);
    final completer = uploadCompleter;
    if (completer != null) return completer.future;
    return OnlineStoreMedia(
      mediaAssetId: 'uploaded-1',
      purpose: purpose,
      publicUrl: 'https://cdn.example.com/uploaded-1.png',
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
    );
  }

  @override
  Future<OnlineStoreSupport> getSupport() async => const OnlineStoreSupport(
        email: 'help@example.test',
        phone: '+94110000000',
        whatsapp: '+94770000000',
        helpUrl: 'https://support.example.test',
        contactUsEnabled: true,
        supportHours: 'Mon - Fri: 9:00 AM - 6:00 PM',
        businessAddress: 'Example support address',
      );
}

class _BrandingUpdate {
  const _BrandingUpdate({
    required this.logoMediaAssetId,
    required this.faviconMediaAssetId,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String? logoMediaAssetId;
  final String? faviconMediaAssetId;
  final String primaryColor;
  final String secondaryColor;
}
