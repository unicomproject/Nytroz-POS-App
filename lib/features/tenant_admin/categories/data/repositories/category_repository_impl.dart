import 'dart:typed_data';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_list_query.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._remoteDatasource);

  final CategoryRemoteDatasource _remoteDatasource;

  @override
  Future<CategoryListResult> getCategories({
    required CategoryListQuery query,
  }) async {
    final dto = await _remoteDatasource.getCategories(query);
    return CategoryMapper.toListResult(dto);
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async {
    final dto = await _remoteDatasource.getCategoryTree();
    return dto.items.map(CategoryMapper.toTreeNode).toList(growable: false);
  }

  @override
  Future<Category> getCategoryById(String id) async {
    final dto = await _remoteDatasource.getCategoryById(id);
    return CategoryMapper.toEntity(dto);
  }

  @override
  Future<Category> createCategory(CategoryUpsertInput input) async {
    final dto = await _remoteDatasource.createCategory(
      CategoryMapper.toRequestDto(input),
    );
    return CategoryMapper.toEntity(dto);
  }

  @override
  Future<Category> updateCategory(String id, CategoryUpsertInput input) async {
    final dto = await _remoteDatasource.updateCategory(
      id,
      CategoryMapper.toRequestDto(input),
    );
    return CategoryMapper.toEntity(dto);
  }

  @override
  Future<void> archiveCategory(String id) async {
    await _remoteDatasource.deleteCategory(id);
  }

  @override
  Future<Category> uploadCategoryImage(
    String id,
    Uint8List bytes,
    String fileName,
  ) async {
    await _remoteDatasource.uploadCategoryImage(id, bytes, fileName);
    return getCategoryById(id);
  }

  @override
  Future<Category> removeCategoryImage(String id) async {
    await _remoteDatasource.removeCategoryImage(id);
    return getCategoryById(id);
  }
}
