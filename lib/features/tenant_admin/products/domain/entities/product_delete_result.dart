class ProductDeleteResult {
  const ProductDeleteResult({
    required this.productId,
    required this.outcome,
    required this.status,
  });

  final String productId;
  final String outcome;
  final String status;

  bool get wasArchived => outcome.trim().toLowerCase() == 'archived';
}
