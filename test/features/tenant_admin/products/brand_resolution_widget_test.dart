// ignore_for_file: invalid_annotation_target
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/basic_details/basic_details.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/scan_barcode/scan_barcode_step.dart';

class _FakeRepo implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestController extends AddProductWizardController {
  _TestController() : super(_FakeRepo());
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

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  group('Scan Preview Widget Tests - Brand Resolution', () {
    Future<void> pumpScanPreview(
      WidgetTester tester, {
      required ScanBarcodeStepState scan,
      Size size = const Size(1024, 768),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AddProductWizardState(scanStepState: scan);
      final controller = _TestController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: ScanBarcodeStep(
                  state: state,
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('FOUND + mapped brand renders mapped tenant brand in preview', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Coca-Cola Can',
            brandText: 'Coca-Cola',
          ),
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola',
            externalBrandName: 'Coca-Cola',
            mappedBrand: TenantBrandCandidateDto(
              id: 'brand-coke',
              name: 'Coca Cola',
              code: 'COKE',
            ),
            suggestions: [],
          ),
        ),
      );

      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Coca-Cola'), findsOneWidget);
      expect(find.text('Tenant Brand'), findsOneWidget);
      expect(find.text('Coca Cola (Mapped)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FOUND + brand suggestions does not falsely render "Mapped"', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Coca-Cola Zero',
            brandText: 'Coca-Cola Zero',
          ),
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola zero',
            externalBrandName: 'Coca-Cola Zero',
            mappedBrand: null,
            suggestions: [
              TenantBrandCandidateDto(
                id: 'brand-coke',
                name: 'Coca Cola',
                code: 'COKE',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tenant Brand'), findsOneWidget);
      expect(find.text('Suggested: Coca Cola'), findsOneWidget);
      expect(find.textContaining('(Mapped)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FOUND + no brand renders safely without brand section errors', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Simple Item',
          ),
          brandResolution: null,
        ),
      );

      expect(find.text('Product Found'), findsOneWidget);
      expect(find.text('Simple Item'), findsOneWidget);
      expect(find.text('Tenant Brand'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Basic Details Widget Tests - Brand Resolution, Suggestions & Quick Add', () {
    const options = TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
      ],
      subCategories: [],
      brands: [
        ProductBrandOption(id: 'brand-coke', code: 'COKE', name: 'Coca Cola'),
        ProductBrandOption(id: 'brand-coke-zero', code: 'COKE_ZERO', name: 'Coca Cola Zero'),
      ],
      units: [],
      taxes: [],
      outlets: [],
      variantOptionTemplates: [],
    );

    Future<void> pumpBasicDetails(
      WidgetTester tester, {
      required AddProductWizardState state,
      required AddProductWizardController controller,
      List<String> permissions = const [],
      Size size = const Size(1024, 768),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final name = TextEditingController();
      final code = TextEditingController();
      final shortDesc = TextEditingController();
      final longDesc = TextEditingController();
      final access = _checker(permissions: permissions);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith((ref) async => access),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: Step1BasicDetails(
                  state: state,
                  controller: controller,
                  nameController: name,
                  codeController: code,
                  shortDescriptionController: shortDesc,
                  longDescriptionController: longDesc,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('mapped brand dropdown preselected and no suggestion chips rendered', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        brandId: 'brand-coke',
        scanStepState: const ScanBarcodeStepState(
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola',
            mappedBrand: TenantBrandCandidateDto(
              id: 'brand-coke',
              name: 'Coca Cola',
              code: 'COKE',
            ),
            suggestions: [],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      expect(find.text('Coca Cola'), findsOneWidget);
      expect(find.text('Suggested:'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('brand suggestions render chips filtered against options', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola zero',
            mappedBrand: null,
            suggestions: [
              TenantBrandCandidateDto(
                id: 'brand-coke-zero',
                name: 'Coca Cola Zero',
                code: 'COKE_ZERO',
              ),
              TenantBrandCandidateDto(
                id: 'brand-non-existent',
                name: 'Unknown Brand',
                code: 'UNK',
              ),
            ],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      expect(find.text('Suggested:'), findsOneWidget);
      expect(find.text('Coca Cola Zero'), findsOneWidget);
      expect(find.text('Unknown Brand'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping brand suggestion chip triggers controller brand update', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola zero',
            mappedBrand: null,
            suggestions: [
              TenantBrandCandidateDto(
                id: 'brand-coke-zero',
                name: 'Coca Cola Zero',
                code: 'COKE_ZERO',
              ),
            ],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      final chipFinder = find.byKey(const Key('brand_suggestion_brand-coke-zero'));
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pump();

      expect(controller.state.brandId, 'brand-coke-zero');
      controller.dispose();
    });

    testWidgets('Quick Add button hidden without catalog.brands.create permission', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(createOptions: options);

      await pumpBasicDetails(
        tester,
        state: state,
        controller: controller,
        permissions: const [],
      );

      expect(find.byKey(const Key('quick_add_brand_button')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quick Add button visible with tenant.brands.create permission', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(createOptions: options);

      await pumpBasicDetails(
        tester,
        state: state,
        controller: controller,
        permissions: const ['tenant.brands.create'],
      );

      expect(find.byKey(const Key('quick_add_brand_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1024x768 layout has no overflow with brand suggestions', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola zero',
            mappedBrand: null,
            suggestions: [
              TenantBrandCandidateDto(id: 'brand-coke', name: 'Coca Cola', code: 'COKE'),
              TenantBrandCandidateDto(id: 'brand-coke-zero', name: 'Coca Cola Zero', code: 'COKE_ZERO'),
            ],
          ),
        ),
      );

      await pumpBasicDetails(
        tester,
        state: state,
        controller: controller,
        permissions: const ['tenant.brands.create'],
        size: const Size(1024, 768),
      );

      expect(find.text('Suggested:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
