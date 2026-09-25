import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/repositories/brand_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/providers/brand_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/basic_details/basic_details.dart';

const _initialOptions = TenantProductCreateOptions(
  categories: [
    ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
  ],
  subCategories: [],
  brands: [
    ProductBrandOption(id: 'brand-coke', code: 'COKE', name: 'Coca Cola'),
  ],
  units: [],
  taxes: [],
  outlets: [],
  variantOptionTemplates: [],
);

const _refreshedOptions = TenantProductCreateOptions(
  categories: [
    ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
  ],
  subCategories: [],
  brands: [
    ProductBrandOption(id: 'brand-coke', code: 'COKE', name: 'Coca Cola'),
    ProductBrandOption(id: 'brand-new', code: 'ABC_FOODS', name: 'ABC Foods'),
  ],
  units: [],
  taxes: [],
  outlets: [],
  variantOptionTemplates: [],
);

class _FakeProductRepo implements TenantProductRepository {
  int getCreateOptionsCallCount = 0;

  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    // This test pumps Step1BasicDetails directly (no initWizard call), so the
    // only getCreateOptions() call is the refresh triggered by
    // applyQuickAddedBrand after a successful create.
    getCreateOptionsCallCount++;
    return _refreshedOptions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestController extends AddProductWizardController {
  _TestController(TenantProductRepository repo) : super(repo);
}

class _FakeBrandRepository implements BrandRepository {
  bool throwOnCreate = false;

  @override
  Future<Brand> createBrand(BrandUpsertInput input) async {
    if (throwOnCreate) {
      throw Exception('brand.duplicate_code');
    }
    return Brand(
      id: 'brand-new',
      code: input.code,
      name: input.name,
      status: input.status,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TenantAdminAccessChecker _checkerWithCreatePermission() {
  return TenantAdminAccessChecker(
    const TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Test Tenant',
      userId: 'user-test',
      userDisplayName: 'Test User',
      roleNames: ['Tenant Admin'],
      roles: [TenantAdminRoleScope(roleId: 'role-1', roleName: 'Tenant Admin')],
      outletScope: [],
      featureEntitlements: [],
      permissions: [
        TenantAdminPermission(
          permissionCode: 'tenant.brands.create',
          permissionName: 'tenant.brands.create',
        ),
      ],
      runtimeFlags: [],
    ),
  );
}

void main() {
  group('Quick Add Brand', () {
    Future<_TestController> pumpAndOpenDrawer(
      WidgetTester tester, {
      required _FakeProductRepo productRepo,
      required _FakeBrandRepository brandRepo,
    }) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = _TestController(productRepo);
      final state = AddProductWizardState(createOptions: _initialOptions);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider
                .overrideWith((ref) async => _checkerWithCreatePermission()),
            brandRepositoryProvider.overrideWithValue(brandRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1024,
                height: 768,
                child: Step1BasicDetails(
                  state: state,
                  controller: controller,
                  nameController: TextEditingController(),
                  codeController: TextEditingController(),
                  shortDescriptionController: TextEditingController(),
                  longDescriptionController: TextEditingController(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final quickAddButton = find.byKey(const Key('quick_add_brand_button'));
      expect(quickAddButton, findsOneWidget);
      await tester.tap(quickAddButton);
      await tester.pumpAndSettle();

      return controller;
    }

    testWidgets('opens drawer, derives code from name, creates brand, and selects it', (tester) async {
      final productRepo = _FakeProductRepo();
      final brandRepo = _FakeBrandRepository();
      final controller = await pumpAndOpenDrawer(
        tester,
        productRepo: productRepo,
        brandRepo: brandRepo,
      );
      addTearDown(controller.dispose);

      expect(find.text('Quick Add Brand'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('quick_add_brand_name_field')),
        'ABC Foods',
      );
      await tester.pump();

      final codeField = tester.widget<TextField>(
        find.byKey(const Key('quick_add_brand_code_field')),
      );
      expect(codeField.controller!.text, 'ABC_FOODS');

      await tester.tap(find.byKey(const Key('quick_add_brand_save_button')));
      await tester.pumpAndSettle();
      // Flush the wizard controller's debounced auto-save timer (triggered by
      // applyQuickAddedBrand's updateBrand call) so no timer is left pending.
      await tester.pump(const Duration(seconds: 2));

      // Drawer closed
      expect(find.text('Quick Add Brand'), findsNothing);

      // New brand selected as the wizard's final brandId
      expect(controller.state.brandId, 'brand-new');

      // Canonical create-options were refreshed (not a local-only divergent append).
      // The test pumps Step1BasicDetails directly (no initWizard call), so this is
      // the single refresh triggered by applyQuickAddedBrand after creation.
      expect(productRepo.getCreateOptionsCallCount, 1);
      expect(
        controller.state.createOptions?.brands.any((b) => b.id == 'brand-new'),
        isTrue,
      );
    });

    testWidgets('manual code edit is preserved and not overwritten by further name changes', (tester) async {
      final productRepo = _FakeProductRepo();
      final brandRepo = _FakeBrandRepository();
      final controller = await pumpAndOpenDrawer(
        tester,
        productRepo: productRepo,
        brandRepo: brandRepo,
      );
      addTearDown(controller.dispose);

      await tester.enterText(
        find.byKey(const Key('quick_add_brand_name_field')),
        'ABC Foods',
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('quick_add_brand_code_field')),
        'CUSTOM_CODE',
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('quick_add_brand_name_field')),
        'ABC Foods Extended',
      );
      await tester.pump();

      final codeField = tester.widget<TextField>(
        find.byKey(const Key('quick_add_brand_code_field')),
      );
      expect(codeField.controller!.text, 'CUSTOM_CODE');
    });

    testWidgets('shows error and keeps drawer open when create fails', (tester) async {
      final productRepo = _FakeProductRepo();
      final brandRepo = _FakeBrandRepository()..throwOnCreate = true;
      final controller = await pumpAndOpenDrawer(
        tester,
        productRepo: productRepo,
        brandRepo: brandRepo,
      );
      addTearDown(controller.dispose);

      await tester.enterText(
        find.byKey(const Key('quick_add_brand_name_field')),
        'ABC Foods',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('quick_add_brand_save_button')));
      await tester.pumpAndSettle();

      // Drawer remains open; brandId not set
      expect(find.text('Quick Add Brand'), findsOneWidget);
      expect(controller.state.brandId, isNull);
      expect(find.text('Brand code already exists.'), findsOneWidget);
    });
  });
}
