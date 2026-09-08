import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/utils/variant_estimated_count_calculator.dart';

void main() {
  AttributeConfigRow row(String name, List<String> values) {
    return AttributeConfigRow(
      templateId: name,
      templateName: name,
      selectedValues: values
          .map((v) => SelectedOptionValue(valueId: v, valueName: v))
          .toList(),
    );
  }

  group('VariantEstimatedCountCalculator', () {
    test('Case 1: Colour = 3 => 3 variants', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue', 'Black']),
      ]);

      expect(result.count, 3);
      expect(result.isComplete, isTrue);
      expect(result.exceedsMaximum, isFalse);
    });

    test('Case 2: Colour = 3, Capacity = 2 => 6 variants', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue', 'Black']),
        row('Capacity', ['128GB', '256GB']),
      ]);

      expect(result.count, 6);
      expect(
        VariantEstimatedCountCalculator.formatFormulaSummary(result),
        'Colour (3) × Capacity (2) = 6 variants',
      );
    });

    test('Case 3: Size = 4, Colour = 3, Material = 2 => 24 variants', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Size', ['S', 'M', 'L', 'XL']),
        row('Colour', ['Red', 'Blue', 'Black']),
        row('Material', ['Cotton', 'Poly']),
      ]);

      expect(result.count, 24);
    });

    test('Case 4: single value => 1 variant', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red']),
      ]);

      expect(result.count, 1);
      expect(
        VariantEstimatedCountCalculator.formatVariantLabel(result.count),
        '1 variant',
      );
    });

    test('Case 5: 10 x 10 = 100 valid', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('A', List.generate(10, (i) => 'A$i')),
        row('B', List.generate(10, (i) => 'B$i')),
      ]);

      expect(result.count, 100);
      expect(result.exceedsMaximum, isFalse);
    });

    test('Case 6: 10 x 11 = 110 exceeds maximum', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('A', List.generate(10, (i) => 'A$i')),
        row('B', List.generate(11, (i) => 'B$i')),
      ]);

      expect(result.exceedsMaximum, isTrue);
    });

    test('Case 7: attribute with zero values is incomplete', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Colour', []),
      ]);

      expect(result.isComplete, isFalse);
      expect(result.count, 0);
    });

    test('Case 8: remove value updates count 3x2 to 2x2', () {
      final before = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue', 'Black']),
        row('Capacity', ['128GB', '256GB']),
      ]);
      final after = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue']),
        row('Capacity', ['128GB', '256GB']),
      ]);

      expect(before.count, 6);
      expect(after.count, 4);
    });

    test('Case 9: remove attribute updates 3x2 to 3', () {
      final before = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue', 'Black']),
        row('Capacity', ['128GB', '256GB']),
      ]);
      final after = VariantEstimatedCountCalculator.calculate([
        row('Colour', ['Red', 'Blue', 'Black']),
      ]);

      expect(before.count, 6);
      expect(after.count, 3);
    });

    test('Case 10: empty configuration is incomplete with zero count', () {
      final result = VariantEstimatedCountCalculator.calculate([]);

      expect(result.count, 0);
      expect(result.isComplete, isFalse);
    });

    test('dynamic formula summary for Size and Material', () {
      final result = VariantEstimatedCountCalculator.calculate([
        row('Size', ['S', 'M', 'L', 'XL']),
        row('Material', ['Cotton', 'Poly']),
      ]);

      expect(
        VariantEstimatedCountCalculator.formatFormulaSummary(result),
        'Size (4) × Material (2) = 8 variants',
      );
    });
  });
}
