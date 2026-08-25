import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_1/step_1_basic_details.dart';

void main() {
  Widget buildPage(Size size) {
    final name = TextEditingController();
    final code = TextEditingController();
    final shortDesc = TextEditingController();
    final longDesc = TextEditingController();
    final batch = TextEditingController();
    final serial = TextEditingController();
    final controller = _FakeController();

    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: Step1BasicDetails(
                state: AddProductWizardState(
                  createOptions: const TenantProductCreateOptions(
                    categories: [
                      ProductCategoryOption(
                        id: 'cat-1',
                        code: 'CAT1',
                        name: 'Electronics',
                      ),
                    ],
                    subCategories: [],
                    brands: [
                      ProductBrandOption(
                        id: 'brand-1',
                        code: 'BR1',
                        name: 'Acme',
                      ),
                    ],
                    units: [],
                    taxes: [],
                    outlets: [],
                    variantOptionTemplates: [],
                  ),
                ),
                controller: controller,
                nameController: name,
                codeController: code,
                shortDescriptionController: shortDesc,
                longDescriptionController: longDesc,
                batchController: batch,
                serialController: serial,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Step 1 tablet layout shows half-split cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildPage(const Size(1024, 768)));

    expect(find.text('Product Information'), findsOneWidget);
    expect(find.text('Product Images'), findsOneWidget);
    expect(find.text('Initial Tracking Details'), findsOneWidget);
    expect(find.text('Channel Availability'), findsOneWidget);
    expect(find.text('Product Name *'), findsOneWidget);
    expect(find.text('Category *'), findsOneWidget);
  });
}

class _FakeController extends AddProductWizardController {
  _FakeController() : super(_DummyRepository());

  @override
  Future<void> initWizard({
    String? resumeLocalDraftId,
    String? resumeProductId,
    String? duplicateFromProductId,
  }) async {}
}

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
