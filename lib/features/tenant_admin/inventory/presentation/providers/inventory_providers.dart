import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../utils/inventory_api_errors.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';

final inventoryRemoteDatasourceProvider = Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasource(ref.watch(appDioProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryRemoteDatasourceProvider));
});

final accessibleOutletOptionsProvider =
    Provider<List<AccessibleOutletOption>>((ref) {
  final context = ref.watch(tenantAdminContextProvider).asData?.value;
  if (context == null) {
    return const [];
  }

  return context.outletScope
      .map(
        (outlet) => AccessibleOutletOption(
          id: outlet.outletId,
          name: outlet.outletName,
          isDefault: outlet.isDefault,
        ),
      )
      .toList();
});

final currentStockSearchProvider = StateProvider<String>((ref) => '');

final currentStockOutletFilterProvider = StateProvider<String?>((ref) => null);

final currentStockStatusFilterProvider =
    StateProvider<String?>((ref) => null);

final currentStockExpiryFilterProvider =
    StateProvider<String?>((ref) => null);

final currentStockBatchFilterProvider = StateProvider<String>((ref) => '');

final currentStockPageProvider = StateProvider<int>((ref) => 1);

final currentStockPageSizeProvider = StateProvider<int>((ref) => 50);

final currentStockSortByProvider = StateProvider<String?>((ref) => null);

final currentStockSortDirectionProvider =
    StateProvider<String?>((ref) => null);

final currentStockQueryProvider = Provider<CurrentStockQuery>((ref) {
  final search = ref.watch(currentStockSearchProvider);
  final outletId = ref.watch(currentStockOutletFilterProvider);
  final stockStatus = ref.watch(currentStockStatusFilterProvider);
  final expiryStatus = ref.watch(currentStockExpiryFilterProvider);
  final batchNumber = ref.watch(currentStockBatchFilterProvider);
  final page = ref.watch(currentStockPageProvider);
  final pageSize = ref.watch(currentStockPageSizeProvider);
  final sortBy = ref.watch(currentStockSortByProvider);
  final sortDirection = ref.watch(currentStockSortDirectionProvider);

  return CurrentStockQuery(
    outletId: outletId,
    search: search.trim().isEmpty ? null : search.trim(),
    stockStatus: stockStatus,
    batchNumber: batchNumber.trim().isEmpty ? null : batchNumber.trim(),
    expiryStatus: expiryStatus,
    page: page,
    pageSize: pageSize,
    sortBy: sortBy,
    sortDirection: sortDirection,
  );
});

final currentStockListProvider =
    FutureProvider.autoDispose<CurrentStockPage?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canViewCurrentStock()) {
    return null;
  }

  final query = ref.watch(currentStockQueryProvider);
  return ref.watch(inventoryRepositoryProvider).getCurrentStock(query);
});

final currentStockSummaryProvider =
    FutureProvider.autoDispose<CurrentStockSummary?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canViewCurrentStock()) {
    return null;
  }

  final outletId = ref.watch(currentStockOutletFilterProvider);
  return ref.watch(inventoryRepositoryProvider).getCurrentStockSummary(
        outletId: outletId,
      );
});

final variantLookupProvider =
    FutureProvider.autoDispose.family<VariantLookup?, String>((ref, productId) async {
  if (productId.isEmpty) {
    return null;
  }

  return ref.watch(inventoryRepositoryProvider).getProductVariants(productId);
});

final stockInFormProvider =
    StateNotifierProvider.autoDispose<StockInFormNotifier, StockInFormInput>(
  StockInFormNotifier.new,
);

class StockInFormNotifier extends StateNotifier<StockInFormInput> {
  StockInFormNotifier(this.ref)
      : super(StockInFormInput(receivedAt: DateTime.now())) {
    _autoSelectOutlet();
  }

  final Ref ref;
  final Map<String, String> fieldErrors = {};

  void _autoSelectOutlet() {
    final outlets = ref.read(accessibleOutletOptionsProvider);
    if (outlets.length == 1) {
      state = state.copyWith(outletId: outlets.first.id);
    }
  }

  void setOutletId(String? outletId) {
    fieldErrors.remove('outletId');
    state = state.copyWith(outletId: outletId);
  }

  void setReferenceNumber(String value) {
    fieldErrors.remove('referenceNumber');
    state = state.copyWith(referenceNumber: value);
  }

  void setReceivedAt(DateTime? value) {
    fieldErrors.remove('receivedAt');
    state = state.copyWith(receivedAt: value);
  }

  void setNotes(String value) {
    fieldErrors.remove('notes');
    state = state.copyWith(notes: value);
  }

  void updateLine(int index, StockInLineInput line) {
    final items = [...state.items];
    if (index < 0 || index >= items.length) {
      return;
    }

    items[index] = line;
    state = state.copyWith(items: items);
  }

  void addLine() {
    if (state.items.length >= 100) {
      return;
    }

    state = state.copyWith(items: [...state.items, const StockInLineInput()]);
  }

  void removeLine(int index) {
    if (state.items.length <= 1) {
      return;
    }

    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  void applyBackendErrors(Map<String, String> errors) {
    fieldErrors
      ..clear()
      ..addAll(errors);
  }

  Map<String, String> validateLocally() {
    final errors = <String, String>{};

    if (state.outletId == null || state.outletId!.isEmpty) {
      errors['outletId'] = 'Outlet is required.';
    }

    final validLines = state.items.where(
      (line) =>
          line.productVariantId != null &&
          line.productVariantId!.isNotEmpty &&
          (line.quantity ?? 0) > 0,
    );

    if (validLines.isEmpty) {
      errors['items'] = 'At least one stock-in line is required.';
    }

    for (var index = 0; index < state.items.length; index++) {
      final line = state.items[index];
      final prefix = 'items[$index]';
      final hasContent = line.productId != null ||
          line.productVariantId != null ||
          (line.quantity ?? 0) > 0;

      if (!hasContent) {
        continue;
      }

      if (line.productVariantId == null || line.productVariantId!.isEmpty) {
        errors['$prefix.productVariantId'] = 'Product variant is required.';
      }

      if ((line.quantity ?? 0) <= 0) {
        errors['$prefix.quantity'] = 'Quantity must be greater than zero.';
      }

      if ((line.unitCost ?? 0) < 0) {
        errors['$prefix.unitCost'] = 'Unit cost cannot be negative.';
      }

      if (line.isBatchTracked &&
          (line.batchNumber == null || line.batchNumber!.trim().isEmpty)) {
        errors['$prefix.batchNumber'] = 'Batch number is required.';
      }

      if (line.isExpiryTracked && line.expiryDate == null) {
        errors['$prefix.expiryDate'] = 'Expiry date is required.';
      }

      if (line.manufacturedDate != null &&
          line.expiryDate != null &&
          line.expiryDate!.isBefore(line.manufacturedDate!)) {
        errors['$prefix.expiryDate'] =
            'Expiry date cannot be earlier than manufactured date.';
      }
    }

    final seen = <String>{};
    for (var index = 0; index < state.items.length; index++) {
      final line = state.items[index];
      if (line.productVariantId == null || line.productVariantId!.isEmpty) {
        continue;
      }

      final batchKey = (line.batchNumber ?? '').trim().toUpperCase();
      final key = '${line.productVariantId}|$batchKey';
      if (!seen.add(key)) {
        errors['items[$index].productVariantId'] =
            'Duplicate variant and batch combination is not allowed.';
      }
    }

    fieldErrors
      ..clear()
      ..addAll(errors);
    return errors;
  }
}

final stockInSubmitControllerProvider =
    AutoDisposeAsyncNotifierProvider<StockInSubmitController, void>(
  StockInSubmitController.new,
);

class StockInSubmitController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<StockInResult> submit() async {
    final formNotifier = ref.read(stockInFormProvider.notifier);
    final errors = formNotifier.validateLocally();
    if (errors.isNotEmpty) {
      throw StateError('Validation failed');
    }

    state = const AsyncLoading();
    StockInResult? result;

    state = await AsyncValue.guard(() async {
      final input = ref.read(stockInFormProvider);
      final idempotencyKey = DateTime.now().microsecondsSinceEpoch.toString();
      result = await ref.read(inventoryRepositoryProvider).receiveStock(
            input,
            idempotencyKey: idempotencyKey,
          );

      ref.invalidate(currentStockListProvider);
      ref.invalidate(currentStockSummaryProvider);
    });

    if (state.hasError) {
      final error = state.error!;
      if (error is DioException) {
        formNotifier.applyBackendErrors(inventoryValidationErrors(error));
      }
      throw error;
    }

    return result!;
  }
}

void clearCurrentStockFilters(WidgetRef ref) {
  ref.read(currentStockSearchProvider.notifier).state = '';
  ref.read(currentStockOutletFilterProvider.notifier).state = null;
  ref.read(currentStockStatusFilterProvider.notifier).state = null;
  ref.read(currentStockExpiryFilterProvider.notifier).state = null;
  ref.read(currentStockBatchFilterProvider.notifier).state = '';
  ref.read(currentStockPageProvider.notifier).state = 1;
}

void applyCurrentStockRouteFilters(
  WidgetRef ref, {
  String? stockStatus,
  String? expiryStatus,
}) {
  if (stockStatus != null && stockStatus.isNotEmpty) {
    ref.read(currentStockStatusFilterProvider.notifier).state = stockStatus;
  }

  if (expiryStatus != null && expiryStatus.isNotEmpty) {
    ref.read(currentStockExpiryFilterProvider.notifier).state = expiryStatus;
  }
}
