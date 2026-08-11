import '../../../sale/domain/entities/pos_checkout_summary.dart';

/// Helper mapping utilities for Discount request payloads.
class PosDiscountLineMapper {
  const PosDiscountLineMapper._();

  static List<PosCheckoutLineRequest> linesFromJson(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((raw) {
          final json = Map<String, dynamic>.from(raw);
          return PosCheckoutLineRequest(
            variantId: json['variantId']?.toString() ?? '',
            quantity: (json['qty'] as num?)?.toInt() ?? 0,
            clientLineId: json['clientLineId']?.toString(),
            uomId: json['uomId']?.toString(),
            lineNote: json['lineNote']?.toString(),
            source: json['source']?.toString(),
            recommendationParentProductId:
                json['recommendationParentProductId']?.toString(),
            recommendationRelationshipId:
                json['recommendationRelationshipId']?.toString(),
          );
        })
        .where((line) => line.variantId.isNotEmpty && line.quantity > 0)
        .toList(growable: false);
  }
}
