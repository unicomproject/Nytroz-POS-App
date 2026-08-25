import '../entities/step4_variant_configuration_state.dart';

class VariantCombinationGenerator {
  /// Generates the deterministic clientCombinationKey.
  /// Matches backend hash format: opt:<sourceOptionTemplateId>|val:<sourceOptionTemplateValueId>
  /// sorted by sourceOptionTemplateId ascending, joined by semicolon.
  static String generateClientCombinationKey(
      List<SelectedOptionValue> selectedValues,
      List<AttributeConfigRow> allAttributes) {
    // Map each value to its attribute's templateId
    final pairs = <_AttributeValuePair>[];

    for (final value in selectedValues) {
      // Find the attribute that contains this value
      for (final attr in allAttributes) {
        if (attr.templateId != null &&
            attr.selectedValues.any((v) => v.valueId == value.valueId)) {
          pairs.add(_AttributeValuePair(attr.templateId!, value.valueId));
          break;
        }
      }
    }

    // Sort by templateId ascending (guid string order)
    pairs.sort((a, b) => a.templateId.compareTo(b.templateId));

    // Format and join
    return pairs.map((p) => '${p.templateId}:${p.valueId}').join(';');
  }

  /// Generates Cartesian combinations from a list of attributes.
  static List<List<SelectedOptionValue>> generateCartesianMatrix(
      List<AttributeConfigRow> attributes) {
    final validAttributes = attributes.where((a) => a.isValid).toList();
    if (validAttributes.isEmpty) {
      return [];
    }

    List<List<SelectedOptionValue>> result = [[]];
    for (final attr in validAttributes) {
      final currentValues = attr.selectedValues;
      final nextResult = <List<SelectedOptionValue>>[];
      for (final combination in result) {
        for (final value in currentValues) {
          nextResult.add([...combination, value]);
        }
      }
      result = nextResult;
    }
    return result;
  }

  static List<GeneratedVariantRow> reconcileVariants({
    required List<AttributeConfigRow> activeAttributes,
    required List<GeneratedVariantRow> existingVariants,
    required List<DeletedVariantTombstone> deletedVariants,
    required String productName,
  }) {
    final matrix = generateCartesianMatrix(activeAttributes);
    final newRows = <GeneratedVariantRow>[];

    for (final combination in matrix) {
      final key = generateClientCombinationKey(combination, activeAttributes);

      // Skip if explicitly tombstoned/excluded
      if (deletedVariants.any((d) => d.clientCombinationKey == key)) {
        continue;
      }

      // Look for existing state
      final existingIdx =
          existingVariants.indexWhere((v) => v.clientCombinationKey == key);

      if (existingIdx >= 0) {
        // Preserve existing
        newRows.add(existingVariants[existingIdx]);
      } else {
        // Create new
        final combinationLabel =
            combination.map((v) => v.valueName).join(' / ');
        final displayLabel = productName.isNotEmpty
            ? '$productName - $combinationLabel'
            : combinationLabel;

        newRows.add(GeneratedVariantRow(
          clientCombinationKey: key,
          combinationLabel: combinationLabel,
          displayLabel: displayLabel,
          selectedValues: combination,
          isIncluded: true,
        ));
      }
    }

    return newRows;
  }
}

class _AttributeValuePair {
  final String templateId;
  final String valueId;
  _AttributeValuePair(this.templateId, this.valueId);
}
