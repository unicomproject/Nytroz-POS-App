enum ProductStatusAction {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  draft('INACTIVE', 'Draft');

  const ProductStatusAction(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static List<ProductStatusAction> availableForStatus(String currentStatus) {
    final normalized = currentStatus.trim().toUpperCase();
    return ProductStatusAction.values
        .where((action) => !action.matchesCurrentStatus(normalized))
        .toList(growable: false);
  }

  bool matchesCurrentStatus(String normalizedStatus) {
    return switch (this) {
      ProductStatusAction.active => normalizedStatus == 'ACTIVE',
      ProductStatusAction.inactive => normalizedStatus == 'INACTIVE',
      ProductStatusAction.draft =>
        normalizedStatus == 'DRAFT' || normalizedStatus == 'INACTIVE',
    };
  }

  String confirmationTitle(String productName) {
    return switch (this) {
      ProductStatusAction.active => 'Activate product',
      ProductStatusAction.inactive => 'Deactivate product',
      ProductStatusAction.draft => 'Move product to draft',
    };
  }

  String confirmationMessage(String productName) {
    final name = productName.trim().isEmpty ? 'this product' : '"$productName"';
    return switch (this) {
      ProductStatusAction.active =>
        'Are you sure you want to mark $name as active?',
      ProductStatusAction.inactive =>
        'Are you sure you want to mark $name as inactive?',
      ProductStatusAction.draft =>
        'Are you sure you want to move $name to draft?',
    };
  }

  String successMessage(String productName) {
    final name = productName.trim().isEmpty ? 'Product' : productName;
    return switch (this) {
      ProductStatusAction.active => '$name is now active.',
      ProductStatusAction.inactive => '$name is now inactive.',
      ProductStatusAction.draft => '$name was moved to draft.',
    };
  }
}
