import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/data/mappers/category_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/data/models/category_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_list_query.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_tree_node.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/utils/category_form_utils.dart'
    hide deriveCategoryCode, formatCategoryUpdatedOn;
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_details_side_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_route_guard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  group('CategoryMapper', () {
    test('maps hierarchy and counts from dto', () {
      final entity = CategoryMapper.toEntity(
        CategoryDto(
          id: 'cat-1',
          parentCategoryId: 'cat-root',
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
          imageUrl: 'https://cdn.example/category.png',
          updatedAt: DateTime.parse('2026-01-15T10:30:00Z'),
        ),
      );

      expect(entity.categoryCode, 'WATER');
      expect(entity.level, 3);
      expect(entity.childCount, 4);
      expect(entity.productCount, 12);
      expect(entity.parentDisplayLabel, 'Groceries');
      expect(entity.hasImage, isTrue);
    });

    test('maps root parent display label', () {
      final entity = CategoryMapper.toEntity(
        const CategoryDto(
          id: 'root-1',
          categoryCode: 'GROC',
          categoryName: 'Groceries',
          categorySlug: 'groceries',
          status: 'ACTIVE',
          sortOrder: 0,
          level: 1,
          hierarchyPath: 'Groceries',
          childCount: 0,
          productCount: 0,
          hasChildren: false,
        ),
      );

      expect(entity.isRoot, isTrue);
      expect(entity.parentDisplayLabel, 'Root');
    });

    test('normalizes upsert code to uppercase', () {
      final dto = CategoryMapper.toRequestDto(
        const CategoryUpsertInput(
          categoryCode: 'water_bottles',
          name: 'Water Bottles',
          status: 'ACTIVE',
          sortOrder: 0,
        ),
      );

      expect(dto.categoryCode, 'WATER_BOTTLES');
      expect(dto.toJson()['categoryCode'], 'WATER_BOTTLES');
    });

    test('maps tree nodes recursively', () {
      final node = CategoryMapper.toTreeNode(
        CategoryTreeNodeDto(
          id: 'root',
          categoryCode: 'ROOT',
          categoryName: 'Root Category',
          status: 'INACTIVE',
          sortOrder: 0,
          level: 1,
          hierarchyPath: 'Root Category',
          childCount: 1,
          productCount: 0,
          hasChildren: true,
          children: const [
            CategoryTreeNodeDto(
              id: 'child',
              categoryCode: 'CHILD',
              categoryName: 'Child Category',
              status: 'ACTIVE',
              sortOrder: 0,
              level: 2,
              hierarchyPath: 'Root Category > Child Category',
              parentCategoryId: 'root',
              childCount: 0,
              productCount: 0,
              hasChildren: false,
              children: const [],
            ),
          ],
        ),
      );

      expect(node.children.length, 1);
      expect(node.children.first.parentCategoryId, 'root');
      expect(node.children.first.level, 2);
    });
  });

  group('CategoryListQuery', () {
    test('maps status filter values', () {
      expect(
        const CategoryListQuery(
          search: '',
          pageNumber: 1,
          pageSize: 5,
          statusFilter: CategoryStatusFilter.active,
        ).statusValue,
        'ACTIVE',
      );
      expect(
        const CategoryListQuery(
          search: '',
          pageNumber: 1,
          pageSize: 5,
          statusFilter: CategoryStatusFilter.inactive,
        ).statusValue,
        'INACTIVE',
      );
      expect(
        const CategoryListQuery(
          search: '',
          pageNumber: 1,
          pageSize: 5,
        ).statusValue,
        isNull,
      );
    });

    test('maps parent filter to rootOnly and parentCategoryId', () {
      const rootQuery = CategoryListQuery(
        search: '',
        pageNumber: 1,
        pageSize: 5,
        parentFilter: CategoryParentFilter(
          kind: CategoryParentFilterKind.rootOnly,
        ),
      );
      expect(rootQuery.rootOnly, isTrue);
      expect(rootQuery.parentCategoryId, isNull);

      const specificQuery = CategoryListQuery(
        search: '',
        pageNumber: 1,
        pageSize: 5,
        parentFilter: CategoryParentFilter(
          kind: CategoryParentFilterKind.specific,
          parentCategoryId: 'parent-1',
        ),
      );
      expect(specificQuery.rootOnly, isFalse);
      expect(specificQuery.parentCategoryId, 'parent-1');
    });
  });

  group('Category helpers', () {
    test('deriveCategoryCode normalizes name', () {
      expect(deriveCategoryCode('Water Bottles'), 'WATER_BOTTLES');
    });

    test('formatCategoryUpdatedOn returns dash for null', () {
      expect(formatCategoryUpdatedOn(null), '—');
    });

    test('visibleCategoryTreeRows hides children until expanded', () {
      const child = CategoryTreeNode(
        id: 'child',
        categoryCode: 'CHILD',
        categoryName: 'Shoes',
        status: 'ACTIVE',
        sortOrder: 0,
        level: 2,
        hierarchyPath: 'Footwear > Shoes',
        parentCategoryId: 'parent',
        childCount: 0,
        productCount: 0,
        hasChildren: false,
        children: [],
      );
      const parent = CategoryTreeNode(
        id: 'parent',
        categoryCode: 'FOOT',
        categoryName: 'Footwear',
        status: 'ACTIVE',
        sortOrder: 0,
        level: 1,
        hierarchyPath: 'Footwear',
        childCount: 1,
        productCount: 0,
        hasChildren: true,
        children: [child],
      );

      final collapsed = visibleCategoryTreeRows(
        nodes: const [parent],
        expandedIds: const {},
      );
      expect(collapsed, hasLength(1));
      expect(collapsed.single.node.id, 'parent');

      final expanded = visibleCategoryTreeRows(
        nodes: const [parent],
        expandedIds: const {'parent'},
      );
      expect(expanded, hasLength(2));
      expect(expanded[1].node.id, 'child');
      expect(expanded[1].parentName, 'Footwear');
      expect(expanded[1].depth, 1);
    });

    test('paginateList returns the requested page and clamps overflow', () {
      final items = List<int>.generate(12, (index) => index + 1);

      expect(
        paginateList(items, page: 1, pageSize: 5),
        [1, 2, 3, 4, 5],
      );
      expect(
        paginateList(items, page: 3, pageSize: 5),
        [11, 12],
      );
      expect(
        paginateList(items, page: 99, pageSize: 5),
        [11, 12],
      );
      expect(paginateList(items, page: 1, pageSize: 12), items);
      expect(paginateList<int>(const [], page: 1, pageSize: 5), isEmpty);
    });
  });

  group('CategoryListVisibility', () {
    test('shows page with view permission and product catalog entitlement', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
        features: const ['product_catalog'],
      );

      final visibility = CategoryListVisibility.resolve(access: access);

      expect(visibility.showPage, isTrue);
      expect(visibility.showList, isTrue);
      expect(visibility.showSearch, isTrue);
    });

    test('hides page without view/manage permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantProductsView],
        features: const ['product_catalog'],
      );

      expect(CategoryListVisibility.resolve(access: access).showPage, isFalse);
    });

    test('shows add category with create permission', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantCategoriesView,
          TenantAdminPermissionCodes.tenantCategoriesCreate,
        ],
        features: const ['product_catalog'],
      );

      expect(
        CategoryListVisibility.resolve(access: access).showAddCategory,
        isTrue,
      );
    });

    test('shows add category with manage permission alias', () {
      final access = _checker(
        permissions: [
          'catalog.categories.view',
          'catalog.categories.manage',
        ],
        features: const ['product_catalog'],
      );

      final visibility = CategoryListVisibility.resolve(access: access);
      expect(visibility.showAddCategory, isTrue);
      expect(visibility.showEditAction, isTrue);
      expect(visibility.showDeleteAction, isTrue);
    });

    test('hides create without create/manage permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
        features: const ['product_catalog'],
      );

      expect(
        CategoryListVisibility.resolve(access: access).showAddCategory,
        isFalse,
      );
    });

    test('shows edit and status with update permission', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantCategoriesView,
          TenantAdminPermissionCodes.tenantCategoriesUpdate,
        ],
        features: const ['product_catalog'],
      );

      final visibility = CategoryListVisibility.resolve(access: access);
      expect(visibility.showEditAction, isTrue);
      expect(visibility.showStatusAction, isTrue);
      expect(visibility.showDeleteAction, isFalse);
    });

    test('shows delete with delete permission', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantCategoriesView,
          TenantAdminPermissionCodes.tenantCategoriesDelete,
        ],
        features: const ['product_catalog'],
      );

      expect(
        CategoryListVisibility.resolve(access: access).showDeleteAction,
        isTrue,
      );
    });
  });

  group('ProductsRouteGuard categories', () {
    test('allows categories route with view permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
        features: const ['product_catalog'],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categories,
        ),
        isTrue,
      );
    });

    test('blocks categories route without view permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantProductsView],
        features: const ['product_catalog'],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categories,
        ),
        isFalse,
      );
    });
  });

  group('categoryApiErrorMessage', () {
    test('maps duplicate code message', () {
      expect(
        categoryApiErrorMessage(
          _fakeDioError({'code': 'category.duplicate_code'}),
        ),
        'Category code already exists.',
      );
    });

    test('maps max depth exceeded message', () {
      expect(
        categoryApiErrorMessage(
          _fakeDioError({'code': 'category.max_depth_exceeded'}),
        ),
        'Category hierarchy cannot exceed 5 levels.',
      );
    });
  });
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  List<String> features = const [],
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
      featureEntitlements: [
        for (final featureCode in features)
          TenantAdminFeatureEntitlement(
            featureCode: featureCode,
            featureName: featureCode,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: [
        for (final featureCode in features)
          TenantAdminRuntimeFlag(featureCode: featureCode, enabled: true),
      ],
    ),
  );
}

Object _fakeDioError(Map<String, dynamic> data) {
  final requestOptions = RequestOptions(path: '/api/v1/categories');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      data: data,
      statusCode: 400,
    ),
    type: DioExceptionType.badResponse,
  );
}
