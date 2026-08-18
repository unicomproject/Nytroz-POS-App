import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_5/step_5_barcode_sku_form.dart';

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
      ),
    );
  }

  @override
  Future<void> initWizard(
      {String? resumeLocalDraftId, String? resumeProductId}) async {
    // override so it doesn't fetch options
  }
}

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Step 5 form renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(productStructure: 'SIMPLE'));
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Step5BarcodeSkuForm(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI components exist
    expect(find.text('Barcode & SKU'), findsOneWidget);
    expect(find.text('Base SKU *'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Parent Product Barcode'), findsOneWidget);
  });
}
