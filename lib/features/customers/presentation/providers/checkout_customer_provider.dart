import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../discount/presentation/providers/pos_discount_provider.dart';
import '../../../sale/domain/entities/pos_customer.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'customers_provider.dart';

enum CheckoutCustomerStage {
  phoneEntry,
  searching,
  customerFound,
  customerNotFound,
  addCustomer,
  createReady,
  creating,
  searchError,
  createError,
  checkoutRevalidationError,
  permissionDenied
}

final checkoutCustomerProvider = NotifierProvider.autoDispose<
    CheckoutCustomerNotifier,
    CheckoutCustomerState>(CheckoutCustomerNotifier.new);

class CheckoutCustomerState {
  const CheckoutCustomerState(
      {this.stage = CheckoutCustomerStage.phoneEntry,
      this.dialCode = '',
      this.localPhone = '',
      this.customerName = '',
      this.foundCustomer,
      this.error});
  final CheckoutCustomerStage stage;
  final String dialCode;
  final String localPhone;
  final String customerName;
  final PosCustomer? foundCustomer;
  final String? error;
  String get phone => '$dialCode$localPhone';
  String get normalizedPhone => normalizeCheckoutPhone(phone);
  bool get isPhoneValid => normalizedPhone.replaceAll('+', '').length >= 7;
  bool get isNameValid =>
      customerName.trim().isNotEmpty && customerName.trim().length <= 150;
  bool get isBusy =>
      stage == CheckoutCustomerStage.searching ||
      stage == CheckoutCustomerStage.creating;
  List<PosCustomer> get items =>
      foundCustomer == null ? const [] : [foundCustomer!];
  String? get createError =>
      stage == CheckoutCustomerStage.createError ? error : null;
  CheckoutCustomerState copyWith(
          {CheckoutCustomerStage? stage,
          String? dialCode,
          String? localPhone,
          String? customerName,
          PosCustomer? foundCustomer,
          bool clearFoundCustomer = false,
          String? error,
          bool clearError = false}) =>
      CheckoutCustomerState(
          stage: stage ?? this.stage,
          dialCode: dialCode ?? this.dialCode,
          localPhone: localPhone ?? this.localPhone,
          customerName: customerName ?? this.customerName,
          foundCustomer:
              clearFoundCustomer ? null : foundCustomer ?? this.foundCustomer,
          error: clearError ? null : error ?? this.error);
}

class CheckoutCustomerNotifier
    extends AutoDisposeNotifier<CheckoutCustomerState> {
  int _searchSequence = 0;
  bool _commitInProgress = false;
  @override
  CheckoutCustomerState build() => const CheckoutCustomerState(dialCode: '+94');

  void setDialCode(String value) {
    if (state.isBusy) return;
    state = state.copyWith(
        dialCode: value.trim(),
        stage: CheckoutCustomerStage.phoneEntry,
        clearError: true,
        clearFoundCustomer: true);
  }

  Future<void> enterDigit(String digit) async {
    if (state.isBusy || digit.length != 1 || int.tryParse(digit) == null) {
      return;
    }
    state = state.copyWith(
        localPhone: '${state.localPhone}$digit',
        stage: CheckoutCustomerStage.phoneEntry,
        clearError: true,
        clearFoundCustomer: true);
    if (state.isPhoneValid) await search();
  }

  void backspace() {
    if (state.isBusy || state.localPhone.isEmpty) return;
    _searchSequence++;
    state = state.copyWith(
        localPhone: state.localPhone.substring(0, state.localPhone.length - 1),
        stage: CheckoutCustomerStage.phoneEntry,
        clearError: true,
        clearFoundCustomer: true);
  }

  void clearPhone() {
    if (state.isBusy) return;
    _searchSequence++;
    state = state.copyWith(
        localPhone: '',
        customerName: '',
        stage: CheckoutCustomerStage.phoneEntry,
        clearError: true,
        clearFoundCustomer: true);
  }

  Future<void> search() async {
    if (!state.isPhoneValid || state.isBusy) return;
    final requestId = ++_searchSequence;
    final requestedPhone = state.normalizedPhone;
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.searchError,
          error: 'Device context is not available.');
      return;
    }
    state = state.copyWith(
        stage: CheckoutCustomerStage.searching,
        clearError: true,
        clearFoundCustomer: true);
    try {
      final page = await ref
          .read(posCustomerRemoteDatasourceProvider)
          .listCustomers(
              deviceId: deviceId,
              search: requestedPhone,
              status: 'ACTIVE',
              page: 1,
              pageSize: 20);
      if (requestId != _searchSequence ||
          requestedPhone != state.normalizedPhone) {
        return;
      }
      final exact = page.items
          .where((item) =>
              item.isActive &&
              normalizeCheckoutPhone(item.phone ?? '') == requestedPhone)
          .toList();
      state = state.copyWith(
          stage: exact.length == 1
              ? CheckoutCustomerStage.customerFound
              : CheckoutCustomerStage.customerNotFound,
          foundCustomer: exact.length == 1 ? exact.single : null,
          clearFoundCustomer: exact.length != 1,
          clearError: true);
    } catch (error) {
      if (requestId != _searchSequence) return;
      state = state.copyWith(
          stage: CheckoutCustomerStage.searchError,
          error: _messageFor(error, 'search for customer'));
    }
  }

  void beginCreate() {
    if (state.stage == CheckoutCustomerStage.customerNotFound) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.addCustomer, clearError: true);
    }
  }

  void changeNumber() {
    if (!state.isBusy) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.phoneEntry,
          customerName: '',
          clearError: true,
          clearFoundCustomer: true);
    }
  }

  void setCustomerName(String value) {
    if (state.isBusy) return;
    final limited = value.length > 150 ? value.substring(0, 150) : value;
    state = state.copyWith(
        customerName: limited,
        stage: limited.trim().isEmpty
            ? CheckoutCustomerStage.addCustomer
            : CheckoutCustomerStage.createReady,
        clearError: true);
  }

  Future<bool> confirmFound() async {
    final customer = state.foundCustomer;
    if (state.stage != CheckoutCustomerStage.customerFound ||
        customer == null) {
      return false;
    }
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canAttachCustomerToSale(granted)) {
      state = state.copyWith(
        stage: CheckoutCustomerStage.permissionDenied,
        error: 'You do not have permission to attach a customer to a sale.',
      );
      return false;
    }
    if (_commitInProgress) return false;
    _commitInProgress = true;
    try {
      return await _applyAndRevalidate(customer);
    } finally {
      _commitInProgress = false;
    }
  }

  @Deprecated('Use confirmFound after the explicit found-customer state.')
  Future<bool> applyCustomer(PosCustomer? customer) async {
    if (customer == null) return false;
    return _applyAndRevalidate(customer);
  }

  @Deprecated('Use setCustomerName then createAndContinue.')
  Future<PosCustomer?> create(
      {required String fullName, required String phone, String? email}) async {
    if (state.isBusy) return null;
    final deviceId = _deviceId;
    if (deviceId == null) return null;
    state = state.copyWith(
        stage: CheckoutCustomerStage.creating,
        customerName: fullName.trim(),
        clearError: true);
    try {
      final created = await ref
          .read(posCustomerRemoteDatasourceProvider)
          .createCustomer(
              deviceId: deviceId,
              fullName: fullName.trim(),
              phone: phone.trim());
      state = state.copyWith(
          stage: CheckoutCustomerStage.customerFound,
          foundCustomer: created,
          clearError: true);
      return created;
    } catch (error) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.createError,
          error: _messageFor(error, 'create customer'));
      return null;
    }
  }

  Future<bool> createAndContinue() async {
    if (state.stage != CheckoutCustomerStage.createReady ||
        !state.isNameValid) {
      return false;
    }
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canCreateCustomer(granted)) {
      state = state.copyWith(
        stage: CheckoutCustomerStage.permissionDenied,
        error: 'You do not have permission to create a customer.',
      );
      return false;
    }
    if (!PosPermissionAccess.canAttachCustomerToSale(granted)) {
      state = state.copyWith(
        stage: CheckoutCustomerStage.permissionDenied,
        error: 'You do not have permission to attach a customer to a sale.',
      );
      return false;
    }
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.createError,
          error: 'Device context is not available.');
      return false;
    }
    state =
        state.copyWith(stage: CheckoutCustomerStage.creating, clearError: true);
    try {
      final created = await ref
          .read(posCustomerRemoteDatasourceProvider)
          .createCustomer(
              deviceId: deviceId,
              fullName: state.customerName.trim(),
              phone: state.phone);
      return _applyAndRevalidate(created);
    } catch (error) {
      state = state.copyWith(
          stage: CheckoutCustomerStage.createError,
          error: _messageFor(error, 'create customer'));
      return false;
    }
  }

  Future<bool> skip() async {
    if (_commitInProgress) return false;
    _commitInProgress = true;
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    final previous = ref.read(posNewSaleCartProvider).selectedCustomer;
    try {
      if (previous != null) notifier.setCustomer(null);
      final discountError = await rebindPosDiscountsAfterCustomerChange(
          read: ref.read, invalidate: ref.invalidate);
      if (discountError != null) {
        if (previous != null) notifier.setCustomer(previous);
        state = state.copyWith(
            stage: CheckoutCustomerStage.checkoutRevalidationError,
            error: discountError);
        return false;
      }
      ref.invalidate(posCheckoutSummaryProvider);
      await ref.read(posCheckoutSummaryProvider.future);
      return true;
    } catch (_) {
      if (previous != null) notifier.setCustomer(previous);
      ref.invalidate(posCheckoutSummaryProvider);
      state = state.copyWith(
          stage: CheckoutCustomerStage.checkoutRevalidationError,
          error:
              'Checkout could not be revalidated. Your cart was preserved. Retry when the connection is available.');
      return false;
    } finally {
      _commitInProgress = false;
    }
  }

  Future<bool> _applyAndRevalidate(PosCustomer customer) async {
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    final previous = ref.read(posNewSaleCartProvider).selectedCustomer;
    notifier.setCustomer(customer);
    final discountError = await rebindPosDiscountsAfterCustomerChange(
        read: ref.read, invalidate: ref.invalidate);
    if (discountError != null) {
      notifier.setCustomer(previous);
      state = state.copyWith(
          stage: CheckoutCustomerStage.checkoutRevalidationError,
          error: discountError);
      return false;
    }
    try {
      ref.invalidate(posCheckoutSummaryProvider);
      await ref.read(posCheckoutSummaryProvider.future);
      return true;
    } catch (_) {
      notifier.setCustomer(previous);
      ref.invalidate(posCheckoutSummaryProvider);
      state = state.copyWith(
          stage: CheckoutCustomerStage.checkoutRevalidationError,
          error:
              'Checkout could not be revalidated. Your cart was preserved. Retry when the connection is available.');
      return false;
    }
  }

  String? get _deviceId {
    final value =
        ref.read(deviceActivationProvider).deviceContext?.deviceId.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

String normalizeCheckoutPhone(String value) {
  final trimmed = value.trim();
  return '${trimmed.startsWith('+') ? '+' : ''}${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
}

String _messageFor(Object error, String operation) {
  if (error is DioException) {
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    if (code == 'pos_customers.duplicate_phone') {
      return 'A customer with this phone number already exists. Search again to continue.';
    }
    if (error.response?.statusCode == 403) {
      return 'You do not have permission to $operation.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The request timed out. Retry when the connection is available.';
    }
  }
  return 'Unable to $operation. Try again.';
}
