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
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/screens/edit_category_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_edit_form.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_states.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_route_guard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  group('Edit Category route access', () {
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

    test('manage permission allows edit route', () {
      final access = _checker(permissions: ['catalog.categories.manage']);

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

  group('EditCategoryScreen', () {
    testWidgets('shows loading then prefilled form at 1024x768',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _RecordingCategoryRepository(
        details: _childCategory(),
        tree: _sampleTree(),
      );

      await tester.pumpWidget(
        _wrapEditScreen(
          categoryId: 'cat-child',
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesUpdate],
          ),
          repository: repository,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(
          find.textContaining('Update category information'), findsOneWidget);
      expect(find.textContaining('Product /'), findsNothing);
      expect(find.text('Back to List'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Save as Draft'), findsNothing);
      expect(find.textContaining('Department'), findsNothing);
      expect(find.textContaining('SubCategory'), findsNothing);
      expect(find.text('Water Bottles'), findsOneWidget);
      expect(find.text('WATER'), findsOneWidget);
      expect(find.text('Still and sparkling water'), findsOneWidget);
      expect(find.text('Current category image'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('root category prefilled correctly', (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _rootCategory(),
        tree: _sampleTree(),
      );

      await tester.pumpWidget(
        _wrapEditScreen(
          categoryId: 'cat-root',
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesUpdate],
          ),
          repository: repository,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Root Category'), findsWidgets);
      expect(find.text('GROC'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('unchanged inactive parent remains visible and save succeeds',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _RecordingCategoryRepository(
        details: _childWithInactiveParent(),
        tree: _treeWithInactiveParent(),
      );
      final formKey = GlobalKey<CategoryEditFormState>();

      await tester.pumpWidget(
        _wrapEditFormHarness(
          categoryId: 'cat-child',
          repository: repository,
          formKey: formKey,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Inactive Parent (Inactive)'), findsOneWidget);

      await tester.enterText(
          find.byType(TextFormField).at(3), 'Updated description only');
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) {},
        onError: (_, __) {},
      );
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(
          repository.lastUpdateInput?.description, 'Updated description only');
      expect(repository.lastUpdateInput?.parentCategoryId, 'inactive-parent');
    });

    testWidgets('edit name only with unchanged inactive parent succeeds',
        (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childWithInactiveParent(),
        tree: _treeWithInactiveParent(),
      );
      final formKey = GlobalKey<CategoryEditFormState>();

      await tester.pumpWidget(
        _wrapEditFormHarness(
          categoryId: 'cat-child',
          repository: repository,
          formKey: formKey,
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Renamed Child');
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) {},
        onError: (_, __) {},
      );
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(repository.lastUpdateInput?.name, 'Renamed Child');
      expect(repository.lastUpdateInput?.parentCategoryId, 'inactive-parent');
    });

    testWidgets('parent selector lists only ACTIVE candidates', (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childWithInactiveParent(),
        tree: _treeWithInactiveParent(),
      );

      await tester.pumpWidget(
        _wrapEditScreen(
          categoryId: 'cat-child',
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesUpdate],
          ),
          repository: repository,
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Inactive Parent (Inactive)'));
      await tester.pumpAndSettle();

      expect(find.text('Beverages'), findsWidgets);
      expect(find.text('Select Parent Category'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Inactive Parent'),
        ),
        findsNothing,
      );
    });

    testWidgets('maps parent_inactive backend error to parent field',
        (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childCategory(),
        tree: _sampleTree(),
        updateError: _dioError(
          statusCode: 400,
          body: {'code': 'category.parent_inactive'},
        ),
      );
      final formKey = GlobalKey<CategoryEditFormState>();

      await tester.pumpWidget(
        _wrapEditFormHarness(
          categoryId: 'cat-child',
          repository: repository,
          formKey: formKey,
        ),
      );

      await tester.pumpAndSettle();
      Map<String, String>? fieldErrors;
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) {},
        onError: (_, errors) => fieldErrors = errors,
      );

      expect(fieldErrors?['parent'], isNotNull);
      expect(fieldErrors!['parent']!, contains('inactive'));
    });

    testWidgets('maps max depth error and preserves form', (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childCategory(),
        tree: _sampleTree(),
        updateError: _dioError(
          statusCode: 400,
          body: {'code': 'category.max_depth_exceeded'},
        ),
      );
      final formKey = GlobalKey<CategoryEditFormState>();

      await tester.pumpWidget(
        _wrapEditFormHarness(
          categoryId: 'cat-child',
          repository: repository,
          formKey: formKey,
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Updated Name');

      Object? capturedError;
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) {},
        onError: (error, __) => capturedError = error,
      );
      await tester.pumpAndSettle();

      expect(capturedError, isNotNull);
      expect(categoryApiErrorMessage(capturedError!), contains('5 levels'));
      expect(find.text('Updated Name'), findsOneWidget);
    });

    testWidgets('partial image upload failure keeps master update',
        (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childCategory(),
        tree: _sampleTree(),
        uploadError: _dioError(
          statusCode: 500,
          body: {'message': 'Image upload failed'},
        ),
      );

      final formKey = GlobalKey<CategoryEditFormState>();
      await tester.pumpWidget(
        _wrapEditForm(repository: repository, formKey: formKey),
      );
      await tester.pumpAndSettle();

      formKey.currentState!.stagePendingImageForTest(
        _onePixelPng,
        'replacement.jpg',
      );

      var partial = false;
      await formKey.currentState!.submit(
        onSuccess: () {},
        onPartialSuccess: (_) => partial = true,
        onError: (_, __) {},
      );

      expect(repository.updateCalls, 1);
      expect(repository.uploadCalls, 1);
      expect(partial, isTrue);
    });

    testWidgets('no access when update permission missing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => _checker(permissions: const []),
            ),
            categoryUpdateAccessProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: EditCategoryScreen(categoryId: 'cat-child'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('You do not have permission to edit categories.'),
        findsOneWidget,
      );
    });

    testWidgets('not found state for missing category', (tester) async {
      final repository = _RecordingCategoryRepository(
        details: _childCategory(),
        tree: _sampleTree(),
        detailsError: _dioError(
          statusCode: 404,
          body: {'code': 'category.not_found'},
        ),
      );

      await tester.pumpWidget(
        _wrapEditScreen(
          categoryId: 'missing',
          access: _checker(
            permissions: [TenantAdminPermissionCodes.tenantCategoriesUpdate],
          ),
          repository: repository,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Category not found'), findsOneWidget);
    });
  });
}

Widget _wrapEditScreen({
  required String categoryId,
  required TenantAdminAccessChecker access,
  required _RecordingCategoryRepository repository,
}) {
  return ProviderScope(
    overrides: [
      tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
      categoryUpdateAccessProvider
          .overrideWith((ref) => access.canUpdateCategory()),
      categoryDetailsProvider.overrideWith((ref, id) async {
        if (repository.detailsError != null) {
          throw repository.detailsError!;
        }
        return repository.details;
      }),
      categoryRepositoryProvider.overrideWith((ref) => repository),
      categoryTreeProvider.overrideWith((ref) async => repository.tree),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: 1600,
            child: EditCategoryScreen(categoryId: categoryId),
          ),
        ),
      ),
    ),
  );
}

Widget _wrapEditFormHarness({
  required String categoryId,
  required _RecordingCategoryRepository repository,
  required GlobalKey<CategoryEditFormState> formKey,
}) {
  return ProviderScope(
    overrides: [
      categoryDetailsProvider
          .overrideWith((ref, id) async => repository.details),
      categoryRepositoryProvider.overrideWith((ref) => repository),
      categoryTreeProvider.overrideWith((ref) async => repository.tree),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: 1600,
            child: _EditFormHarness(
              categoryId: categoryId,
              formKey: formKey,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditFormHarness extends ConsumerWidget {
  const _EditFormHarness({
    required this.categoryId,
    required this.formKey,
  });

  final String categoryId;
  final GlobalKey<CategoryEditFormState> formKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryDetailsProvider(categoryId));
    final treeState = ref.watch(categoryTreeProvider);

    return categoryAsync.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
      error: (_, __) => const SizedBox.shrink(),
      data: (category) => treeState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
        error: (_, __) => const SizedBox.shrink(),
        data: (_) => CategoryEditForm(
          key: formKey,
          category: category,
          submitting: false,
          onCancel: () {},
          onSavePressed: () {},
        ),
      ),
    );
  }
}

final _onePixelPng = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _wrapEditForm({
  required _RecordingCategoryRepository repository,
  GlobalKey<CategoryEditFormState>? formKey,
}) {
  return ProviderScope(
    overrides: [
      categoryRepositoryProvider.overrideWith((ref) => repository),
      categoryTreeProvider.overrideWith((ref) async => repository.tree),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: 1600,
            child: CategoryEditForm(
              key: formKey,
              category: _childCategory(),
              submitting: false,
              onCancel: () {},
              onSavePressed: () {},
            ),
          ),
        ),
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
  );
}

Category _childCategory() {
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
    level: 3,
    hierarchyPath: 'Groceries > Beverages > Water Bottles',
    childCount: 4,
    productCount: 12,
    hasChildren: true,
  );
}

Category _childWithInactiveParent() {
  return Category(
    id: 'cat-child',
    parentCategoryId: 'inactive-parent',
    parentCategoryName: 'Inactive Parent',
    categoryCode: 'CHILD',
    categoryName: 'Child Category',
    categorySlug: 'child-category',
    status: 'ACTIVE',
    sortOrder: 0,
    level: 2,
    hierarchyPath: 'Inactive Parent > Child Category',
    childCount: 0,
    productCount: 0,
    hasChildren: false,
  );
}

List<CategoryTreeNode> _sampleTree() {
  return const [
    CategoryTreeNode(
      id: 'cat-root',
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
          id: 'cat-parent',
          categoryCode: 'BEV',
          categoryName: 'Beverages',
          status: 'ACTIVE',
          sortOrder: 0,
          level: 2,
          hierarchyPath: 'Groceries > Beverages',
          parentCategoryId: 'cat-root',
          childCount: 1,
          productCount: 0,
          hasChildren: true,
          children: [],
        ),
      ],
    ),
  ];
}

List<CategoryTreeNode> _treeWithInactiveParent() {
  return const [
    CategoryTreeNode(
      id: 'inactive-parent',
      categoryCode: 'INACT',
      categoryName: 'Inactive Parent',
      status: 'INACTIVE',
      sortOrder: 0,
      level: 1,
      hierarchyPath: 'Inactive Parent',
      childCount: 1,
      productCount: 0,
      hasChildren: true,
      children: [],
    ),
    CategoryTreeNode(
      id: 'active-parent',
      categoryCode: 'BEV',
      categoryName: 'Beverages',
      status: 'ACTIVE',
      sortOrder: 0,
      level: 1,
      hierarchyPath: 'Beverages',
      childCount: 0,
      productCount: 0,
      hasChildren: false,
      children: [],
    ),
  ];
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

class _RecordingCategoryRepository implements CategoryRepository {
  _RecordingCategoryRepository({
    required this.details,
    required this.tree,
    this.detailsError,
    this.updateError,
    this.uploadError,
  });

  final Category details;
  final List<CategoryTreeNode> tree;
  final Object? detailsError;
  final Object? updateError;
  final Object? uploadError;

  int updateCalls = 0;
  int uploadCalls = 0;
  int removeCalls = 0;
  CategoryUpsertInput? lastUpdateInput;

  @override
  Future<Category> getCategoryById(String id) async {
    if (detailsError != null) {
      throw detailsError!;
    }
    return details;
  }

  @override
  Future<List<CategoryTreeNode>> getCategoryTree() async => tree;

  @override
  Future<Category> updateCategory(String id, CategoryUpsertInput input) async {
    updateCalls++;
    lastUpdateInput = input;
    if (updateError != null) {
      throw updateError!;
    }
    return Category(
      id: id,
      parentCategoryId: input.parentCategoryId,
      parentCategoryName: details.parentCategoryName,
      categoryCode: input.categoryCode,
      categoryName: input.name,
      categorySlug: details.categorySlug,
      description: input.description,
      imageUrl: details.imageUrl,
      status: input.status,
      sortOrder: input.sortOrder,
      level: details.level,
      hierarchyPath: details.hierarchyPath,
      childCount: details.childCount,
      productCount: details.productCount,
      hasChildren: details.hasChildren,
    );
  }

  @override
  Future<Category> uploadCategoryImage(
    String id,
    Uint8List bytes,
    String fileName,
  ) async {
    uploadCalls++;
    if (uploadError != null) {
      throw uploadError!;
    }
    return details;
  }

  @override
  Future<Category> removeCategoryImage(String id) async {
    removeCalls++;
    return details;
  }

  @override
  Future<void> archiveCategory(String id) async {}

  @override
  Future<CategoryListResult> getCategories({
    required CategoryListQuery query,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Category> createCategory(CategoryUpsertInput input) {
    throw UnimplementedError();
  }
}
