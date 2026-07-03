import '../../domain/entities/product.dart';

class CreateProductRequestDto {
  const CreateProductRequestDto({
    required this.name,
    required this.sku,
    this.categoryName,
    this.brandName,
    this.barcode,
    this.description,
    this.sellingPrice,
    this.trackStock = false,
  });

  factory CreateProductRequestDto.fromForm(ProductFormData form) {
    return CreateProductRequestDto(
      name: form.name.trim(),
      sku: form.sku.trim(),
      categoryName: _cleanOptional(form.categoryName),
      brandName: _cleanOptional(form.brandName),
      barcode: _cleanOptional(form.barcode),
      description: _cleanOptional(form.description),
      sellingPrice: form.sellingPrice,
      trackStock: form.trackStock,
    );
  }

  final String name;
  final String sku;
  final String? categoryName;
  final String? brandName;
  final String? barcode;
  final String? description;
  final double? sellingPrice;
  final bool trackStock;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sku': sku,
      if (categoryName != null) 'categoryName': categoryName,
      if (brandName != null) 'brandName': brandName,
      if (barcode != null) 'barcode': barcode,
      if (description != null) 'description': description,
      if (sellingPrice != null) 'sellingPrice': sellingPrice,
      'trackStock': trackStock,
    };
  }
}

String? _cleanOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}
