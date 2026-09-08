import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

void main() {
  group('applyVariantImage scope', () {
    late _FakeRepository repo;
    late AddProductWizardController controller;

    setUp(() {
      repo = _FakeRepository();
      controller = AddProductWizardController(repo);
      controller.state = controller.state.copyWith(
        step4State: Step4VariantConfigurationState(
          generatedVariants: const [
            GeneratedVariantRow(
              clientCombinationKey: 'blue-m',
              combinationLabel: 'Blue / M',
              selectedValues: [
                SelectedOptionValue(valueId: 'blue', valueName: 'Blue'),
                SelectedOptionValue(valueId: 'm', valueName: 'M'),
              ],
            ),
            GeneratedVariantRow(
              clientCombinationKey: 'blue-l',
              combinationLabel: 'Blue / L',
              selectedValues: [
                SelectedOptionValue(valueId: 'blue', valueName: 'Blue'),
                SelectedOptionValue(valueId: 'l', valueName: 'L'),
              ],
            ),
            GeneratedVariantRow(
              clientCombinationKey: 'red-m',
              combinationLabel: 'Red / M',
              selectedValues: [
                SelectedOptionValue(valueId: 'red', valueName: 'Red'),
                SelectedOptionValue(valueId: 'm', valueName: 'M'),
              ],
            ),
          ],
        ),
      );
    });

    test('ONLY_THIS applies image to current variant only', () async {
      final ok = await controller.applyVariantImage(
        variantKey: 'blue-m',
        bytes: [1, 2, 3],
        fileName: 'blue-m.png',
        mimeType: 'image/png',
        applyScope: 'ONLY_THIS',
        groupValueId: 'blue',
      );

      expect(ok, isTrue);
      final variants = controller.state.step4State.generatedVariants;
      expect(variants[0].exactImageMediaAssetId, 'media-1');
      expect(variants[0].effectiveImageUrl, 'https://cdn/test.png');
      expect(variants[1].exactImageMediaAssetId, isNull);
      expect(variants[2].exactImageMediaAssetId, isNull);
    });

    test('ALL_GROUP applies image to all matching color variants', () async {
      final ok = await controller.applyVariantImage(
        variantKey: 'blue-m',
        bytes: [1, 2, 3],
        fileName: 'blue.png',
        mimeType: 'image/png',
        applyScope: 'ALL_GROUP',
        groupValueId: 'blue',
      );

      expect(ok, isTrue);
      final variants = controller.state.step4State.generatedVariants;
      expect(variants[0].exactImageMediaAssetId, 'media-1');
      expect(variants[1].exactImageMediaAssetId, 'media-1');
      expect(variants[2].exactImageMediaAssetId, isNull);
    });
  });
}

class _FakeRepository implements TenantProductRepository {
  @override
  Future<StagedImageResponseDto> stageImage(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    return StagedImageResponseDto(
      mediaAssetId: 'media-1',
      publicUrl: 'https://cdn/test.png',
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
      createdAt: DateTime(2026, 1, 1),
      status: 'READY',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
