import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_list_query.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../utils/category_form_utils.dart';

export '../utils/category_form_utils.dart'
    show
        categoryApiErrorMessage,
        categoryArchiveErrorMessage,
        categoryFieldErrorsFromError;

final categoryRemoteDatasourceProvider =
    Provider<CategoryRemoteDatasource>((ref) {
  return CategoryRemoteDatasource(ref.watch(appDioProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryRemoteDatasourceProvider));
});

final categorySearchProvider = StateProvider<String>((ref) => '');

final categoryPageProvider = StateProvider<int>((ref) => 1);

final categoryStatusFilterProvider =
    StateProvider<CategoryStatusFilter>((ref) => CategoryStatusFilter.all);

final categoryParentFilterProvider =
    StateProvider<CategoryParentFilter>((ref) => CategoryParentFilter.all);

final categoryListQueryProvider = Provider<CategoryListQuery>((ref) {
  return CategoryListQuery(
    search: ref.watch(categorySearchProvider),
    pageNumber: ref.watch(categoryPageProvider),
    pageSize: TenantAdminContentTokens.defaultListPageSize,
    statusFilter: ref.watch(categoryStatusFilterProvider),
    parentFilter: ref.watch(categoryParentFilterProvider),
  );
});

final categoryListProvider =
    FutureProvider.autoDispose<CategoryListResult?>((ref) async {
  final query = ref.watch(categoryListQueryProvider);
  return ref.watch(categoryRepositoryProvider).getCategories(query: query);
});

final categoryTreeProvider =
    FutureProvider.autoDispose<List<CategoryTreeNode>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategoryTree();
});

final categoryDetailsProvider = FutureProvider.autoDispose
    .family<Category, String>((ref, categoryId) async {
  return ref.watch(categoryRepositoryProvider).getCategoryById(categoryId);
});

final categorySaveControllerProvider =
    AutoDisposeAsyncNotifierProvider<CategorySaveController, void>(
  CategorySaveController.new,
);

class CategorySaveController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CategorySaveResult> save({
    String? categoryId,
    required CategoryUpsertInput input,
    Uint8List? imageBytes,
    String? imageFileName,
    bool removeExistingImage = false,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(categoryRepositoryProvider);
      final isCreate = categoryId == null || categoryId.isEmpty;
      var savedCategory = isCreate
          ? await repository.createCategory(input)
          : await repository.updateCategory(categoryId, input);

      var imageUploadFailed = false;
      var imageRemoveFailed = false;
      String? imageUploadError;

      if (removeExistingImage && !isCreate) {
        try {
          savedCategory =
              await repository.removeCategoryImage(savedCategory.id);
        } catch (error) {
          imageRemoveFailed = true;
          imageUploadError = categoryApiErrorMessage(error);
        }
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          savedCategory = await repository.uploadCategoryImage(
            savedCategory.id,
            imageBytes,
            imageFileName ?? 'category.jpg',
          );
        } catch (error) {
          imageUploadFailed = true;
          imageUploadError = categoryApiErrorMessage(error);
        }
      }

      state = const AsyncData(null);
      ref.invalidate(categoryListProvider);
      ref.invalidate(categoryTreeProvider);
      _invalidateCategoryDetails(savedCategory.id);

      return CategorySaveResult(
        category: savedCategory,
        imageUploadFailed: imageUploadFailed,
        imageRemoveFailed: imageRemoveFailed,
        imageUploadError: imageUploadError,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<CategorySaveResult> retryImageRemove({
    required String categoryId,
  }) async {
    state = const AsyncLoading();

    try {
      final category =
          await ref.read(categoryRepositoryProvider).removeCategoryImage(
                categoryId,
              );
      state = const AsyncData(null);
      ref.invalidate(categoryListProvider);
      ref.invalidate(categoryTreeProvider);
      _invalidateCategoryDetails(categoryId);
      return CategorySaveResult(category: category);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<CategorySaveResult> retryImageUpload({
    required String categoryId,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    state = const AsyncLoading();

    try {
      final category = await ref.read(categoryRepositoryProvider).uploadCategoryImage(
            categoryId,
            imageBytes,
            imageFileName,
          );
      state = const AsyncData(null);
      ref.invalidate(categoryListProvider);
      ref.invalidate(categoryTreeProvider);
      _invalidateCategoryDetails(categoryId);
      return CategorySaveResult(category: category);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> archive(String categoryId) async {
    state = const AsyncLoading();

    final listResult = ref.read(categoryListProvider).valueOrNull;
    final currentPage = ref.read(categoryPageProvider);
    final shouldMoveToPreviousPage = listResult != null &&
        listResult.items.length == 1 &&
        currentPage > 1;

    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).archiveCategory(categoryId);

      if (shouldMoveToPreviousPage) {
        ref.read(categoryPageProvider.notifier).state = currentPage - 1;
      }

      ref.invalidate(categoryListProvider);
      ref.invalidate(categoryTreeProvider);
      _invalidateCategoryDetails(categoryId);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<Category> toggleStatus(Category category) async {
    final nextStatus = category.isActive ? 'INACTIVE' : 'ACTIVE';
    final input = CategoryUpsertInput(
      categoryCode: category.categoryCode,
      name: category.categoryName,
      status: nextStatus,
      parentCategoryId: category.parentCategoryId,
      description: category.description,
      sortOrder: category.sortOrder,
    );

    state = const AsyncLoading();

    try {
      final updated = await ref
          .read(categoryRepositoryProvider)
          .updateCategory(category.id, input);
      state = const AsyncData(null);
      ref.invalidate(categoryListProvider);
      ref.invalidate(categoryTreeProvider);
      _invalidateCategoryDetails(category.id);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateCategoryDetails(String categoryId) {
    if (categoryId.isEmpty) {
      return;
    }

    ref.invalidate(categoryDetailsProvider(categoryId));
  }
}
