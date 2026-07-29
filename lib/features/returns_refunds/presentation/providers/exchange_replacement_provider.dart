import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/domain/entities/pos_catalog_models.dart';
import '../../../cart/presentation/providers/pos_catalog_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/exchange_replacement_selection.dart';
import '../../domain/entities/return_exchange.dart';
import 'return_flow_provider.dart';
import 'return_search_provider.dart';

class ExchangeReplacementSearchState {
  const ExchangeReplacementSearchState({
    this.searchQuery = '',
    this.inStockOnly = false,
    this.showFilters = false,
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
    this.currencyCode = '',
    this.requestToken = 0,
    this.isForbidden = false,
  });

  final String searchQuery;
  final bool inStockOnly;
  final bool showFilters;
  final bool isLoading;
  final String? errorMessage;
  final List<ReturnExchangeProduct> products;
  final String currencyCode;
  final int requestToken;
  final bool isForbidden;

  ExchangeReplacementSearchState copyWith({
    String? searchQuery,
    bool? inStockOnly,
    bool? showFilters,
    bool? isLoading,
    String? errorMessage,
    List<ReturnExchangeProduct>? products,
    String? currencyCode,
    int? requestToken,
    bool? isForbidden,
    bool clearError = false,
  }) {
    return ExchangeReplacementSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      showFilters: showFilters ?? this.showFilters,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      products: products ?? this.products,
      currencyCode: currencyCode ?? this.currencyCode,
      requestToken: requestToken ?? this.requestToken,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class ExchangeReplacementSearchController
    extends StateNotifier<ExchangeReplacementSearchState> {
  ExchangeReplacementSearchController(this._ref)
      : super(const ExchangeReplacementSearchState()) {
    _ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _cancelToken?.cancel('Exchange search disposed.');
    });
  }

  final Ref _ref;
  Timer? _debounce;
  CancelToken? _cancelToken;
  var _disposed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('Exchange search disposed.');
    super.dispose();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearError: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(loadProducts());
    });
  }

  void toggleFilters() {
    state = state.copyWith(showFilters: !state.showFilters);
  }

  void setInStockOnly(bool value) {
    state = state.copyWith(inStockOnly: value);
    unawaited(loadProducts());
  }

  Future<void> loadProducts() async {
    final granted =
        _ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canProcessExchange(granted)) {
      state = state.copyWith(
        isLoading: false,
        products: const [],
        isForbidden: true,
        errorMessage: 'You do not have permission to search exchange products.',
      );
      return;
    }

    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        products: const [],
        errorMessage:
            'Complete earlier return steps before searching products.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        products: const [],
        errorMessage: 'Device context is required to search products.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final token = state.requestToken + 1;
    _cancelToken?.cancel('Superseded exchange product search.');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    state = state.copyWith(
      isLoading: true,
      requestToken: token,
      clearError: true,
    );

    try {
      final response = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .searchExchangeProducts(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            search: state.searchQuery,
            cancelToken: cancelToken,
          );

      if (_disposed || token != state.requestToken) {
        return;
      }

      final filtered = [
        for (final product in response.items)
          if (!state.inStockOnly || !product.isOutOfStock) product,
      ];

      state = state.copyWith(
        isLoading: false,
        products: filtered,
        currencyCode: response.currencyCode,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) ||
          _disposed ||
          token != state.requestToken) {
        return;
      }
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoading: false,
          products: const [],
          isForbidden: true,
          errorMessage:
              'You do not have permission to search exchange products.',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        products: const [],
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to search products',
          fallback: 'Unable to search products. Please try again.',
        ),
      );
    } catch (error) {
      if (_disposed || token != state.requestToken) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        products: const [],
        errorMessage: error is StateError
            ? error.message
            : 'Unable to search products. Please try again.',
      );
    }
  }

  Future<ExchangeReplacementSelection?> resolveSelection({
    required ReturnExchangeProduct product,
  }) async {
    if (product.isOutOfStock || !product.enabled) {
      return null;
    }

    if (!product.hasVariants) {
      final variantId = product.variantId ?? product.productId;
      return ExchangeReplacementSelection(
        productId: product.productId,
        productVariantId: variantId,
        productName: product.name,
        imageUrl: product.imageStorageKey,
        variantDisplayName: product.variantDisplayName ?? '',
        sku: product.sku,
        quantity: 1,
        unitPrice: product.sellingPrice,
        currencyCode: product.currencyCode.isNotEmpty
            ? product.currencyCode
            : state.currencyCode,
        stockStatus: product.stockStatus,
        availableQty: product.availableQuantity,
      );
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || deviceContext == null) {
      return null;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    final detail =
        await _ref.read(posCatalogRemoteDatasourceProvider).getProductDetail(
              deviceId: deviceContext.deviceId,
              productId: product.productId,
            );

    final selectable = detail.variants
        .where((variant) => !variant.isOutOfStock)
        .toList(growable: false);
    if (selectable.isEmpty) {
      return null;
    }

    if (selectable.length == 1) {
      return _selectionFromVariant(
        summary: detail.summary,
        variant: selectable.first,
        currencyCode: state.currencyCode,
      );
    }

    return null;
  }

  ExchangeReplacementSelection _selectionFromVariant({
    required PosCatalogProductSummary summary,
    required PosCatalogVariant variant,
    required String currencyCode,
  }) {
    final variantLabel = variant.attributes.entries
        .map((entry) => entry.value)
        .where((value) => value.trim().isNotEmpty)
        .join(' / ');

    return ExchangeReplacementSelection(
      productId: summary.productId,
      productVariantId: variant.variantId,
      productName: summary.name,
      imageUrl: summary.imageUrl,
      variantDisplayName:
          variantLabel.isEmpty ? summary.categoryName : variantLabel,
      sku: variant.sku,
      quantity: 1,
      unitPrice: variant.price.toDouble(),
      currencyCode: currencyCode,
      stockStatus: variant.stockStatus,
      availableQty: variant.stockQty,
    );
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final exchangeReplacementSearchProvider = StateNotifierProvider.autoDispose<
    ExchangeReplacementSearchController, ExchangeReplacementSearchState>(
  (ref) => ExchangeReplacementSearchController(ref),
);
