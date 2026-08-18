import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import '../data/tax_repository.dart';
import '../data/tax_repository_impl.dart';
import '../domain/tax_aggregate.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  final apiClient = ref.watch(appDioProvider);
  return TaxRepositoryImpl(apiClient);
});

final taxListProvider =
    FutureProvider.autoDispose<TaxAggregateListResult>((ref) {
  final repository = ref.watch(taxRepositoryProvider);
  return repository.getTaxes();
});

class TaxManagementState {
  const TaxManagementState({
    this.editingTaxId,
    this.isSubmitting = false,
  });

  final String? editingTaxId;
  final bool isSubmitting;

  bool get isEditing => editingTaxId != null;

  TaxManagementState copyWith({
    String? editingTaxId,
    bool? isSubmitting,
  }) {
    return TaxManagementState(
      editingTaxId: editingTaxId ?? this.editingTaxId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  TaxManagementState clearEdit() {
    return TaxManagementState(
      editingTaxId: null,
      isSubmitting: isSubmitting,
    );
  }
}

class TaxManagementController extends StateNotifier<TaxManagementState> {
  TaxManagementController(this._repository, this._ref)
      : super(const TaxManagementState());

  final TaxRepository _repository;
  final Ref _ref;

  void startEditing(String id) {
    state = state.copyWith(editingTaxId: id);
  }

  void cancelEditing() {
    state = state.clearEdit();
  }

  Future<void> submitTax(TaxAggregateUpsertInput input) async {
    state = state.copyWith(isSubmitting: true);
    try {
      if (state.isEditing) {
        await _repository.updateTax(state.editingTaxId!, input);
      } else {
        await _repository.createTax(input);
      }
      state = state.clearEdit();
      // Refresh the list after successful submit
      _ref.invalidate(taxListProvider);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> deleteTax(String id) async {
    try {
      await _repository.deleteTax(id);
      _ref.invalidate(taxListProvider);
    } catch (e) {
      // Re-throw to be handled by the UI
      rethrow;
    }
  }
}

final taxManagementControllerProvider =
    StateNotifierProvider<TaxManagementController, TaxManagementState>((ref) {
  final repository = ref.watch(taxRepositoryProvider);
  return TaxManagementController(repository, ref);
});
