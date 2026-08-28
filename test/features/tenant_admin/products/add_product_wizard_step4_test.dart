import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/add_product_wizard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_4/edit_variant_drawer.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_4/step_4_variant_configuration_form.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';

void main() {
  Widget buildTestWidget(AddProductWizardState initialState) {
    return ProviderScope(
      overrides: [
        addProductWizardControllerProvider.overrideWith((ref) {
          return _FakeAddProductWizardController(initialState);
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1200,
              height: 1000,
              child: AddProductWizard(
                options: const TenantProductCreateOptions(
                  categories: [],
                  subCategories: [],
                  brands: [],
                  units: [],
                  taxes: [],
                  outlets: [],
                  variantOptionTemplates: [],
                ),
                dropdownsEnabled: true,
                canCreate: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AddProductWizard Step 4 UI Matrix Tests', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(1920, 1080);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets(
        'Test 1: Given Product Structure = VARIANT, When Step 4 is opened, Then Variant Configuration is visible',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'VARIANT',
      )));

      expect(find.byType(Step4VariantConfigurationForm), findsOneWidget);
      expect(find.text('Bundle / Kit Composition'), findsNothing);
    });

    testWidgets(
        'Test 2: Given Product Structure = BUNDLE, When Step 4 is opened, Then Bundle / Kit Composition is visible',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'BUNDLE',
      )));

      expect(find.text('Bundle / Kit Composition'), findsOneWidget);
      expect(find.byType(Step4VariantConfigurationForm), findsNothing);
    });

    testWidgets(
        'Test 3: Given a saved VARIANT draft When reopened Then Product Structure restores as VARIANT And Step 4 renders Variant Configuration',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'VARIANT',
      )));

      expect(find.byType(Step4VariantConfigurationForm), findsOneWidget);
    });

    testWidgets(
        'Test 4: Given a saved BUNDLE draft When reopened Then Product Structure restores as BUNDLE And Step 4 renders Bundle / Kit Composition',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'BUNDLE',
      )));

      expect(find.text('Bundle / Kit Composition'), findsOneWidget);
    });

    testWidgets(
        'Test 5: Given VARIANT is changed to BUNDLE When Step 4 is revisited Then stale Variant Configuration is not rendered',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'BUNDLE',
      )));

      expect(find.byType(Step4VariantConfigurationForm), findsNothing);
      expect(find.text('Bundle / Kit Composition'), findsOneWidget);
    });

    testWidgets(
        'Test 6: Given BUNDLE is changed to VARIANT When Step 4 is revisited Then stale Bundle / Kit Composition is not rendered',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'VARIANT',
      )));

      expect(find.text('Bundle / Kit Composition'), findsNothing);
      expect(find.byType(Step4VariantConfigurationForm), findsOneWidget);
    });

    testWidgets(
        'Test 7: Missing/unknown Product Structure must not silently fall back to VARIANT',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        currentStep: 4,
        productStructure: 'UNKNOWN',
      )));

      expect(find.byType(Step4VariantConfigurationForm), findsNothing);
      expect(find.text('Simple Product Configuration'), findsOneWidget);
    });

    testWidgets('Edit Variant opens as a full-height right-side drawer',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(AddProductWizardState(
        currentStep: 4,
        productStructure: 'VARIANT',
        productName: 'shirt',
        step4State: Step4VariantConfigurationState(
          generatedVariants: const [
            GeneratedVariantRow(
              clientCombinationKey: 'color:red',
              combinationLabel: 'Red',
              displayLabel: 'shirt - Red',
              selectedValues: [
                SelectedOptionValue(
                  valueId: 'red',
                  templateId: 'Color',
                  valueName: 'Red',
                ),
              ],
            ),
          ],
        ),
      )));

      await tester.tap(find.byKey(const ValueKey('edit-variant-color:red')));
      await tester.pumpAndSettle();

      expect(find.byType(EditVariantDrawer), findsOneWidget);
      expect(find.text('Edit Variant'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      final align = tester.widget<Align>(find
          .ancestor(
            of: find.byType(EditVariantDrawer),
            matching: find.byType(Align),
          )
          .first);
      expect(align.alignment, Alignment.centerRight);

      final drawerSize = tester.getSize(find.byType(EditVariantDrawer));
      expect(drawerSize.height, tester.view.physicalSize.height);
      expect(drawerSize.width, 420);
    });
  });
}

class _FakeAddProductWizardController extends AddProductWizardController {
  _FakeAddProductWizardController(AddProductWizardState initialState)
      : super(_DummyRepository()) {
    state = initialState.copyWith(
        createOptions: const TenantProductCreateOptions(
      categories: [],
      subCategories: [],
      brands: [],
      units: [],
      taxes: [],
      outlets: [],
      variantOptionTemplates: [],
    ));
  }

  @override
  Future<void> initWizard({
    String? resumeLocalDraftId,
    String? resumeProductId,
    String? duplicateFromProductId,
  }) async {
    // override so it doesn't try to fetch options and overwrite state
  }
}

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
