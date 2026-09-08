import '../../data/models/step6_pricing_tax_dtos.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/step4_variant_configuration_state.dart';

/// View-model row for VARIANT Step 6 pricing table.
class VariantPricingRowView {
  final String identityKey;
  final String? productVariantId;
  final String clientCombinationKey;
  final String displayLabel;
  final String? sku;
  final num? sellingPrice;

  const VariantPricingRowView({
    required this.identityKey,
    required this.clientCombinationKey,
    required this.displayLabel,
    this.productVariantId,
    this.sku,
    this.sellingPrice,
  });

  bool get isPriced => sellingPrice != null && sellingPrice! > 0;
}

class VariantPricingDerivedStatus {
  final int total;
  final int priced;
  final int pending;
  final num? priceFrom;
  final num? priceTo;

  const VariantPricingDerivedStatus({
    required this.total,
    required this.priced,
    required this.pending,
    this.priceFrom,
    this.priceTo,
  });

  String priceRangeLabel(String currencyCode) {
    final code = currencyCode.trim().toUpperCase();
    final prefix = code.isEmpty ? '' : '$code ';
    if (priced == 0 || priceFrom == null) return '—';
    if (priceTo == null || priceFrom == priceTo) {
      return '$prefix${_fmt(priceFrom!)}';
    }
    return '$prefix${_fmt(priceFrom!)} – $prefix${_fmt(priceTo!)}';
  }

  static String _fmt(num value) => value.toStringAsFixed(2);
}

/// Reconcile stored prices with current included Step 4 variants.
List<VariantPriceDto> reconcileVariantPricesWithIncluded({
  required List<GeneratedVariantRow> includedVariants,
  required List<VariantPriceDto> existingPrices,
}) {
  final byId = <String, VariantPriceDto>{};
  final byKey = <String, VariantPriceDto>{};
  for (final p in existingPrices) {
    final id = p.productVariantId?.trim();
    if (id != null && id.isNotEmpty) {
      byId[id] = p;
    }
    final key = p.clientCombinationKey?.trim();
    if (key != null && key.isNotEmpty) {
      byKey[key] = p;
    }
  }

  final next = <VariantPriceDto>[];
  for (final v in includedVariants) {
    final id = v.productVariantId?.trim();
    VariantPriceDto? match;
    if (id != null && id.isNotEmpty) {
      match = byId[id];
    }
    match ??= byKey[v.clientCombinationKey];

    next.add(
      VariantPriceDto(
        productVariantId: id?.isNotEmpty == true ? id : null,
        clientCombinationKey: v.clientCombinationKey,
        sellingPrice: match?.sellingPrice,
        displayName: v.displayLabel?.trim().isNotEmpty == true
            ? v.displayLabel
            : v.combinationLabel,
      ),
    );
  }
  return next;
}

List<VariantPricingRowView> buildVariantPricingRows({
  required AddProductWizardState state,
}) {
  final included =
      state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
  final skuByKey = <String, String?>{
    for (final a in state.step5State.assignments) a.clientCombinationKey: a.sku,
  };
  final priceById = <String, VariantPriceDto>{};
  final priceByClientKey = <String, VariantPriceDto>{};
  for (final p in state.variantPrices) {
    final id = p.productVariantId?.trim();
    if (id != null && id.isNotEmpty) {
      priceById[id] = p;
    }
    final key = p.clientCombinationKey?.trim();
    if (key != null && key.isNotEmpty) {
      priceByClientKey[key] = p;
    }
  }

  return included.map((v) {
    final id = v.productVariantId?.trim();
    final identity = (id != null && id.isNotEmpty)
        ? 'id:$id'
        : 'key:${v.clientCombinationKey}';
    final stored = (id != null && id.isNotEmpty ? priceById[id] : null) ??
        priceByClientKey[v.clientCombinationKey];

    final label = (v.displayLabel?.trim().isNotEmpty == true)
        ? v.displayLabel!.trim()
        : v.combinationLabel;

    return VariantPricingRowView(
      identityKey: identity,
      productVariantId: id?.isNotEmpty == true ? id : null,
      clientCombinationKey: v.clientCombinationKey,
      displayLabel: label,
      sku: skuByKey[v.clientCombinationKey] ?? stored?.sku,
      sellingPrice: stored?.sellingPrice,
    );
  }).toList();
}

VariantPricingDerivedStatus deriveVariantPricingStatus(
  Iterable<VariantPricingRowView> rows,
) {
  final list = rows.toList();
  final pricedRows = list.where((r) => r.isPriced).toList();
  num? from;
  num? to;
  for (final r in pricedRows) {
    final p = r.sellingPrice!;
    from = from == null ? p : (p < from ? p : from);
    to = to == null ? p : (p > to ? p : to);
  }
  return VariantPricingDerivedStatus(
    total: list.length,
    priced: pricedRows.length,
    pending: list.length - pricedRows.length,
    priceFrom: from,
    priceTo: to,
  );
}

/// Full-snapshot list for API (includes null sellingPrice for PENDING).
List<VariantPriceDto> buildVariantPriceSnapshot(
  AddProductWizardState state,
) {
  final rows = buildVariantPricingRows(state: state);
  return rows
      .map(
        (r) => VariantPriceDto(
          productVariantId: r.productVariantId,
          clientCombinationKey: r.clientCombinationKey,
          sellingPrice: r.sellingPrice,
          displayName: r.displayLabel,
          sku: r.sku,
        ),
      )
      .toList();
}

final _variantPriceIndexField = RegExp(
  r'variantPrices\[(\d+)\]',
  caseSensitive: false,
);

/// Maps backend `pricingTax.variantPrices[n].sellingPrice` onto the row
/// submitted at that snapshot index (not the current visible table order).
Map<String, String> mapVariantPriceServerFieldErrors({
  required List<VariantPriceDto> submittedSnapshot,
  required Object? errorBody,
}) {
  final mapped = <String, String>{};
  if (errorBody is! Map) return mapped;
  final details = errorBody['details'] ?? errorBody['errors'];
  if (details is! List) return mapped;

  for (final item in details) {
    if (item is! Map) continue;
    final field = (item['field'] ?? item['path'] ?? item['name'])?.toString();
    final message = (item['message'] ?? item['error'])?.toString();
    if (field == null || message == null || message.isEmpty) continue;
    final match = _variantPriceIndexField.firstMatch(field);
    if (match == null) continue;
    final index = int.tryParse(match.group(1) ?? '');
    if (index == null || index < 0 || index >= submittedSnapshot.length) {
      mapped['variantPrices'] = message;
      continue;
    }
    final row = submittedSnapshot[index];
    mapped['variantPrice:${row.identityKey}'] = message;
    mapped['variantPrices'] = message;
  }
  return mapped;
}
