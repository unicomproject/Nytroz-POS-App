class ReportQuery {
  const ReportQuery({
    this.from,
    this.to,
    this.outletId,
    this.tillId,
    this.cashierId,
    this.customerId,
    this.departmentId,
    this.categoryId,
    this.subcategoryId,
    this.brandId,
    this.productId,
    this.productVariantId,
    this.salesChannelId,
    this.paymentMethodId,
    this.orderStatus,
    this.paymentStatus,
    this.stockStatus,
    this.expiryStatus,
    this.movementType,
    this.batchNumber,
    this.search,
    required this.section,
    this.page = 1,
    this.pageSize = 25,
    this.sortBy,
    this.sortDirection = 'asc',
  });

  final DateTime? from;
  final DateTime? to;
  final String? outletId;
  final String? tillId;
  final String? cashierId;
  final String? customerId;
  final String? departmentId;
  final String? categoryId;
  final String? subcategoryId;
  final String? brandId;
  final String? productId;
  final String? productVariantId;
  final String? salesChannelId;
  final String? paymentMethodId;
  final String? orderStatus;
  final String? paymentStatus;
  final String? stockStatus;
  final String? expiryStatus;
  final String? movementType;
  final String? batchNumber;
  final String? search;
  final String section;
  final int page;
  final int pageSize;
  final String? sortBy;
  final String sortDirection;

  bool get hasActiveFilters =>
      from != null ||
      to != null ||
      _hasValue(outletId) ||
      _hasValue(tillId) ||
      _hasValue(cashierId) ||
      _hasValue(customerId) ||
      _hasValue(departmentId) ||
      _hasValue(categoryId) ||
      _hasValue(subcategoryId) ||
      _hasValue(brandId) ||
      _hasValue(productId) ||
      _hasValue(productVariantId) ||
      _hasValue(salesChannelId) ||
      _hasValue(paymentMethodId) ||
      _hasValue(orderStatus) ||
      _hasValue(paymentStatus) ||
      _hasValue(stockStatus) ||
      _hasValue(expiryStatus) ||
      _hasValue(movementType) ||
      _hasValue(batchNumber) ||
      _hasValue(search);

  String? validate({required bool datesRequired}) {
    if (datesRequired && (from == null || to == null)) {
      return 'From date and to date are required.';
    }
    if (from != null && to != null && from!.isAfter(to!)) {
      return 'From date must not be after to date.';
    }
    if (page < 1) {
      return 'Page must be at least 1.';
    }
    if (!const {25, 50, 100}.contains(pageSize)) {
      return 'Page size must be 25, 50, or 100.';
    }
    if (sortDirection != 'asc' && sortDirection != 'desc') {
      return 'Sort direction must be asc or desc.';
    }
    return null;
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      if (from != null) 'from': _dateOnly(from!),
      if (to != null) 'to': _dateOnly(to!),
      if (_hasValue(outletId)) 'outletId': outletId!.trim(),
      if (_hasValue(tillId)) 'tillId': tillId!.trim(),
      if (_hasValue(cashierId)) 'cashierId': cashierId!.trim(),
      if (_hasValue(customerId)) 'customerId': customerId!.trim(),
      if (_hasValue(departmentId)) 'departmentId': departmentId!.trim(),
      if (_hasValue(categoryId)) 'categoryId': categoryId!.trim(),
      if (_hasValue(subcategoryId)) 'subcategoryId': subcategoryId!.trim(),
      if (_hasValue(brandId)) 'brandId': brandId!.trim(),
      if (_hasValue(productId)) 'productId': productId!.trim(),
      if (_hasValue(productVariantId))
        'productVariantId': productVariantId!.trim(),
      if (_hasValue(salesChannelId)) 'salesChannelId': salesChannelId!.trim(),
      if (_hasValue(paymentMethodId))
        'paymentMethodId': paymentMethodId!.trim(),
      if (_hasValue(orderStatus)) 'orderStatus': orderStatus!.trim(),
      if (_hasValue(paymentStatus)) 'paymentStatus': paymentStatus!.trim(),
      if (_hasValue(stockStatus)) 'stockStatus': stockStatus!.trim(),
      if (_hasValue(expiryStatus)) 'expiryStatus': expiryStatus!.trim(),
      if (_hasValue(movementType)) 'movementType': movementType!.trim(),
      if (_hasValue(batchNumber)) 'batchNumber': batchNumber!.trim(),
      if (_hasValue(search)) 'search': search!.trim(),
      'section': section,
      'page': page,
      'pageSize': pageSize,
      if (_hasValue(sortBy)) 'sortBy': sortBy!.trim(),
      'sortDirection': sortDirection,
    };
  }

  ReportQuery copyWith({
    DateTime? from,
    DateTime? to,
    String? outletId,
    String? tillId,
    String? cashierId,
    String? customerId,
    String? departmentId,
    String? categoryId,
    String? subcategoryId,
    String? brandId,
    String? productId,
    String? productVariantId,
    String? salesChannelId,
    String? paymentMethodId,
    String? orderStatus,
    String? paymentStatus,
    String? stockStatus,
    String? expiryStatus,
    String? movementType,
    String? batchNumber,
    String? search,
    String? section,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearOutlet = false,
    bool clearTill = false,
    bool clearCashier = false,
    bool clearCustomer = false,
    bool clearDepartment = false,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool clearBrand = false,
    bool clearProduct = false,
    bool clearVariant = false,
    bool clearSalesChannel = false,
    bool clearPaymentMethod = false,
    bool clearOrderStatus = false,
    bool clearPaymentStatus = false,
    bool clearStockStatus = false,
    bool clearExpiryStatus = false,
    bool clearMovementType = false,
    bool clearBatchNumber = false,
    bool clearSearch = false,
    bool clearSort = false,
  }) {
    return ReportQuery(
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
      outletId: clearOutlet ? null : outletId ?? this.outletId,
      tillId: clearTill ? null : tillId ?? this.tillId,
      cashierId: clearCashier ? null : cashierId ?? this.cashierId,
      customerId: clearCustomer ? null : customerId ?? this.customerId,
      departmentId: clearDepartment ? null : departmentId ?? this.departmentId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      subcategoryId:
          clearSubcategory ? null : subcategoryId ?? this.subcategoryId,
      brandId: clearBrand ? null : brandId ?? this.brandId,
      productId: clearProduct ? null : productId ?? this.productId,
      productVariantId:
          clearVariant ? null : productVariantId ?? this.productVariantId,
      salesChannelId:
          clearSalesChannel ? null : salesChannelId ?? this.salesChannelId,
      paymentMethodId:
          clearPaymentMethod ? null : paymentMethodId ?? this.paymentMethodId,
      orderStatus: clearOrderStatus ? null : orderStatus ?? this.orderStatus,
      paymentStatus:
          clearPaymentStatus ? null : paymentStatus ?? this.paymentStatus,
      stockStatus: clearStockStatus ? null : stockStatus ?? this.stockStatus,
      expiryStatus:
          clearExpiryStatus ? null : expiryStatus ?? this.expiryStatus,
      movementType:
          clearMovementType ? null : movementType ?? this.movementType,
      batchNumber: clearBatchNumber ? null : batchNumber ?? this.batchNumber,
      search: clearSearch ? null : search ?? this.search,
      section: section ?? this.section,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: clearSort ? null : sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  ReportQuery clearFilters() => ReportQuery(
        section: section,
        pageSize: pageSize,
        sortBy: sortBy,
        sortDirection: sortDirection,
      );
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

String _dateOnly(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
