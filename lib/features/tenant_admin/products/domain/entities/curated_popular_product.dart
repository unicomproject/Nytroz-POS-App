class CuratedPopularProduct {
  const CuratedPopularProduct({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.status,
    required this.sortOrder,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String status;
  final int sortOrder;

  factory CuratedPopularProduct.fromJson(Map<String, dynamic> json) {
    return CuratedPopularProduct(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString(),
      status: json['status']?.toString() ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
