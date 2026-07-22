import 'pos_catalog_models.dart';
import 'pos_resolved_sale_item.dart';

class PosBarcodeLookupResult {
  const PosBarcodeLookupResult({
    required this.productId,
    required this.variantId,
    required this.barcode,
    required this.barcodeType,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.quantityPerScan,
    required this.price,
    required this.availableQuantity,
    required this.stockStatus,
  });

  factory PosBarcodeLookupResult.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantityPerScan'] as num?)?.toDouble();
    if (quantity == null || quantity <= 0 || quantity != quantity.floor()) {
      throw const FormatException('Invalid barcode quantityPerScan.');
    }

    final result = PosBarcodeLookupResult(
      productId: json['productId']?.toString().trim() ?? '',
      variantId: json['variantId']?.toString().trim() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      barcodeType: json['barcodeType']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      quantityPerScan: quantity.toInt(),
      price: parsePriceToInt(json['price']),
      availableQuantity: (json['availableQuantity'] as num?)?.toDouble(),
      stockStatus: stockStatusFromApi(json['stockStatus']?.toString()),
    );
    if (result.productId.isEmpty ||
        result.variantId.isEmpty ||
        result.barcode.isEmpty) {
      throw const FormatException('Invalid exact barcode response.');
    }
    return result;
  }

  final String productId;
  final String variantId;
  final String barcode;
  final String barcodeType;
  final String productName;
  final String variantName;
  final String? sku;
  final int quantityPerScan;
  final int price;
  final double? availableQuantity;
  final String stockStatus;

  PosResolvedSaleItem toResolvedSaleItem() => PosResolvedSaleItem(
        productId: productId,
        variantId: variantId,
        name: productName,
        variantName: variantName,
        category: 'General',
        unitPrice: price,
        sku: sku,
        stockStatus: stockStatus,
        availableQuantity: availableQuantity,
        hasVariants: true,
      );
}
