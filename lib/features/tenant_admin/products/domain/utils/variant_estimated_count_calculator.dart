import '../entities/step4_variant_configuration_state.dart';

/// Canonical frontend preview for Step 4 Estimated Variant Count (VARIANT only).
class VariantEstimatedCountCalculator {
  VariantEstimatedCountCalculator._();

  static const int maxVariantCombinationsPerProduct = 100;

  static VariantEstimatedCountResult calculate(
    List<AttributeConfigRow> attributeRows,
  ) {
    final components = <VariantEstimatedCountComponent>[];
    var isComplete = true;

    for (final row in attributeRows) {
      final hasAttribute = row.templateId != null && row.templateId!.isNotEmpty;
      final valueCount = row.selectedValues.length;

      if (!hasAttribute && valueCount == 0) {
        continue;
      }

      if (!hasAttribute || valueCount == 0) {
        isComplete = false;
        continue;
      }

      components.add(
        VariantEstimatedCountComponent(
          attributeName: _displayName(row),
          valueCount: valueCount,
        ),
      );
    }

    if (components.isEmpty) {
      return const VariantEstimatedCountResult(
        count: 0,
        isComplete: false,
        exceedsMaximum: false,
        components: [],
      );
    }

    if (!isComplete) {
      return VariantEstimatedCountResult(
        count: 0,
        isComplete: false,
        exceedsMaximum: false,
        components: components,
      );
    }

    var count = 1;
    var exceedsMaximum = false;
    for (final component in components) {
      count *= component.valueCount;
      if (count > maxVariantCombinationsPerProduct) {
        exceedsMaximum = true;
        break;
      }
    }

    return VariantEstimatedCountResult(
      count: count,
      isComplete: true,
      exceedsMaximum: exceedsMaximum,
      components: components,
    );
  }

  static String formatVariantLabel(int count) =>
      count == 1 ? '1 variant' : '$count variants';

  static String formatFormulaSummary(VariantEstimatedCountResult result) {
    if (!result.isComplete || result.components.isEmpty) {
      return '';
    }

    final parts = result.components
        .map((c) => '${c.attributeName} (${c.valueCount})')
        .join(' × ');
    return '$parts = ${formatVariantLabel(result.count)}';
  }

  static String _displayName(AttributeConfigRow row) {
    final name = row.templateName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Attribute';
  }
}

class VariantEstimatedCountResult {
  final int count;
  final bool isComplete;
  final bool exceedsMaximum;
  final List<VariantEstimatedCountComponent> components;

  const VariantEstimatedCountResult({
    required this.count,
    required this.isComplete,
    required this.exceedsMaximum,
    required this.components,
  });
}

class VariantEstimatedCountComponent {
  final String attributeName;
  final int valueCount;

  const VariantEstimatedCountComponent({
    required this.attributeName,
    required this.valueCount,
  });
}
