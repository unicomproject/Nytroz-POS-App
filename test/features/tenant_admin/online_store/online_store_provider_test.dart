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
  final List<String> publishKeys = [];
  Completer<OnlineStorePublishResult>? publishCompleter;
  Object? nextPublishError;

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
  Future<OnlineStoreBranding> getBranding() => throw UnimplementedError();

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
  Future<OnlineStoreUrlDomain> getUrlDomain() => throw UnimplementedError();

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
  Future<List<OnlineStoreDomain>> listDomains() => throw UnimplementedError();

  @override
  Future<void> deleteMedia(String mediaAssetId) => throw UnimplementedError();

  @override
  Future<OnlineStoreActivation> updateActivation(bool setupEnabled) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreBranding> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreUrlDomain> updateUrl(String storeSlug) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreMedia> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) =>
      throw UnimplementedError();

  @override
  Future<OnlineStoreSupport> getSupport() => throw UnimplementedError();
}
