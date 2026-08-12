import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../discount/presentation/providers/pos_discount_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/pos_customer.dart';
import 'pos_checkout_summary_provider.dart';

final checkoutCustomerProvider = NotifierProvider.autoDispose<
    CheckoutCustomerNotifier, CheckoutCustomerState>(
  CheckoutCustomerNotifier.new,
);

class CheckoutCustomerState {
  const CheckoutCustomerState({
    this.items = const [],
    this.query = '',
    this.page = 1,
    this.totalPages = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isApplying = false,
    this.searchError,
    this.createError,
    this.applyError,
  });

  final List<PosCustomer> items;
  final String query;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isCreating;
  final bool isApplying;
  final String? searchError;
  final String? createError;
  final String? applyError;

  bool get hasMore => totalPages > 0 && page < totalPages;

  CheckoutCustomerState copyWith({
    List<PosCustomer>? items,
    String? query,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isApplying,
    String? searchError,
    bool clearSearchError = false,
    String? createError,
    bool clearCreateError = false,
    String? applyError,
    bool clearApplyError = false,
  }) {
    return CheckoutCustomerState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isApplying: isApplying ?? this.isApplying,
      searchError: clearSearchError ? null : searchError ?? this.searchError,
      createError: clearCreateError ? null : createError ?? this.createError,
      applyError: clearApplyError ? null : applyError ?? this.applyError,
    );
  }
}

class CheckoutCustomerNotifier
    extends AutoDisposeNotifier<CheckoutCustomerState> {
  int _requestSequence = 0;

  @override
  CheckoutCustomerState build() => const CheckoutCustomerState();

  Future<void> search(String query) async {
    final normalized = query.trim();
    final requestId = ++_requestSequence;
    state = state.copyWith(
      query: normalized,
      isLoading: true,
      page: 1,
      totalPages: 0,
      clearSearchError: true,
    );
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = state.copyWith(
        isLoading: false,
        items: const [],
        searchError: 'Device context is not available.',
      );
      return;
    }
    try {
      final page =
          await ref.read(posCustomerRemoteDatasourceProvider).listCustomers(
                deviceId: deviceId,
                search: normalized,
                status: 'ACTIVE',
                page: 1,
                pageSize: 20,
              );
      if (requestId != _requestSequence) return;
      state = state.copyWith(
        items: page.items.where((customer) => customer.isActive).toList(),
        page: page.page,
        totalPages: page.totalPages,
        isLoading: false,
        clearSearchError: true,
      );
    } catch (error) {
      if (requestId != _requestSequence) return;
      state = state.copyWith(
        items: const [],
        isLoading: false,
        searchError: _messageFor(error, operation: 'load customers'),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final deviceId = _deviceId;
    if (deviceId == null) return;
    final requestId = _requestSequence;
    state = state.copyWith(isLoadingMore: true, clearSearchError: true);
    try {
      final page =
          await ref.read(posCustomerRemoteDatasourceProvider).listCustomers(
                deviceId: deviceId,
                search: state.query,
                status: 'ACTIVE',
                page: state.page + 1,
                pageSize: 20,
              );
      if (requestId != _requestSequence) return;
      final byId = <String, PosCustomer>{
        for (final customer in state.items) customer.customerId: customer,
        for (final customer in page.items.where((item) => item.isActive))
          customer.customerId: customer,
      };
      state = state.copyWith(
        items: byId.values.toList(growable: false),
        page: page.page,
        totalPages: page.totalPages,
        isLoadingMore: false,
      );
    } catch (error) {
      if (requestId != _requestSequence) return;
      state = state.copyWith(
        isLoadingMore: false,
        searchError: _messageFor(error, operation: 'load more customers'),
      );
    }
  }

  Future<PosCustomer?> create({
    required String fullName,
    required String phone,
    String? email,
  }) async {
    if (state.isCreating || state.isApplying) return null;
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = state.copyWith(createError: 'Device context is not available.');
      return null;
    }
    state = state.copyWith(isCreating: true, clearCreateError: true);
    try {
      final created =
          await ref.read(posCustomerRemoteDatasourceProvider).createCustomer(
                deviceId: deviceId,
                fullName: fullName.trim(),
                phone: phone.trim(),
                email: _emptyToNull(email),
              );
      state = state.copyWith(
        isCreating: false,
        items: [
          created,
          ...state.items.where((item) => item.customerId != created.customerId)
        ],
        clearCreateError: true,
      );
      return created;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        createError: _messageFor(error, operation: 'create customer'),
      );
      return null;
    }
  }

  Future<bool> applyCustomer(PosCustomer? customer) async {
    if (state.isApplying || state.isCreating) return false;
    final cartNotifier = ref.read(posNewSaleCartProvider.notifier);
    final previousCustomerId =
        ref.read(posNewSaleCartProvider).selectedCustomer?.customerId;
    state = state.copyWith(isApplying: true, clearApplyError: true);

    if (customer == null) {
      cartNotifier.setCustomer(null);
      final rebindError = await _rebindDiscountIfCustomerChanged(
        previousCustomerId: previousCustomerId,
        nextCustomerId: null,
      );
      if (rebindError != null) {
        state = state.copyWith(isApplying: false, applyError: rebindError);
        return false;
      }
      ref.invalidate(posCheckoutSummaryProvider);
      state = state.copyWith(isApplying: false, clearApplyError: true);
      return true;
    }

    final deviceId = _deviceId;
    if (deviceId == null) {
      state = state.copyWith(
        isApplying: false,
        applyError: 'Device context is not available.',
      );
      return false;
    }

    try {
      final attachment =
          await ref.read(posCustomerRemoteDatasourceProvider).attachToSale(
                deviceId: deviceId,
                customerId: customer.customerId,
              );
      cartNotifier.setCustomer(attachment.customer);
      final rebindError = await _rebindDiscountIfCustomerChanged(
        previousCustomerId: previousCustomerId,
        nextCustomerId: attachment.customer.customerId,
      );
      if (rebindError != null) {
        state = state.copyWith(isApplying: false, applyError: rebindError);
        return false;
      }
      ref.invalidate(posCheckoutSummaryProvider);
      state = state.copyWith(isApplying: false, clearApplyError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isApplying: false,
        applyError: _messageFor(error, operation: 'update checkout customer'),
      );
      return false;
    }
  }

  Future<String?> _rebindDiscountIfCustomerChanged({
    required String? previousCustomerId,
    required String? nextCustomerId,
  }) async {
    if (previousCustomerId == nextCustomerId) {
      return null;
    }
    return rebindPosDiscountsAfterCustomerChange(
      read: ref.read,
      invalidate: ref.invalidate,
    );
  }

  String? get _deviceId {
    final id =
        ref.read(deviceActivationProvider).deviceContext?.deviceId.trim();
    return id == null || id.isEmpty ? null : id;
  }
}

String? _emptyToNull(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

String _messageFor(Object error, {required String operation}) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    final message = data is Map ? data['message']?.toString() : null;
    if (code == 'pos_customers.duplicate_phone') {
      return 'A customer with this phone number already exists.';
    }
    if (code == 'pos_customers.duplicate_email') {
      return 'A customer with this email address already exists.';
    }
    if (code == 'pos_customers.duplicate_contact') {
      return 'A customer with these contact details already exists.';
    }
    if (status == 401) return 'Your session has expired. Sign in again.';
    if (status == 403) return 'You do not have permission to $operation.';
    if (status == 404 && message != null && message.isNotEmpty) return message;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The request timed out. Check the connection and retry.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Check the connection and retry.';
    }
    if (message != null &&
        message.isNotEmpty &&
        status != null &&
        status < 500) {
      return message;
    }
  }
  return 'Unable to $operation. Try again.';
}
