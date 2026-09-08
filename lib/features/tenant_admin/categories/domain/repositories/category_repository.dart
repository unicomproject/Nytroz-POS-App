import 'dart:typed_data';

import '../entities/category.dart';
import '../entities/category_list_query.dart';
import '../entities/category_tree_node.dart';

abstract class CategoryRepository {
  Future<CategoryListResult> getCategories({required CategoryListQuery query});

  Future<List<CategoryTreeNode>> getCategoryTree();

  Future<Category> getCategoryById(String id);

  Future<Category> createCategory(CategoryUpsertInput input);

  Future<Category> updateCategory(String id, CategoryUpsertInput input);

  Future<void> archiveCategory(String id);

  Future<Category> uploadCategoryImage(
    String id,
    Uint8List bytes,
    String fileName,
  );

  Future<Category> removeCategoryImage(String id);
}
