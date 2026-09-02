import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_tree_node.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/screens/add_category_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_add_form.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_route_guard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  group('Add Category access', () {
    test('route allowed with create permission', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantCategoriesCreate,
        ],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoriesAdd,
        ),
        isTrue,
      );
      expect(access.canCreateCategory(), isTrue);
    });

    test('route blocked without create/manage permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoriesAdd,
        ),
        isFalse,
      );
    });

    test('route allowed with manage permission alias', () {
      final access = _checker(
        permissions: ['catalog.categories.manage'],
      );

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.categoriesAdd,
        ),
        isTrue,
      );
    });
  });

  group('categoryFieldErrorsFromError', () {
    test('maps duplicate name to name field', () {
      expect(
        categoryFieldErrorsFromError(
          _fakeDioError({'code': 'category.duplicate_name'}),
        ).containsKey('name'),
        isTrue,
      );
    });

    test('maps max depth to parent field', () {
      expect(
        categoryFieldErrorsFromError(
          _fakeDioError({'code': 'category.max_depth_exceeded'}),
        ).containsKey('parent'),
        isTrue,
      );
    });
  });

  group('AddCategoryScreen widget', () {
    testWidgets('renders core fields without breadcrumb or draft action',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapForm(
          child: const AddCategoryScreen(),
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesCreate],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Category'), findsOneWidget);
      expect(find.textContaining('Create a new product category'), findsOneWidget);
      expect(find.text('Back to List'), findsOneWidget);
      expect(find.textContaining('Product /'), findsNothing);
      expect(find.text('Save as Draft'), findsNothing);
      expect(find.text('Create Category'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Root Category'), findsOneWidget);
      expect(find.textContaining('Department'), findsNothing);
    });

    testWidgets('shows child indicator when parent selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final formKey = GlobalKey<CategoryAddFormState>();

      await tester.pumpWidget(
        _wrapForm(
          child: CategoryAddForm(
            key: formKey,
            submitting: false,
            onCancel: () {},
            onCreatePressed: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('No parent selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beverages'));
      await tester.pumpAndSettle();

      expect(find.text('Child Category'), findsOneWidget);
      expect(find.textContaining('Parent: Groceries > Beverages'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      final formKey = GlobalKey<CategoryAddFormState>();

      await tester.pumpWidget(
        _wrapForm(
          child: CategoryAddForm(
            key: formKey,
            submitting: false,
            onCancel: () {},
            onCreatePressed: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) {},
        onError: (_, __) {},
      );
      await tester.pumpAndSettle();

      expect(find.text('Category name is required.'), findsOneWidget);
      expect(find.text('Category code is required.'), findsOneWidget);
    });

    testWidgets('no access state when create permission missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => _checker(
                permissions: [TenantAdminPermissionCodes.tenantCategoriesView],
              ),
            ),
            categoryAddPageAccessProvider.overrideWith((ref) => false),
            categoryTreeProvider.overrideWith((ref) async => _sampleTree()),
          ],
          child: const MaterialApp(home: AddCategoryScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text('You do not have permission to create categories.'),
        findsOneWidget,
      );
    });
  });
}

Widget _wrapForm({
  required Widget child,
  TenantAdminAccessChecker? access,
}) {
  return ProviderScope(
    overrides: [
      if (access != null)
        tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
      categoryAddPageAccessProvider.overrideWith((ref) => true),
      categoryTreeProvider.overrideWith((ref) async => _sampleTree()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(height: 1800, child: child),
        ),
      ),
    ),
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

List<CategoryTreeNode> _sampleTree() {
  return const [
    CategoryTreeNode(
      id: 'root-1',
      categoryCode: 'GROC',
      categoryName: 'Groceries',
      status: 'ACTIVE',
      sortOrder: 0,
      level: 1,
      hierarchyPath: 'Groceries',
      childCount: 1,
      productCount: 0,
      hasChildren: true,
      children: [
        CategoryTreeNode(
          id: 'child-1',
          categoryCode: 'BEV',
          categoryName: 'Beverages',
          status: 'ACTIVE',
          sortOrder: 0,
          level: 2,
          hierarchyPath: 'Groceries > Beverages',
          parentCategoryId: 'root-1',
          childCount: 0,
          productCount: 0,
          hasChildren: false,
          children: [],
        ),
      ],
    ),
  ];
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
