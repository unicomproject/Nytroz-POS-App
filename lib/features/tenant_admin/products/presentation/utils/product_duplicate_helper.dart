import '../../domain/entities/tenant_product_detail.dart';

String buildDuplicatedProductName(String sourceName) {
  final trimmed = sourceName.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  if (trimmed.endsWith('(Copy)')) {
    return trimmed;
  }

  return '$trimmed (Copy)';
}

String inferProductStructureFromDetail(TenantProductDetail detail) {
  if (detail.variants.length > 1) {
    return 'VARIANT';
  }

  return 'SIMPLE';
}
