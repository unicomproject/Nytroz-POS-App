import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_online_orders_remote_datasource.dart';
import '../../data/repositories/pos_online_orders_repository_impl.dart';
import '../../domain/entities/pos_online_order.dart';
import '../../domain/repositories/pos_online_orders_repository.dart';

final posOnlineOrdersRemoteDatasourceProvider =
    Provider<PosOnlineOrdersRemoteDatasource>(
  (ref) => PosOnlineOrdersRemoteDatasource(ref.watch(appDioProvider)),
);

final posOnlineOrdersRepositoryProvider = Provider<PosOnlineOrdersRepository>(
  (ref) => PosOnlineOrdersRepositoryImpl(
    ref.watch(posOnlineOrdersRemoteDatasourceProvider),
  ),
);

class PosOnlineOrdersState {
  const PosOnlineOrdersState({
    this.items = const [],
    this.summary = const PosOnlineOrderSummary(
      total: 0,
      pending: 0,
      preparing: 0,
      ready: 0,
      overdue: 0,
      newOrders: 0,
      collected: 0,
      cancelled: 0,
    ),
    this.query = '',
    this.status,
    this.sort = PosOnlineOrderSort.collectionAsc,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 0,
    this.serverTime,
    this.selected,
    this.isLoading = false,
    this.isLoadingDetail = false,
    this.isStartingFulfillment = false,
    this.errorMessage,
    this.detailErrorMessage,
  });

  final List<PosOnlineOrder> items;
  final PosOnlineOrderSummary summary;
  final String query;
  final String? status;
  final PosOnlineOrderSort sort;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final DateTime? serverTime;
  final PosOnlineOrderDetail? selected;
  final bool isLoading;
  final bool isLoadingDetail;
  final bool isStartingFulfillment;
  final String? errorMessage;
  final String? detailErrorMessage;

  PosOnlineOrdersState copyWith({
    List<PosOnlineOrder>? items,
    PosOnlineOrderSummary? summary,
    String? query,
    String? status,
    PosOnlineOrderSort? sort,
    bool clearStatus = false,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    DateTime? serverTime,
    PosOnlineOrderDetail? selected,
    bool clearSelected = false,
    bool? isLoading,
    bool? isLoadingDetail,
    bool? isStartingFulfillment,
    String? errorMessage,
    bool clearError = false,
    String? detailErrorMessage,
    bool clearDetailError = false,
  }) =>
      PosOnlineOrdersState(
        items: items ?? this.items,
        summary: summary ?? this.summary,
        query: query ?? this.query,
        status: clearStatus ? null : status ?? this.status,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        totalCount: totalCount ?? this.totalCount,
        totalPages: totalPages ?? this.totalPages,
        serverTime: serverTime ?? this.serverTime,
        selected: clearSelected ? null : selected ?? this.selected,
        isLoading: isLoading ?? this.isLoading,
        isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
        isStartingFulfillment:
            isStartingFulfillment ?? this.isStartingFulfillment,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        detailErrorMessage: clearDetailError
            ? null
            : detailErrorMessage ?? this.detailErrorMessage,
      );
}

final posOnlineOrdersProvider =
    NotifierProvider<PosOnlineOrdersController, PosOnlineOrdersState>(
  PosOnlineOrdersController.new,
);

class PosOnlineOrdersController extends Notifier<PosOnlineOrdersState> {
  CancelToken? _listToken;
  CancelToken? _detailToken;
  Timer? _searchDebounce;

  @override
  PosOnlineOrdersState build() {
    ref.onDispose(() {
      _listToken?.cancel();
      _detailToken?.cancel();
      _searchDebounce?.cancel();
    });
    return const PosOnlineOrdersState();
  }

  Future<void> load({bool resetPage = false}) async {
    final outletId =
        ref.read(deviceActivationProvider).deviceContext?.outletId.trim();
    if (outletId == null || outletId.isEmpty) {
      state = state.copyWith(errorMessage: 'Assigned outlet is unavailable.');
      return;
    }
    _listToken?.cancel('superseded');
    _listToken = CancelToken();
    final requestedPage = resetPage ? 1 : state.page;
    state =
        state.copyWith(isLoading: true, page: requestedPage, clearError: true);
    try {
      final result = await ref.read(posOnlineOrdersRepositoryProvider).list(
            PosOnlineOrdersQuery(
              outletId: outletId,
              search: state.query,
              status: state.status,
              sort: state.sort,
              page: requestedPage,
              pageSize: state.pageSize,
            ),
            cancelToken: _listToken,
          );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        summary: result.summary,
        page: result.page,
        pageSize: result.pageSize,
        totalCount: result.totalCount,
        totalPages: result.totalPages,
        serverTime: result.serverTime,
        clearError: true,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load online orders. Try again.',
      );
    }
  }

  Future<void> select(String orderId) async {
    final outletId =
        ref.read(deviceActivationProvider).deviceContext?.outletId.trim();
    if (outletId == null || outletId.isEmpty) return;
    _detailToken?.cancel('superseded');
    _detailToken = CancelToken();
    state = state.copyWith(isLoadingDetail: true, clearDetailError: true);
    try {
      final detail = await ref.read(posOnlineOrdersRepositoryProvider).get(
            outletId: outletId,
            orderId: orderId,
            cancelToken: _detailToken,
          );
      state = state.copyWith(isLoadingDetail: false, selected: detail);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      state = state.copyWith(
        isLoadingDetail: false,
        detailErrorMessage: _message(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingDetail: false,
        detailErrorMessage: 'Unable to load order details.',
      );
    }
  }

  Future<PosStartFulfillmentResult?> startFulfillment(String orderId) async {
    final outletId =
        ref.read(deviceActivationProvider).deviceContext?.outletId.trim();
    if (outletId == null || outletId.isEmpty) return null;
    state = state.copyWith(
      isStartingFulfillment: true,
      clearDetailError: true,
    );
    try {
      final result = await ref
          .read(posOnlineOrdersRepositoryProvider)
          .startFulfillment(outletId: outletId, orderId: orderId);
      state = state.copyWith(isStartingFulfillment: false);
      await select(orderId);
      await load();
      return result;
    } on DioException catch (error) {
      state = state.copyWith(
        isStartingFulfillment: false,
        detailErrorMessage: _message(error),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isStartingFulfillment: false,
        detailErrorMessage: 'Unable to start fulfilment. Try again.',
      );
      return null;
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value.trim(), page: 1);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => load(resetPage: true),
    );
  }

  void setStatus(String? value) {
    state = state.copyWith(status: value, clearStatus: value == null, page: 1);
    load(resetPage: true);
  }

  void setSort(PosOnlineOrderSort value) {
    state = state.copyWith(sort: value, page: 1);
    load(resetPage: true);
  }

  void goToPage(int value) {
    if (value < 1 || value > state.totalPages || value == state.page) return;
    state = state.copyWith(page: value);
    load();
  }

  String _message(DioException error) {
    return onlineOrderErrorMessage(error);
  }
}

String onlineOrderErrorMessage(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code']?.toString() : null;
  return switch (code) {
    'online_orders.permission_denied' =>
      'You do not have permission to perform this online-order action.',
    'online_orders.feature_not_entitled' =>
      'Click and collect is not enabled for this tenant.',
    'online_orders.outlet_access_denied' =>
      'You do not have access to this outlet. Contact an administrator if access is required.',
    'online_orders.not_found' ||
    'online_orders.picking_not_found' =>
      'This online order is no longer available. Refresh the queue.',
    'online_orders.fulfilment_conflict' =>
      'This order changed or is being handled by another cashier. Refresh and try again.',
    'online_orders.invalid_pagination' ||
    'online_orders.invalid_order_id' ||
    'online_orders.invalid_outlet' =>
      'The online-order request is invalid. Refresh and try again.',
    _ when error.response?.statusCode == 401 =>
      'Your session has expired. Sign in again.',
    _ when error.response?.statusCode == 403 =>
      'You do not have permission to access online orders.',
    _ when error.response?.statusCode == 404 =>
      'This online order is no longer available. Refresh the queue.',
    _ when error.response?.statusCode == 409 =>
      'This order changed. Refresh before continuing.',
    _ => 'Unable to complete the online-order request. Try again.',
  };
}

final posPickingOrderProvider = FutureProvider.autoDispose
    .family<PosPickingOrder, String>((ref, orderId) async {
  final outletId =
      ref.watch(deviceActivationProvider).deviceContext?.outletId.trim();
  if (outletId == null || outletId.isEmpty) {
    throw StateError('Assigned outlet is unavailable.');
  }
  return ref.watch(posOnlineOrdersRepositoryProvider).getPicking(
        outletId: outletId,
        orderId: orderId,
      );
});

final posPickingActionsProvider = Provider.autoDispose
    .family<PosPickingActions, String>(
        (ref, orderId) => PosPickingActions(ref, orderId));

class PosPickingActions {
  PosPickingActions(this.ref, this.orderId);
  final Ref ref;
  final String orderId;

  String get _outletId =>
      ref.read(deviceActivationProvider).deviceContext?.outletId.trim() ?? '';

  Future<PosFulfillmentCommandResult> pick(
    PosPickingLine line, {
    required bool scanned,
    required String barcode,
  }) async {
    final result = await ref.read(posOnlineOrdersRepositoryProvider).pickLine(
          outletId: _outletId,
          orderId: orderId,
          lineId: line.id,
          quantity: line.requestedQuantity - line.pickedQuantity,
          barcode: barcode.trim(),
          scanned: scanned,
        );
    ref.invalidate(posPickingOrderProvider(orderId));
    return result;
  }

  Future<void> issue(PosPickingLine line, String reason, String? note) async {
    await ref.read(posOnlineOrdersRepositoryProvider).reportIssue(
          outletId: _outletId,
          orderId: orderId,
          lineId: line.id,
          reason: reason,
          note: note,
        );
    ref.invalidate(posPickingOrderProvider(orderId));
  }

  Future<PosFulfillmentCommandResult> pack(String? note) async {
    final result = await ref
        .read(posOnlineOrdersRepositoryProvider)
        .pack(outletId: _outletId, orderId: orderId, packingNote: note);
    ref.invalidate(posPickingOrderProvider(orderId));
    return result;
  }

  Future<PosFulfillmentCommandResult> ready() async {
    final result = await ref
        .read(posOnlineOrdersRepositoryProvider)
        .markReady(outletId: _outletId, orderId: orderId);
    ref.invalidate(posPickingOrderProvider(orderId));
    ref.invalidate(posOnlineOrdersProvider);
    return result;
  }
}
