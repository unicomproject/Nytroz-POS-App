class ProductStatusUpdateRequestDto {
  const ProductStatusUpdateRequestDto({required this.status});

  final String status;

  Map<String, dynamic> toJson() => {'status': status.trim()};
}

class ProductStatusUpdateResponseDto {
  const ProductStatusUpdateResponseDto({
    required this.productId,
    required this.status,
  });

  factory ProductStatusUpdateResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductStatusUpdateResponseDto(
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String productId;
  final String status;
}
