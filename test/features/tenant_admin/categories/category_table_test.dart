import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/domain/entities/category_tree_node.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/providers/category_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/screens/category_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/categories/presentation/widgets/category_table.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';

void main() {
  Future<void> setSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  group('CategoryTable', () {
    testWidgets('renders original table columns and collapsed parent row',
        (tester) async {
      await setSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Product Count'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Child Categories'), findsNothing);
      expect(find.text('Last Updated'), findsNothing);

      expect(find.text('Footwear'), findsOneWidget);
      expect(find.text('FOOT'), findsOneWidget);
      expect(find.text('Shoes'), findsNothing);
    });

    testWidgets('expand shows child row under parent', (tester) async {
      await setSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Expand'));
      await tester.pumpAndSettle();

      expect(find.text('Shoes'), findsOneWidget);
      expect(find.text('SHOE'), findsOneWidget);
    });

    testWidgets('parent row tap opens details without expanding',
        (tester) async {
      await setSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Footwear'));
      await tester.pumpAndSettle();

      expect(find.text('Details parent-footwear'), findsOneWidget);
      expect(find.text('Shoes'), findsNothing);
    });

    testWidgets('row tap opens details and actions use overflow menu',
        (tester) async {
      await setSize(tester, const Size(1400, 800));
      FlutterError.onError = (details) {
        if (details.toString().contains('OVERFLOW')) {
          fail(details.toString());
        }
      };

      await tester.pumpWidget(
        _wrapTable(
          nodes: _footwearTree(),
          canEdit: true,
          canDelete: true,
          canChangeStatus: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('View'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.byTooltip('Actions'), findsOneWidget);

      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Inactivate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('level column is visible at tablet width', (tester) async {
      await setSize(tester, const Size(900, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Level'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('compact width keeps core columns and hides extras',
        (tester) async {
      await setSize(tester, const Size(600, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Product Count'), findsNothing);
      expect(find.text('Child Categories'), findsNothing);
      expect(find.text('Last Updated'), findsNothing);

      expect(find.text('Footwear'), findsOneWidget);
      await tester.tap(find.byTooltip('Expand'));
      await tester.pumpAndSettle();
      expect(find.text('Shoes'), findsOneWidget);
    });

    testWidgets('desktop width fills extra space without horizontal scroll',
        (tester) async {
      await setSize(tester, const Size(1100, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('category and code stay close with balanced column gaps',
        (tester) async {
      await setSize(tester, const Size(1400, 800));
      await tester.pumpWidget(
        _wrapTable(nodes: _footwearTree()),
      );
      await tester.pumpAndSettle();

      final categoryLeft = tester.getTopLeft(find.text('Category')).dx;
      final codeLeft = tester.getTopLeft(find.text('Code')).dx;
      final levelLeft = tester.getTopLeft(find.text('Level')).dx;
      final productCountLeft = tester.getTopLeft(find.text('Product Count')).dx;
      final statusLeft = tester.getTopLeft(find.text('Status')).dx;

      expect(codeLeft - categoryLeft, lessThan(340));
      expect(codeLeft - categoryLeft, greaterThan(200));
      expect(levelLeft - codeLeft, greaterThan(120));
      expect(productCountLeft - levelLeft, greaterThan(70));
      expect(statusLeft - productCountLeft, greaterThan(100));
    });
  });

  group('Category list pagination', () {
    testWidgets('paginates extra categories and hides bar when not needed',
        (tester) async {
      await setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(
        _wrapListScreen(tree: _sixRootCategories()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cat 1'), findsOneWidget);
      expect(find.text('Cat 5'), findsOneWidget);
      expect(find.text('Cat 6'), findsNothing);
      expect(
          find.textContaining('Showing 1–5 of 6 categories'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Cat 6'), findsOneWidget);
      expect(find.text('Cat 1'), findsNothing);
      expect(
          find.textContaining('Showing 6–6 of 6 categories'), findsOneWidget);
    });

    testWidgets('hides pagination when all categories fit on one page',
        (tester) async {
      await setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(
        _wrapListScreen(tree: _footwearTree()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsNothing);
      expect(find.textContaining('Showing'), findsNothing);
    });
  });
}

Widget _wrapTable({
  required List<CategoryTreeNode> nodes,
  bool canEdit = false,
  bool canDelete = false,
  bool canChangeStatus = false,
}) {
  final router = GoRouter(
    initialLocation: ProductsSidebarRoutes.categories,
    routes: [
      GoRoute(
        path: ProductsSidebarRoutes.categories,
        builder: (context, state) => Scaffold(
          body: CategoryTable(
            nodes: nodes,
            canView: true,
            canEdit: canEdit,
            canDelete: canDelete,
            canChangeStatus: canChangeStatus,
          ),
        ),
      ),
      GoRoute(
        path: '${ProductsSidebarRoutes.categories}/:id',
        builder: (context, state) => Scaffold(
          body: Text('Details ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

List<CategoryTreeNode> _footwearTree() {
  return const [
    CategoryTreeNode(
      id: 'parent-footwear',
      categoryCode: 'FOOT',
      categoryName: 'Footwear',
      status: 'ACTIVE',
      sortOrder: 0,
      level: 1,
      hierarchyPath: 'Footwear',
      childCount: 1,
      productCount: 3,
      hasChildren: true,
      children: [
        CategoryTreeNode(
          id: 'child-shoes',
          categoryCode: 'SHOE',
          categoryName: 'Shoes',
          status: 'ACTIVE',
          sortOrder: 0,
          level: 2,
          hierarchyPath: 'Footwear > Shoes',
          parentCategoryId: 'parent-footwear',
          childCount: 0,
          productCount: 2,
          hasChildren: false,
          children: [],
        ),
      ],
    ),
  ];
}

List<CategoryTreeNode> _sixRootCategories() {
  return [
    for (var index = 1; index <= 6; index++)
      CategoryTreeNode(
        id: 'cat-$index',
        categoryCode: 'C$index',
        categoryName: 'Cat $index',
        status: 'ACTIVE',
        sortOrder: index,
        level: 1,
        hierarchyPath: 'Cat $index',
        childCount: 0,
        productCount: 0,
        hasChildren: false,
        children: const [],
      ),
  ];
}

Widget _wrapListScreen({required List<CategoryTreeNode> tree}) {
  final access = TenantAdminAccessChecker(
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
      featureEntitlements: const [
        TenantAdminFeatureEntitlement(
          featureCode: 'product_catalog',
          featureName: 'product_catalog',
          enabled: true,
        ),
      ],
      permissions: const [
        TenantAdminPermission(
          permissionCode: TenantAdminPermissionCodes.tenantCategoriesView,
          permissionName: TenantAdminPermissionCodes.tenantCategoriesView,
        ),
      ],
      runtimeFlags: const [
        TenantAdminRuntimeFlag(featureCode: 'product_catalog', enabled: true),
      ],
    ),
  );

  return ProviderScope(
    overrides: [
      tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
      categoryListVisibilityProvider.overrideWith(
        (ref) => AsyncData(CategoryListVisibility.resolve(access: access)),
      ),
      categoryTreeProvider.overrideWith((ref) async => tree),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1400,
          height: 900,
          child: CategoryListScreen(),
        ),
      ),
    ),
  );
}
