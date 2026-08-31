import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_list_query.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_tree_node.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/repositories/category_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/screens/category_details_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_details_content.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_states.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_route_guard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  group('Category details route access', () {
    test('view permission allows details route', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoryDetail('cat-1'),
        ),
        isTrue,
      );
    });

    test('manage permission allows details route', () {
      final access = _checker(permissions: ['catalog.categories.manage']);

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoryDetail('cat-1'),
        ),
        isTrue,
      );
    });

    test('update permission allows edit route', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesUpdate],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoryEdit('cat-1'),
        ),
        isTrue,
      );
    });

    test('view-only permission blocks edit route', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoryEdit('cat-1'),
        ),
        isFalse,
      );
    });
  });

  group('CategoryDetailsScreen', () {
    testWidgets('shows loading state while fetching', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-1'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) => Completer<Category>().future,
        ),
      );

      await tester.pump();

      expect(find.text('Category Details'), findsOneWidget);
      expect(find.byType(TenantAdminLoadingSkeleton), findsOneWidget);
    });

    testWidgets('shows loaded category fields at 1024x768', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final category = _childCategory(level: 3);

      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-child'),
          access: _checker(
            permissions: [
              TenantAdminPermissionCodes.tenantCategoriesView,
              TenantAdminPermissionCodes.tenantCategoriesUpdate,
              TenantAdminPermissionCodes.tenantCategoriesDelete,
            ],
          ),
          loadCategory: (_) async => category,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Category Details'), findsOneWidget);
      expect(find.textContaining('View category information'), findsOneWidget);
      expect(find.textContaining('Product /'), findsNothing);
      expect(find.text('Water Bottles'), findsWidgets);
      expect(find.text('WATER'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(
        find.text('Groceries > Beverages > Water Bottles'),
        findsOneWidget,
      );
      expect(find.text('Still and sparkling water'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Back to List'), findsOneWidget);
      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.textContaining('Department'), findsNothing);
      expect(find.textContaining('SubCategory'), findsNothing);
      expect(find.bySemanticsLabel('Category Image'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final viewportBottom = tester.getSize(find.byType(MaterialApp)).height;
      for (final label in [
        'Product Usage',
        'Audit Information',
        'Description',
      ]) {
        final rect = tester.getRect(find.text(label).first);
        expect(
          rect.bottom,
          lessThanOrEqualTo(viewportBottom + 1),
          reason: '$label should fit on the 1024x768 details page without scrolling',
        );
      }
    });

    testWidgets('root category shows Root parent and level 1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-root'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) async => _rootCategory(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('Groceries'), findsWidgets);
    });

    testWidgets('level 5 child category hierarchy is displayed', (tester) async {
      final category = Category(
        id: 'cat-l5',
        parentCategoryId: 'cat-l4',
        parentCategoryName: 'L4',
        categoryCode: 'L5',
        categoryName: 'Level Five',
        categorySlug: 'level-five',
        status: 'ACTIVE',
        sortOrder: 0,
        level: 5,
        hierarchyPath: 'L1 > L2 > L3 > L4 > L5',
        childCount: 0,
        productCount: 0,
        hasChildren: false,
      );

      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-l5'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) async => category,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('L4'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(find.text('L1 > L2 > L3 > L4 > L5'), findsOneWidget);
    });

    testWidgets('not-found state shown for category.not_found', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'missing'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) async => throw _dioError(
                statusCode: 404,
                body: {'code': 'category.not_found'},
              ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Category not found'), findsOneWidget);
      expect(find.text('Back to List'), findsOneWidget);
    });

    testWidgets('api error state shown with retry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-1'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) async => throw _dioError(
                statusCode: 500,
                body: {'message': 'Server unavailable'},
              ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load category'), findsOneWidget);
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Back to List'), findsOneWidget);
    });

    testWidgets('edit hidden without update/manage permission', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-child'),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
          ),
          loadCategory: (_) async => _childCategory(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('archive hidden without delete/manage permission', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-child'),
          access: _checker(
            permissions: [
              TenantAdminPermissionCodes.tenantCategoriesView,
              TenantAdminPermissionCodes.tenantCategoriesUpdate,
            ],
          ),
          loadCategory: (_) async => _childCategory(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);
      expect(find.text('Inactivate'), findsOneWidget);
    });

    testWidgets('archive visible with delete permission', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-child'),
          access: _checker(
            permissions: [
              TenantAdminPermissionCodes.tenantCategoriesView,
              TenantAdminPermissionCodes.tenantCategoriesDelete,
            ],
          ),
          loadCategory: (_) async => _childCategory(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('archive conflict shows message and keeps category visible',
        (tester) async {
      final repository = _FakeCategoryRepository(
        details: _childCategory(),
        archiveError: _dioError(
          statusCode: 409,
          body: {
            'code': 'category.delete_conflict',
            'message':
                'Category cannot be deleted while child categories exist.',
          },
        ),
      );

      await tester.pumpWidget(
        _wrap(
          child: const CategoryDetailsScreen(categoryId: 'cat-child'),
          access: _checker(
            permissions: [
              TenantAdminPermissionCodes.tenantCategoriesView,
              TenantAdminPermissionCodes.tenantCategoriesDelete,
            ],
          ),
          loadCategory: (_) async => _childCategory(),
          repository: repository,
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('cannot be archived'),
        findsOneWidget,
      );
      expect(find.text('Water Bottles'), findsWidgets);
    });

    testWidgets('no access when view permission missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => _checker(permissions: const []),
            ),
            categoryDetailPageAccessProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: CategoryDetailsScreen(categoryId: 'cat-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You do not have permission to view categories.'),
        findsOneWidget,
      );
    });
  });

  group('CategoryDetailsContent', () {
    testWidgets('displays audit timestamps', (tester) async {
      final category = Category(
        id: 'cat-child',
        parentCategoryId: 'cat-parent',
        parentCategoryName: 'Groceries',
        categoryCode: 'WATER',
        categoryName: 'Water Bottles',
        categorySlug: 'water-bottles',
        status: 'ACTIVE',
        sortOrder: 2,
        level: 3,
        hierarchyPath: 'Groceries > Beverages > Water Bottles',
        childCount: 4,
        productCount: 12,
        hasChildren: true,
        createdAt: DateTime.parse('2026-01-10T08:00:00Z'),
        updatedAt: DateTime.parse('2026-01-15T10:30:00Z'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryDetailsContent(category: category),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Created At'), findsOneWidget);
      expect(find.text('Updated At'), findsOneWidget);
      expect(find.textContaining('Jan 10, 2026'), findsOneWidget);
      expect(find.textContaining('Jan 15, 2026'), findsOneWidget);
    });

    testWidgets('lists child category names under Footwear', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryDetailsContent(
                category: const Category(
                  id: 'cat-footwear',
                  categoryCode: 'FOOTWEAR',
                  categoryName: 'Footwear',
                  categorySlug: 'footwear',
                  status: 'ACTIVE',
                  sortOrder: 1,
                  level: 1,
                  hierarchyPath: 'Footwear',
                  childCount: 1,
                  productCount: 0,
                  hasChildren: true,
                ),
                childCategories: const [
                  CategoryTreeNode(
                    id: 'cat-shoe',
                    categoryCode: 'SHOE',
                    categoryName: 'Shoe',
                    status: 'ACTIVE',
                    sortOrder: 1,
                    level: 2,
                    hierarchyPath: 'Footwear > Shoe',
                    childCount: 0,
                    productCount: 0,
                    hasChildren: false,
                    children: [],
                    parentCategoryId: 'cat-footwear',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shoe'), findsOneWidget);
      expect(find.text('SHOE'), findsOneWidget);
    });
  });
}

Widget _wrap({
  required Widget child,
  required TenantAdminAccessChecker access,
  required Future<Category> Function(String id) loadCategory,
  CategoryRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
      categoryDetailPageAccessProvider.overrideWith(
        (ref) => access.hasProductCatalogEntitlement() &&
            access.canFetchCategoryList(),
      ),
      categoryUpdateAccessProvider.overrideWith(
        (ref) => access.canUpdateCategory(),
      ),
      categoryDeleteAccessProvider.overrideWith(
        (ref) => access.canDeleteCategory(),
      ),
      categoryDetailsProvider.overrideWith((ref, id) => loadCategory(id)),
      categoryTreeProvider.overrideWith(
        (ref) async => const <CategoryTreeNode>[],
      ),
      if (repository != null)
        categoryRepositoryProvider.overrideWith((ref) => repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}

Category _rootCategory() {
  return const Category(
    id: 'cat-root',
    categoryCode: 'GROC',
    categoryName: 'Groceries',
    categorySlug: 'groceries',
    status: 'ACTIVE',
    sortOrder: 0,
    level: 1,
    hierarchyPath: 'Groceries',
    childCount: 2,
    productCount: 0,
    hasChildren: true,
    createdAt: null,
    updatedAt: null,
  );
}

Category _childCategory({int level = 3}) {
  return Category(
    id: 'cat-child',
    parentCategoryId: 'cat-parent',
    parentCategoryName: 'Groceries',
    categoryCode: 'WATER',
    categoryName: 'Water Bottles',
    categorySlug: 'water-bottles',
    description: 'Still and sparkling water',
    imageUrl: 'https://cdn.example/category.png',
    status: 'ACTIVE',
    sortOrder: 2,
    level: level,
    hierarchyPath: 'Groceries > Beverages > Water Bottles',
    childCount: 4,
    productCount: 12,
    hasChildren: true,
    createdAt: DateTime.parse('2026-01-10T08:00:00Z'),
    updatedAt: DateTime.parse('2026-01-15T10:30:00Z'),
  );
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Test Tenant',
      userId: 'user-test',
      userDisplayName: 'Test User',
      roleNames: const ['Tenant Admin'],
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Tenant Admin'),
      ],
      outletScope: const [],
      featureEntitlements: const [],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: const [],
    ),
  );
}

DioException _dioError({
  required int statusCode,
  required Map<String, dynamic> body,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/categories/test'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/v1/categories/test'),
      statusCode: statusCode,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository({
    required this.details,
    this.archiveError,
  });

  final Category details;
  final Object? archiveError;

  @override
  Future<void> archiveCategory(String id) async {
    if (archiveError != null) {
      throw archiveError!;
    }
  }

  @override
  Future<Category> getCategoryById(String id) async => details;

  @override
  Future<CategoryListResult> getCategories({
    required CategoryListQuery query,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() {
    throw UnimplementedError();
  }

  @override
  Future<Category> createCategory(CategoryUpsertInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Category> updateCategory(String id, CategoryUpsertInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Category> uploadCategoryImage(
    String id,
    Uint8List bytes,
    String fileName,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Category> removeCategoryImage(String id) {
    throw UnimplementedError();
  }
}
