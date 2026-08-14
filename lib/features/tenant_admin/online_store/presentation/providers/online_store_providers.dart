import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/online_store_remote_datasource.dart';
import '../../data/repositories/online_store_repository_impl.dart';
import '../../domain/entities/online_store.dart';
import '../../domain/repositories/online_store_repository.dart';

final onlineStoreRemoteDatasourceProvider =
    Provider<OnlineStoreRemoteDatasource>((ref) {
  return OnlineStoreRemoteDatasource(ref.watch(appDioProvider));
});

final onlineStoreRepositoryProvider = Provider<OnlineStoreRepository>((ref) {
  return OnlineStoreRepositoryImpl(
    ref.watch(onlineStoreRemoteDatasourceProvider),
  );
});

final onlineStoreOverviewProvider =
    FutureProvider.autoDispose<OnlineStoreOverview>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getOverview();
});

final onlineStoreReadinessProvider =
    FutureProvider.autoDispose<OnlineStoreReadiness>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getReadiness();
});

final onlineStoreActivationProvider =
    FutureProvider.autoDispose<OnlineStoreActivation>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getActivation();
});

final onlineStoreIdentityProvider =
    FutureProvider.autoDispose<OnlineStoreIdentity>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getIdentity();
});

final onlineStoreUrlDomainProvider =
    FutureProvider.autoDispose<OnlineStoreUrlDomain>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getUrlDomain();
});

final onlineStoreBrandingProvider =
    FutureProvider.autoDispose<OnlineStoreBranding>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getBranding();
});

final onlineStoreSupportProvider =
    FutureProvider.autoDispose<OnlineStoreSupport>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getSupport();
});

final onlineStoreClickCollectProvider =
    FutureProvider.autoDispose<OnlineStoreClickCollect>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getClickCollect();
});

final onlineStoreCatalogSummaryProvider =
    FutureProvider.autoDispose<OnlineStoreCatalogSummary>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).getCatalogSummary();
});

final onlineStorePoliciesProvider =
    FutureProvider.autoDispose<List<OnlineStorePolicy>>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).listPolicies();
});

final onlineStoreCatalogProductsProvider =
    FutureProvider.autoDispose<OnlineStoreCatalogProductList>((ref) {
  return ref.watch(onlineStoreRepositoryProvider).listCatalogProducts(
        pageNumber: 1,
        pageSize: 12,
      );
});

final onlineStoreProductsPoliciesProvider =
    FutureProvider.autoDispose<OnlineStoreProductsPoliciesData>((ref) async {
  final repository = ref.watch(onlineStoreRepositoryProvider);
  final results = await Future.wait<Object>([
    repository.getCatalogSummary(),
    repository.listPolicies(),
  ]);

  return OnlineStoreProductsPoliciesData(
    summary: results[0] as OnlineStoreCatalogSummary,
    policies: results[1] as List<OnlineStorePolicy>,
  );
});

class OnlineStoreProductsPoliciesData {
  const OnlineStoreProductsPoliciesData({
    required this.summary,
    required this.policies,
  });

  final OnlineStoreCatalogSummary summary;
  final List<OnlineStorePolicy> policies;
}

final onlineStoreMutationControllerProvider = StateNotifierProvider.autoDispose<
    OnlineStoreMutationController, AsyncValue<void>>((ref) {
  return OnlineStoreMutationController(ref);
});

class OnlineStoreMutationController extends StateNotifier<AsyncValue<void>> {
  OnlineStoreMutationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  String? _publishIdempotencyKey;
  Future<void>? _publishInFlight;

  OnlineStoreRepository get _repository =>
      _ref.read(onlineStoreRepositoryProvider);

  Future<void> updateActivation(bool setupEnabled) {
    return _run(() async {
      await _repository.updateActivation(setupEnabled);
      _refreshCommon();
      _ref.invalidate(onlineStoreActivationProvider);
    });
  }

  Future<void> updateIdentity({
    required String storeName,
    required String businessDisplayName,
    String? storeDescription,
    String? storeEmail,
    String? storePhone,
    String? supportTagline,
  }) {
    return _run(() async {
      await _repository.updateIdentity(
        storeName: storeName,
        businessDisplayName: businessDisplayName,
        storeDescription: storeDescription,
        storeEmail: storeEmail,
        storePhone: storePhone,
        supportTagline: supportTagline,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreIdentityProvider);
    });
  }

  Future<void> updateUrl(String storeSlug) {
    return _run(() async {
      await _repository.updateUrl(storeSlug);
      _refreshCommon();
      _ref.invalidate(onlineStoreUrlDomainProvider);
    });
  }

  Future<OnlineStoreMedia?> uploadMedia({
    required String purpose,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    OnlineStoreMedia? media;
    await _run(() async {
      media = await _repository.uploadMedia(
        purpose: purpose,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: onProgress,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
    return media;
  }

  Future<void> deleteMedia(String mediaAssetId) {
    return _run(() async {
      await _repository.deleteMedia(mediaAssetId);
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
  }

  Future<void> updateBranding({
    String? logoMediaAssetId,
    String? faviconMediaAssetId,
    required String primaryColor,
    required String secondaryColor,
  }) {
    return _run(() async {
      await _repository.updateBranding(
        logoMediaAssetId: logoMediaAssetId,
        faviconMediaAssetId: faviconMediaAssetId,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreBrandingProvider);
    });
  }

  Future<void> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) {
    return _run(() async {
      await _repository.updateSupport(
        email: email,
        phone: phone,
        whatsapp: whatsapp,
        helpUrl: helpUrl,
        contactUsEnabled: contactUsEnabled,
        supportHours: supportHours,
        businessAddress: businessAddress,
      );
      _refreshCommon();
      _ref.invalidate(onlineStoreSupportProvider);
    });
  }

  Future<void> updateClickCollect(bool enabled) {
    return _run(() async {
      await _repository.updateClickCollect(enabled);
      _refreshCommon();
      _ref.invalidate(onlineStoreClickCollectProvider);
    });
  }

  Future<void> publish() {
    final inFlight = _publishInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _publishIdempotencyKey ??=
        'online-store-publish-${DateTime.now().microsecondsSinceEpoch}';

    final future = _run(() async {
      await _repository.publish(_publishIdempotencyKey!);
      _publishIdempotencyKey = null;
      _refreshCommon();
    }).catchError((Object error) {
      if (!_isAmbiguousPublishFailure(error)) {
        _publishIdempotencyKey = null;
      }
      throw error;
    }).whenComplete(() {
      _publishInFlight = null;
    });

    _publishInFlight = future;
    return future;
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _refreshCommon() {
    _ref.invalidate(onlineStoreOverviewProvider);
    _ref.invalidate(onlineStoreReadinessProvider);
  }

  bool _isAmbiguousPublishFailure(Object error) {
    if (error is! DioException) {
      return false;
    }

    if (error.response != null) {
      return false;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown =>
        true,
      _ => false,
    };
  }
}
