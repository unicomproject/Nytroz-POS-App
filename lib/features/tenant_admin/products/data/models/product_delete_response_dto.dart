class ProductDeleteResponseDto {
  const ProductDeleteResponseDto({
    required this.productId,
    required this.outcome,
    required this.status,
  });

  factory ProductDeleteResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductDeleteResponseDto(
      productId:
          json['productId']?.toString() ?? json['id']?.toString() ?? '',
      outcome: json['outcome'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String productId;
  final String outcome;
  final String status;
}
