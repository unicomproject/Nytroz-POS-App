import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:nytroz_pos/core/network/api_endpoints.dart';
import '../../../domain/entities/pos_catalog_models.dart';

class PosCatalogRemoteDatasource {
  const PosCatalogRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<PosCatalogProductSummary>> getProducts({
    required String deviceId,
    String? categoryId,
    String? search,
    String? segment,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posProducts,
      queryParameters: {
        'deviceId': deviceId,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (segment != null && segment.isNotEmpty) 'segment': segment,
      },
    );

    final data = _unwrapList(response.data ?? const {});
    return data
        .map(
          (item) => _mapSummary(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<PosCatalogProductDetail> getProductDetail({
    required String deviceId,
    required String productId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posProductDetail(productId),
      queryParameters: {'deviceId': deviceId},
    );

    return _mapDetail(_unwrapMap(response.data ?? const {}));
  }

  Future<List<PosProductRecommendation>> getRecommendations({
    required String deviceId,
    required String productId,
    String? sourceVariantId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posProductRecommendations(productId),
      queryParameters: {
        'deviceId': deviceId,
        'type': 'frequently-bought-together',
        'limit': 3,
        if (sourceVariantId?.isNotEmpty == true)
          'sourceVariantId': sourceVariantId,
      },
    );
    return _unwrapList(response.data ?? const {})
        .whereType<Map>()
        .take(3)
        .map((item) => _mapRecommendation(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<List<PosCatalogCategory>> getCategories(
      {required String deviceId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posCatalogCategories,
      queryParameters: {'deviceId': deviceId},
    );

    final data = _unwrapList(response.data ?? const {});
    final categories = data
        .map(
          (item) => PosCatalogCategory(
            id: (item as Map)['id']?.toString() ?? '',
            name: item['name']?.toString().trim() ?? '',
          ),
        )
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList(growable: false);

    developer.log(
      'Loaded ${categories.length} POS catalog categories.',
      name: 'pos.catalog',
    );

    return categories;
  }

  List<dynamic> _unwrapList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data;
    }

    return const [];
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }

  PosCatalogProductSummary _mapSummary(Map<String, dynamic> json) {
    final stockStatus = stockStatusFromApi(json['stockStatus']?.toString());
    final availableQty = (json['availableQuantity'] as num?)?.toDouble();

    return PosCatalogProductSummary(
      productId: json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      variantName: json['variantName']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: _resolveImageUrl(json),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString() ?? '',
      basePrice: parsePriceToInt(json['basePrice']),
      hasVariants: json['hasVariants'] == true,
      stockStatus: stockStatus,
      availableQty: availableQty,
      stockLabel:
          stockLabelFromApi(json['stockStatus']?.toString(), availableQty),
      hasOffer: json['hasOffer'] == true,
      offerType: json['offerType']?.toString(),
      offerPolicyId: json['offerPolicyId']?.toString(),
      offerName: json['offerName']?.toString(),
      originalPrice: json['originalPrice'] != null
          ? parsePriceToInt(json['originalPrice'])
          : null,
      sellingPrice: json['sellingPrice'] != null
          ? parsePriceToInt(json['sellingPrice'])
          : null,
      offerPrice: json['offerPrice'] != null
          ? parsePriceToInt(json['offerPrice'])
          : null,
      discountLabel: json['discountLabel']?.toString(),
      requiresCartValidation: json['requiresCartValidation'] == true,
      requiresManagerApproval: json['requiresManagerApproval'] == true,
    );
  }

  PosCatalogProductDetail _mapDetail(Map<String, dynamic> json) {
    final stockStatus = stockStatusFromApi(json['stockStatus']?.toString());
    final availableQty = (json['availableQuantity'] as num?)?.toDouble();
    final summary = PosCatalogProductSummary(
      productId: json['id']?.toString() ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: _resolveImageUrl(json),
      categoryName: json['categoryName']?.toString() ?? '',
      basePrice: parsePriceToInt(json['basePrice']),
      hasVariants: json['hasVariants'] == true,
      stockStatus: stockStatus,
      availableQty: availableQty,
      stockLabel: stockLabelFromApi(
        json['stockStatus']?.toString(),
        availableQty,
      ),
    );

    final variantGroups = (json['variantGroups'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => PosCatalogVariantGroup(
            name: item['name']?.toString() ?? '',
            options: (item['options'] as List? ?? const [])
                .map((option) => option.toString())
                .toList(growable: false),
            optionId: item['optionId']?.toString() ?? '',
            code: item['optionCode']?.toString() ?? '',
            inputType: item['inputType']?.toString() ?? 'CHIP',
            isRequired: item['isRequired'] != false,
            sortOrder: (item['sortOrder'] as num?)?.toInt() ?? 0,
            values: (item['values'] as List? ?? const [])
                .whereType<Map>()
                .map((value) => PosCatalogOptionValue(
                      optionValueId: value['optionValueId']?.toString() ?? '',
                      code: value['valueCode']?.toString() ?? '',
                      displayName: value['displayName']?.toString() ?? '',
                      colorHex: value['colorHex']?.toString(),
                      sortOrder: (value['sortOrder'] as num?)?.toInt() ?? 0,
                    ))
                .toList(growable: false),
          ),
        )
        .where((group) => group.name.isNotEmpty)
        .toList(growable: false);

    final variants = (json['variants'] as List? ?? const [])
        .whereType<Map>()
        .map(_mapVariant)
        .toList(growable: false);

    return PosCatalogProductDetail(
      summary: summary,
      variantGroups: variantGroups,
      variants: variants,
      productCode: json['productCode']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      requiresConfiguration: json['requiresConfiguration'] == true,
    );
  }

  String? _resolveImageUrl(Map<String, dynamic> json) {
    final imageUrl =
        (json['imageUrl'] ?? json['imageStorageKey'])?.toString().trim();
    return imageUrl?.isNotEmpty == true ? imageUrl : null;
  }

  PosCatalogVariant _mapVariant(Map<dynamic, dynamic> json) {
    final attributes = <String, String>{};
    final rawAttributes = json['attributes'];
    if (rawAttributes is Map) {
      for (final entry in rawAttributes.entries) {
        attributes[entry.key.toString()] = entry.value.toString();
      }
    }

    return PosCatalogVariant(
      variantId: json['variantId']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: parsePriceToInt(json['price']),
      stockQty: (json['stockQty'] as num?)?.toDouble(),
      stockStatus: stockStatusFromApi(json['stockStatus']?.toString()),
      attributes: attributes,
      variantCode: json['variantCode']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      selectedOptionValueIds:
          (json['selectedOptionValueIds'] as List? ?? const [])
              .map((value) => value.toString())
              .toList(growable: false),
      isDefault: json['isDefault'] == true,
      isSelectable: json['isSelectable'] != false,
      unavailableReason: json['unavailableReason']?.toString(),
      salesUomId: json['salesUomId']?.toString() ?? '',
      salesUomCode: json['salesUomCode']?.toString() ?? '',
      allowFractionalQuantity: json['allowFractionalQuantity'] == true,
      authoritativePrice: json['authoritativePrice'] == null
          ? null
          : parseDecimal(json['authoritativePrice']),
      currency: json['currency']?.toString() ?? '',
      isStockTracked: json['isStockTracked'] != false,
      imageUrl: _resolveImageUrl(Map<String, dynamic>.from(json)),
    );
  }

  PosProductRecommendation _mapRecommendation(Map<String, dynamic> json) =>
      PosProductRecommendation(
        relationshipId: json['relationshipId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        variantId: json['variantId']?.toString(),
        productName: json['productName']?.toString() ?? '',
        categoryName: json['categoryName']?.toString(),
        variantName: json['variantName']?.toString(),
        imageUrl: _resolveImageUrl(json),
        hasVariants: json['hasVariants'] == true,
        requiresConfiguration: json['requiresConfiguration'] == true,
        price: json['price'] == null ? null : parseDecimal(json['price']),
        currency: json['currency']?.toString() ?? '',
        availableQuantity: json['availableQuantity'] == null
            ? null
            : parseDecimal(json['availableQuantity']),
        stockStatus: stockStatusFromApi(json['stockStatus']?.toString()),
        isSelectable: json['isSelectable'] == true,
        unavailableReason: json['unavailableReason']?.toString(),
      );
}

String formatLkr(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index += 1) {
    final digitsFromEnd = raw.length - index;
    buffer.write(raw[index]);
    if (digitsFromEnd > 1 && digitsFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return 'LKR ${buffer.toString()}.00';
}
