import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_list_query.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_tree_node.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/repositories/category_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/screens/category_details_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/utils/category_form_utils.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_archive_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_table.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  group('categoryArchiveErrorMessage', () {
    test('maps child category conflict', () {
      expect(
        categoryArchiveErrorMessage(
          _dioError(
            statusCode: 409,
            body: {
              'code': 'category.delete_conflict',
              'message':
                  'Category cannot be deleted while child categories exist.',
            },
          ),
        ),
        contains('child categories'),
      );
    });

    test('maps product mapping conflict', () {
      expect(
        categoryArchiveErrorMessage(
          _dioError(
            statusCode: 409,
            body: {
              'code': 'category.delete_conflict',
              'message':
                  'Category cannot be deleted while products are linked.',
            },
          ),
        ),
        contains('products are still assigned'),
      );
    });

    test('maps permission denied', () {
      expect(
        categoryArchiveErrorMessage(
          _dioError(
            statusCode: 403,
            body: {'code': 'category.permission_denied'},
          ),
        ),
        contains('permission'),
      );
    });
  });

  group('CategoryArchiveDialog', () {
    testWidgets('cancel closes dialog without archive call', (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Archive Category'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 0);
    });

    testWidgets('confirm success archives once and shows success feedback',
        (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
      expect(find.text('Category archived successfully.'), findsOneWidget);
    });

    testWidgets('double tap sends only one archive request', (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
        archiveDelay: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final confirmButton = find.text('Archive Category').last;
      await tester.tap(confirmButton);
      await tester.pump();
      await tester.tap(confirmButton);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
    });

    testWidgets('child conflict keeps dialog open and shows message',
        (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
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
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
      expect(find.textContaining('child categories'), findsOneWidget);
      expect(find.text('Archive Category'), findsWidgets);
    });

    testWidgets('product conflict shows mapping message', (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
        archiveError: _dioError(
          statusCode: 409,
          body: {
            'code': 'category.delete_conflict',
            'message': 'Category cannot be deleted while products are linked.',
          },
        ),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('products are still assigned'), findsOneWidget);
    });

    testWidgets('network error keeps category unchanged', (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
        archiveError: DioException(
          requestOptions: RequestOptions(path: '/api/v1/categories/cat-1'),
          type: DioExceptionType.connectionError,
        ),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
      expect(find.text('Archive Category'), findsWidgets);
    });

    testWidgets('renders at 1024x768 without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: _TrackingCategoryRepository(listResult: _singleItemList()),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Product Setup selection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Archive from Category Details', () {
    testWidgets('success navigates to list', (tester) async {
      final repository = _TrackingCategoryRepository(
        details: _sampleCategory(),
        listResult: _singleItemList(),
      );

      final router = GoRouter(
        initialLocation: ProductsSidebarRoutes.categoryDetail('cat-1'),
        routes: [
          GoRoute(
            path: ProductsSidebarRoutes.categories,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Category List Page')),
            ),
          ),
          GoRoute(
            path: '${ProductsSidebarRoutes.categories}/:id',
            builder: (context, state) => Scaffold(
              body: CategoryDetailsScreen(
                categoryId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _accessOverrides(
            permissions: [
              TenantAdminPermissionCodes.tenantCategoriesView,
              TenantAdminPermissionCodes.tenantCategoriesDelete,
            ],
            repository: repository,
          ),
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(find.text('Category List Page'), findsOneWidget);
      expect(repository.archiveCallCount, 1);
    });
  });

  group('Archive from Category List', () {
    testWidgets('list entry uses shared archive dialog', (tester) async {
      final repository = _TrackingCategoryRepository(
        listResult: _singleItemList(),
      );

      await tester.pumpWidget(
        _archiveDialogHarness(
          repository: repository,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CategoryArchiveDialog.show(
                context: context,
                category: _sampleCategory(),
              ),
              child: const Text('Archive From List'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Archive From List'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
      expect(find.text('Category archived successfully.'), findsOneWidget);
    });
  });

  group('Archive from Category table', () {
    testWidgets('archive success reloads tree provider', (tester) async {
      final repository = _TrackingCategoryRepository(
        tree: _inactiveParentWithActiveChild(),
      );

      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._accessOverrides(
              permissions: [
                TenantAdminPermissionCodes.tenantCategoriesView,
                TenantAdminPermissionCodes.tenantCategoriesDelete,
              ],
              repository: repository,
            ),
            categoryTreeProvider.overrideWith((ref) async => repository.tree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryTable(
                nodes: repository.tree,
                canView: true,
                canEdit: false,
                canDelete: true,
                canChangeStatus: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(repository.archiveCallCount, 1);
      expect(find.text('Inactive Parent'), findsOneWidget);
    });

    testWidgets('child conflict preserves hierarchy', (tester) async {
      final repository = _TrackingCategoryRepository(
        tree: _inactiveParentWithActiveChild(),
        archiveError: _dioError(
          statusCode: 409,
          body: {
            'code': 'category.delete_conflict',
            'message':
                'Category cannot be deleted while child categories exist.',
          },
        ),
      );

      await tester.binding.setSurfaceSize(const Size(1400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._accessOverrides(
              permissions: [
                TenantAdminPermissionCodes.tenantCategoriesView,
                TenantAdminPermissionCodes.tenantCategoriesDelete,
              ],
              repository: repository,
            ),
            categoryTreeProvider.overrideWith((ref) async => repository.tree),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryTable(
                nodes: repository.tree,
                canView: true,
                canEdit: false,
                canDelete: true,
                canChangeStatus: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive Category').last);
      await tester.pumpAndSettle();

      expect(find.text('Inactive Parent'), findsOneWidget);
      expect(find.text('Active Child'), findsNothing);
      expect(find.textContaining('child categories'), findsOneWidget);
    });
  });

  group('Pagination correction', () {
    test('moves to previous page when last item on page archived', () async {
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWith(
            (ref) => _TrackingCategoryRepository(
              listResult: CategoryListResult(
                items: [_sampleCategory()],
                pageNumber: 3,
                pageSize: 20,
                totalCount: 41,
              ),
            ),
          ),
          categoryListProvider.overrideWith(
            (ref) async => CategoryListResult(
              items: [_sampleCategory()],
              pageNumber: 3,
              pageSize: 20,
              totalCount: 41,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(categoryPageProvider.notifier).state = 3;
      await container.read(categoryListProvider.future);

      await container
          .read(categorySaveControllerProvider.notifier)
          .archive('cat-1');

      expect(container.read(categoryPageProvider), 2);
    });
  });
}

List<Override> _accessOverrides({
  required List<String> permissions,
  required CategoryRepository repository,
  CategoryListResult? listResult,
}) {
  final access = _checker(permissions: permissions);

  return [
    tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
    categoryListVisibilityProvider.overrideWith(
      (ref) => AsyncData(CategoryListVisibility.resolve(access: access)),
    ),
    categoryDetailPageAccessProvider.overrideWith((ref) => true),
    categoryUpdateAccessProvider.overrideWith((ref) => access.canUpdateCategory()),
    categoryDeleteAccessProvider.overrideWith((ref) => access.canDeleteCategory()),
    categoryRepositoryProvider.overrideWith((ref) => repository),
    if (listResult != null)
      categoryListProvider.overrideWith((ref) async => listResult),
    categoryDetailsProvider.overrideWith(
      (ref, id) async => (repository as _TrackingCategoryRepository).details ??
          _sampleCategory(id: id),
    ),
  ];
}

Widget _archiveDialogHarness({
  required _TrackingCategoryRepository repository,
  required Widget child,
}) {
  return ProviderScope(
    overrides: _accessOverrides(
      permissions: [
        TenantAdminPermissionCodes.tenantCategoriesView,
        TenantAdminPermissionCodes.tenantCategoriesDelete,
      ],
      repository: repository,
      listResult: repository.listResult,
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

CategoryListResult _singleItemList() {
  return CategoryListResult(
    items: [_sampleCategory()],
    pageNumber: 1,
    pageSize: 20,
    totalCount: 1,
  );
}

Category _sampleCategory({String id = 'cat-1'}) {
  return Category(
    id: id,
    categoryCode: 'BEV',
    categoryName: 'Beverages',
    categorySlug: 'beverages',
    status: 'ACTIVE',
    sortOrder: 0,
    level: 1,
    hierarchyPath: 'Beverages',
    childCount: 0,
    productCount: 0,
    hasChildren: false,
  );
}

List<CategoryTreeNode> _inactiveParentWithActiveChild() {
  return const [
    CategoryTreeNode(
      id: 'parent-inactive',
      categoryCode: 'INACT',
      categoryName: 'Inactive Parent',
      status: 'INACTIVE',
      sortOrder: 0,
      level: 1,
      hierarchyPath: 'Inactive Parent',
      childCount: 1,
      productCount: 0,
      hasChildren: true,
      children: [
        CategoryTreeNode(
          id: 'child-active',
          categoryCode: 'CHILD',
          categoryName: 'Active Child',
          status: 'ACTIVE',
          sortOrder: 0,
          level: 2,
          hierarchyPath: 'Inactive Parent > Active Child',
          parentCategoryId: 'parent-inactive',
          childCount: 0,
          productCount: 0,
          hasChildren: false,
          children: [],
        ),
      ],
    ),
  ];
}

TenantAdminAccessChecker _checker({required List<String> permissions}) {
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
    requestOptions: RequestOptions(path: '/api/v1/categories/cat-1'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/v1/categories/cat-1'),
      statusCode: statusCode,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

class _TrackingCategoryRepository implements CategoryRepository {
  _TrackingCategoryRepository({
    this.details,
    this.listResult,
    this.tree = const [],
    this.archiveError,
    this.archiveDelay = Duration.zero,
  });

  final Category? details;
  final CategoryListResult? listResult;
  final List<CategoryTreeNode> tree;
  final Object? archiveError;
  final Duration archiveDelay;

  var archiveCallCount = 0;

  @override
  Future<void> archiveCategory(String id) async {
    archiveCallCount++;
    if (archiveDelay > Duration.zero) {
      await Future<void>.delayed(archiveDelay);
    }
    if (archiveError != null) {
      throw archiveError!;
    }
  }

  @override
  Future<Category> getCategoryById(String id) async {
    return details ?? _sampleCategory(id: id);
  }

  @override
  Future<CategoryListResult> getCategories({
    required CategoryListQuery query,
  }) async {
    return listResult ??
        CategoryListResult(
          items: const [],
          pageNumber: query.pageNumber,
          pageSize: query.pageSize,
          totalCount: 0,
        );
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async => tree;

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
