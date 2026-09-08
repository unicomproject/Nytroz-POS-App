import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_error_message.dart';
import '../../../../../core/network/dio_provider.dart';
import '../data/tax_repository.dart';
import '../data/tax_repository_impl.dart';
import '../domain/tax_aggregate.dart';
import '../presentation/providers/tax_list_providers.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepositoryImpl(ref.watch(appDioProvider));
});

/// List provider for Tax Setup page (and temporary Step 6 consumers).
final taxListProvider =
    FutureProvider.autoDispose<TaxSetupListResult>((ref) async {
  final query = ref.watch(taxListQueryProvider);
  return ref.watch(taxRepositoryProvider).listTaxSetups(query);
});

final taxDetailProvider =
    FutureProvider.autoDispose.family<TaxSetup, String>((ref, id) async {
  return ref.watch(taxRepositoryProvider).getTaxSetup(id);
});

final taxProductsProvider = FutureProvider.autoDispose
    .family<TaxProductUsingListResult, String>((ref, taxId) async {
  final query = ref.watch(taxProductsQueryProvider(taxId));
  return ref.watch(taxRepositoryProvider).listProductsUsing(taxId, query);
});

class TaxMutationState {
  const TaxMutationState({this.isSubmitting = false});

  final bool isSubmitting;

  TaxMutationState copyWith({bool? isSubmitting}) {
    return TaxMutationState(isSubmitting: isSubmitting ?? this.isSubmitting);
  }
}

class TaxMutationController extends StateNotifier<TaxMutationState> {
  TaxMutationController(this._repository, this._ref)
      : super(const TaxMutationState());

  final TaxRepository _repository;
  final Ref _ref;

  Future<String> create(TaxSetupCreateInput input) {
    return _guard(() async {
      final id = await _repository.createTaxSetup(input);
      _invalidateLists();
      return id;
    });
  }

  Future<void> update(String id, TaxSetupUpdateInput input) {
    return _guard(() async {
      await _repository.updateTaxSetup(id, input);
      _invalidateDetail(id);
      _invalidateLists();
    });
  }

  Future<void> scheduleRate(String id, TaxRateScheduleInput input) {
    return _guard(() async {
      await _repository.scheduleRate(id, input);
      _invalidateDetail(id);
      _invalidateLists();
    });
  }

  Future<void> updateScheduledRate(
    String id,
    String rateId,
    TaxRateScheduleInput input,
  ) {
    return _guard(() async {
      await _repository.updateScheduledRate(id, rateId, input);
      _invalidateDetail(id);
      _invalidateLists();
    });
  }

  Future<void> deleteScheduledRate(String id, String rateId) {
    return _guard(() async {
      await _repository.deleteScheduledRate(id, rateId);
      _invalidateDetail(id);
      _invalidateLists();
    });
  }

  Future<TaxStatusChangeResult> activate(String id) {
    return _guard(() async {
      final result = await _repository.activateTaxSetup(id);
      _invalidateDetail(id);
      _invalidateLists();
      return result;
    });
  }

  Future<TaxStatusChangeResult> deactivate(String id, {String? reason}) {
    return _guard(() async {
      final result =
          await _repository.deactivateTaxSetup(id, reason: reason);
      _invalidateDetail(id);
      _invalidateLists();
      return result;
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (state.isSubmitting) {
      throw StateError('A tax mutation is already in progress.');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      return await action();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  void _invalidateLists() {
    _ref.invalidate(taxListProvider);
  }

  void _invalidateDetail(String id) {
    _ref.invalidate(taxDetailProvider(id));
    _ref.invalidate(taxProductsProvider(id));
  }
}

final taxMutationControllerProvider =
    StateNotifierProvider<TaxMutationController, TaxMutationState>((ref) {
  return TaxMutationController(ref.watch(taxRepositoryProvider), ref);
});

String taxApiErrorMessage(
  Object error, {
  String fallback = 'Unable to complete tax request.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
      final code = data['code']?.toString();
      if (code != null && code.trim().isNotEmpty) {
        return code.trim();
      }
    }
    return messageFromDioException(error, fallback: fallback);
  }
  return error.toString().trim().isEmpty ? fallback : error.toString();
}

/// Back-compat aliases for older imports.
typedef TaxManagementState = TaxMutationState;
typedef TaxManagementController = TaxMutationController;

final taxManagementControllerProvider = taxMutationControllerProvider;
