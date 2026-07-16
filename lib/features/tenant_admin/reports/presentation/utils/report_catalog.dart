import '../../data/constants/report_api_paths.dart';

class ReportTabSpec {
  const ReportTabSpec({
    required this.key,
    required this.label,
    required this.columns,
  });

  final String key;
  final String label;
  final List<ReportColumnSpec> columns;
}

class ReportColumnSpec {
  const ReportColumnSpec({
    required this.key,
    required this.label,
    this.primary = false,
    this.financial = false,
    this.status = false,
    this.sensitive = false,
  });

  final String key;
  final String label;
  final bool primary;
  final bool financial;
  final bool status;
  final bool sensitive;
}

abstract final class ReportCatalog {
  static const salesTabs = [
    ReportTabSpec(
      key: ReportSections.salesSummary,
      label: 'Sales Summary',
      columns: [],
    ),
    ReportTabSpec(
      key: ReportSections.transactions,
      label: 'Transactions',
      columns: transactionColumns,
    ),
    ReportTabSpec(
      key: ReportSections.products,
      label: 'Product Sales',
      columns: productSalesColumns,
    ),
    ReportTabSpec(
      key: ReportSections.categories,
      label: 'Category Sales',
      columns: categorySalesColumns,
    ),
    ReportTabSpec(
      key: ReportSections.payments,
      label: 'Payments',
      columns: paymentColumns,
    ),
    ReportTabSpec(
      key: ReportSections.tax,
      label: 'Tax',
      columns: taxColumns,
    ),
    ReportTabSpec(
      key: ReportSections.discounts,
      label: 'Discounts',
      columns: discountColumns,
    ),
    ReportTabSpec(
      key: ReportSections.returns,
      label: 'Returns & Refunds',
      columns: returnColumns,
    ),
    ReportTabSpec(
      key: ReportSections.cashiers,
      label: 'Cashier Performance',
      columns: cashierColumns,
    ),
    ReportTabSpec(
      key: ReportSections.daily,
      label: 'Daily Sales Snapshot',
      columns: dailyColumns,
    ),
  ];

  static const stockTabs = [
    ReportTabSpec(
      key: ReportSections.currentStock,
      label: 'Current Stock',
      columns: currentStockColumns,
    ),
    ReportTabSpec(
      key: ReportSections.lowStock,
      label: 'Low Stock',
      columns: lowStockColumns,
    ),
    ReportTabSpec(
      key: ReportSections.outOfStock,
      label: 'Out of Stock',
      columns: outOfStockColumns,
    ),
    ReportTabSpec(
      key: ReportSections.batchExpiry,
      label: 'Batch & Expiry',
      columns: batchExpiryColumns,
    ),
    ReportTabSpec(
      key: ReportSections.movements,
      label: 'Stock Movements',
      columns: movementColumns,
    ),
    ReportTabSpec(
      key: ReportSections.valuation,
      label: 'Inventory Valuation',
      columns: valuationColumns,
    ),
  ];

  static const outletTabs = [
    ReportTabSpec(
      key: ReportSections.outletPerformance,
      label: 'Outlet Performance',
      columns: outletPerformanceColumns,
    ),
    ReportTabSpec(
      key: ReportSections.tillSummary,
      label: 'Till Summary',
      columns: tillSummaryColumns,
    ),
    ReportTabSpec(
      key: ReportSections.cashiers,
      label: 'Cashier Performance',
      columns: cashierColumns,
    ),
  ];

  static const transactionColumns = [
    ReportColumnSpec(key: 'completedAt', label: 'Date & Time'),
    ReportColumnSpec(
      key: 'orderNumber',
      label: 'Invoice / Order',
      primary: true,
    ),
    ReportColumnSpec(key: 'salesChannelName', label: 'Sales Channel'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet', primary: true),
    ReportColumnSpec(key: 'tillName', label: 'Till'),
    ReportColumnSpec(key: 'cashierName', label: 'Cashier'),
    ReportColumnSpec(key: 'customerName', label: 'Customer', sensitive: true),
    ReportColumnSpec(key: 'lineCount', label: 'Item Count'),
    ReportColumnSpec(key: 'totalQuantity', label: 'Total Quantity'),
    ReportColumnSpec(key: 'subtotalAmount', label: 'Subtotal', financial: true),
    ReportColumnSpec(key: 'discountAmount', label: 'Discount', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(key: 'chargeAmount', label: 'Charges', financial: true),
    ReportColumnSpec(key: 'roundingAmount', label: 'Rounding', financial: true),
    ReportColumnSpec(key: 'totalAmount', label: 'Total', financial: true),
    ReportColumnSpec(key: 'paidAmount', label: 'Paid', financial: true),
    ReportColumnSpec(key: 'refundedAmount', label: 'Refunded', financial: true),
    ReportColumnSpec(key: 'netAmount', label: 'Net', financial: true),
    ReportColumnSpec(key: 'paymentMethodNames', label: 'Payment Methods'),
    ReportColumnSpec(
        key: 'paymentStatus', label: 'Payment Status', status: true),
    ReportColumnSpec(
      key: 'fulfilmentStatus',
      label: 'Fulfilment Status',
      status: true,
    ),
    ReportColumnSpec(key: 'orderStatus', label: 'Order Status', status: true),
  ];

  static const productSalesColumns = [
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'sku', label: 'SKU'),
    ReportColumnSpec(key: 'barcode', label: 'Barcode'),
    ReportColumnSpec(key: 'brandName', label: 'Brand'),
    ReportColumnSpec(key: 'departmentName', label: 'Department'),
    ReportColumnSpec(key: 'categoryName', label: 'Category'),
    ReportColumnSpec(key: 'subcategoryName', label: 'Subcategory'),
    ReportColumnSpec(key: 'quantitySold', label: 'Quantity Sold'),
    ReportColumnSpec(key: 'quantityReturned', label: 'Quantity Returned'),
    ReportColumnSpec(key: 'netQuantity', label: 'Net Quantity'),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(key: 'discountAmount', label: 'Discount', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refund', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(
      key: 'averageSellingPrice',
      label: 'Average Selling Price',
      financial: true,
    ),
  ];

  static const categorySalesColumns = [
    ReportColumnSpec(key: 'departmentName', label: 'Department'),
    ReportColumnSpec(key: 'categoryName', label: 'Category', primary: true),
    ReportColumnSpec(key: 'subcategoryName', label: 'Subcategory'),
    ReportColumnSpec(key: 'quantitySold', label: 'Quantity Sold'),
    ReportColumnSpec(key: 'quantityReturned', label: 'Quantity Returned'),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(key: 'discountAmount', label: 'Discount', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refund', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(key: 'percentageOfTotal', label: '% of Total Sales'),
  ];

  static const paymentColumns = [
    ReportColumnSpec(
      key: 'paymentMethodName',
      label: 'Payment Method',
      primary: true,
    ),
    ReportColumnSpec(key: 'paymentType', label: 'Payment Type'),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(
        key: 'requestedAmount', label: 'Requested', financial: true),
    ReportColumnSpec(key: 'tenderedAmount', label: 'Tendered', financial: true),
    ReportColumnSpec(key: 'paidAmount', label: 'Paid', financial: true),
    ReportColumnSpec(key: 'changeAmount', label: 'Change', financial: true),
    ReportColumnSpec(key: 'refundedAmount', label: 'Refunded', financial: true),
    ReportColumnSpec(
        key: 'netCollectedAmount', label: 'Net Collected', financial: true),
    ReportColumnSpec(key: 'percentage', label: 'Percentage'),
  ];

  static const taxColumns = [
    ReportColumnSpec(key: 'taxClassName', label: 'Tax Class', primary: true),
    ReportColumnSpec(key: 'taxName', label: 'Tax Name'),
    ReportColumnSpec(key: 'taxCode', label: 'Tax Code'),
    ReportColumnSpec(key: 'taxRate', label: 'Tax Rate'),
    ReportColumnSpec(
        key: 'taxableAmount', label: 'Taxable Amount', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax Amount', financial: true),
    ReportColumnSpec(
        key: 'refundedTaxAmount', label: 'Refunded Tax', financial: true),
    ReportColumnSpec(key: 'netTaxAmount', label: 'Net Tax', financial: true),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
  ];

  static const discountColumns = [
    ReportColumnSpec(
        key: 'discountName', label: 'Discount Policy', primary: true),
    ReportColumnSpec(key: 'discountCode', label: 'Discount Code'),
    ReportColumnSpec(key: 'discountType', label: 'Discount Type'),
    ReportColumnSpec(key: 'discountScope', label: 'Discount Scope'),
    ReportColumnSpec(key: 'usageCount', label: 'Usage Count'),
    ReportColumnSpec(
        key: 'discountAmount', label: 'Discount Amount', financial: true),
    ReportColumnSpec(
      key: 'averageDiscountAmount',
      label: 'Average Discount',
      financial: true,
    ),
    ReportColumnSpec(key: 'manualDiscountCount', label: 'Manual Count'),
    ReportColumnSpec(key: 'managerApprovalCount', label: 'Manager Approvals'),
    ReportColumnSpec(
      key: 'netSalesAfterDiscount',
      label: 'Net Sales After Discount',
      financial: true,
    ),
  ];

  static const returnColumns = [
    ReportColumnSpec(
        key: 'returnNumber', label: 'Return Number', primary: true),
    ReportColumnSpec(key: 'originalOrderNumber', label: 'Original Order'),
    ReportColumnSpec(key: 'requestedAt', label: 'Requested Date'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'customerName', label: 'Customer', sensitive: true),
    ReportColumnSpec(key: 'returnChannel', label: 'Return Channel'),
    ReportColumnSpec(key: 'returnReasonName', label: 'Reason'),
    ReportColumnSpec(key: 'requestedQuantity', label: 'Requested Quantity'),
    ReportColumnSpec(key: 'receivedQuantity', label: 'Received Quantity'),
    ReportColumnSpec(key: 'approvedQuantity', label: 'Approved Quantity'),
    ReportColumnSpec(
        key: 'requestedAmount', label: 'Requested Amount', financial: true),
    ReportColumnSpec(
        key: 'approvedAmount', label: 'Approved Amount', financial: true),
    ReportColumnSpec(
        key: 'refundedAmount', label: 'Refunded Amount', financial: true),
    ReportColumnSpec(key: 'returnStatus', label: 'Return Status', status: true),
    ReportColumnSpec(key: 'refundStatus', label: 'Refund Status', status: true),
    ReportColumnSpec(key: 'completedAt', label: 'Completed Date'),
  ];

  static const cashierColumns = [
    ReportColumnSpec(key: 'cashierName', label: 'Cashier', primary: true),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(key: 'itemQuantitySold', label: 'Items Sold'),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(
        key: 'discountAmount', label: 'Discounts', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refunds', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(
        key: 'averageOrderValue', label: 'Average Order', financial: true),
    ReportColumnSpec(
        key: 'averageItemsPerOrder', label: 'Average Items / Order'),
    ReportColumnSpec(key: 'voidCount', label: 'Void Count'),
    ReportColumnSpec(key: 'returnCount', label: 'Return Count'),
    ReportColumnSpec(
        key: 'cashDifference', label: 'Cash Difference', financial: true),
  ];

  static const dailyColumns = [
    ReportColumnSpec(
        key: 'businessDate', label: 'Business Date', primary: true),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(
        key: 'discountAmount', label: 'Discounts', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refunds', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(
      key: 'totalCollectedAmount',
      label: 'Total Collected',
      financial: true,
    ),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(
        key: 'averageOrderValue', label: 'Average Order', financial: true),
  ];

  static const currentStockColumns = [
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'inventoryLocationName', label: 'Location'),
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'sku', label: 'SKU'),
    ReportColumnSpec(key: 'barcode', label: 'Barcode'),
    ReportColumnSpec(key: 'batchNumber', label: 'Batch'),
    ReportColumnSpec(key: 'expiryDate', label: 'Expiry Date'),
    ReportColumnSpec(key: 'onHandQuantity', label: 'On Hand'),
    ReportColumnSpec(key: 'reservedQuantity', label: 'Reserved'),
    ReportColumnSpec(key: 'damagedQuantity', label: 'Damaged'),
    ReportColumnSpec(key: 'quarantineQuantity', label: 'Quarantine'),
    ReportColumnSpec(key: 'availableQuantity', label: 'Available'),
    ReportColumnSpec(key: 'reorderPoint', label: 'Reorder Point'),
    ReportColumnSpec(key: 'reorderQuantity', label: 'Reorder Quantity'),
    ReportColumnSpec(
        key: 'unitCost', label: 'Unit Cost', financial: true, sensitive: true),
    ReportColumnSpec(
        key: 'stockValue',
        label: 'Stock Value',
        financial: true,
        sensitive: true),
    ReportColumnSpec(key: 'stockStatus', label: 'Stock Status', status: true),
    ReportColumnSpec(key: 'expiryStatus', label: 'Expiry Status', status: true),
    ReportColumnSpec(key: 'lastMovementAt', label: 'Last Movement'),
  ];

  static const lowStockColumns = [
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'sku', label: 'SKU'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'availableQuantity', label: 'Available'),
    ReportColumnSpec(key: 'reorderPoint', label: 'Reorder Point'),
    ReportColumnSpec(key: 'reorderQuantity', label: 'Reorder Quantity'),
    ReportColumnSpec(key: 'safetyStock', label: 'Safety Stock'),
    ReportColumnSpec(key: 'shortageQuantity', label: 'Shortage'),
    ReportColumnSpec(key: 'lastMovementAt', label: 'Last Movement'),
    ReportColumnSpec(key: 'status', label: 'Status', status: true),
  ];

  static const outOfStockColumns = [
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'sku', label: 'SKU'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'availableQuantity', label: 'Available'),
    ReportColumnSpec(key: 'reorderPoint', label: 'Reorder Point'),
    ReportColumnSpec(key: 'lastInStockAt', label: 'Last In Stock'),
    ReportColumnSpec(key: 'lastMovementAt', label: 'Last Movement'),
    ReportColumnSpec(key: 'status', label: 'Status', status: true),
  ];

  static const batchExpiryColumns = [
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'batchNumber', label: 'Batch'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'inventoryLocationName', label: 'Location'),
    ReportColumnSpec(key: 'manufacturedDate', label: 'Manufactured'),
    ReportColumnSpec(key: 'firstReceivedAt', label: 'First Received'),
    ReportColumnSpec(key: 'expiryDate', label: 'Expiry Date'),
    ReportColumnSpec(key: 'daysUntilExpiry', label: 'Days Until Expiry'),
    ReportColumnSpec(key: 'onHandQuantity', label: 'On Hand'),
    ReportColumnSpec(key: 'availableQuantity', label: 'Available'),
    ReportColumnSpec(key: 'batchStatus', label: 'Batch Status', status: true),
    ReportColumnSpec(key: 'expiryStatus', label: 'Expiry Status', status: true),
  ];

  static const movementColumns = [
    ReportColumnSpec(key: 'occurredAt', label: 'Movement Date', primary: true),
    ReportColumnSpec(key: 'movementNumber', label: 'Movement Number'),
    ReportColumnSpec(key: 'productName', label: 'Product'),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'inventoryLocationName', label: 'Location'),
    ReportColumnSpec(key: 'batchNumber', label: 'Batch'),
    ReportColumnSpec(key: 'movementType', label: 'Movement Type', status: true),
    ReportColumnSpec(key: 'quantityBefore', label: 'Quantity Before'),
    ReportColumnSpec(key: 'quantityChanged', label: 'Quantity Changed'),
    ReportColumnSpec(key: 'quantityAfter', label: 'Quantity After'),
    ReportColumnSpec(
        key: 'unitCost', label: 'Unit Cost', financial: true, sensitive: true),
    ReportColumnSpec(
        key: 'totalCost',
        label: 'Total Cost',
        financial: true,
        sensitive: true),
    ReportColumnSpec(key: 'referenceType', label: 'Reference Type'),
    ReportColumnSpec(key: 'referenceNumber', label: 'Reference Number'),
    ReportColumnSpec(key: 'reason', label: 'Reason'),
    ReportColumnSpec(key: 'notes', label: 'Notes'),
    ReportColumnSpec(key: 'performedByName', label: 'Performed By'),
  ];

  static const valuationColumns = [
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'inventoryLocationName', label: 'Location'),
    ReportColumnSpec(key: 'onHandQuantity', label: 'On Hand'),
    ReportColumnSpec(key: 'availableQuantity', label: 'Available'),
    ReportColumnSpec(key: 'costingMethod', label: 'Costing Method'),
    ReportColumnSpec(
        key: 'remainingCostLayerQuantity', label: 'Remaining Cost Layers'),
    ReportColumnSpec(
        key: 'averageUnitCost', label: 'Average Unit Cost', financial: true),
    ReportColumnSpec(
      key: 'totalInventoryValue',
      label: 'Total Inventory Value',
      financial: true,
    ),
  ];

  static const outletPerformanceColumns = [
    ReportColumnSpec(key: 'outletName', label: 'Outlet', primary: true),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(key: 'transactionCount', label: 'Transactions'),
    ReportColumnSpec(
        key: 'averageOrderValue', label: 'Average Order', financial: true),
    ReportColumnSpec(
        key: 'discountAmount', label: 'Discounts', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refunds', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(
        key: 'cashSalesAmount', label: 'Cash Sales', financial: true),
    ReportColumnSpec(
        key: 'cardSalesAmount', label: 'Card Sales', financial: true),
    ReportColumnSpec(key: 'qrSalesAmount', label: 'QR Sales', financial: true),
    ReportColumnSpec(
        key: 'stockValue',
        label: 'Stock Value',
        financial: true,
        sensitive: true),
    ReportColumnSpec(key: 'lowStockItemCount', label: 'Low-stock Items'),
    ReportColumnSpec(key: 'outOfStockItemCount', label: 'Out-of-stock Items'),
    ReportColumnSpec(
        key: 'performancePercentageChange', label: 'Performance Change'),
  ];

  static const tillSummaryColumns = [
    ReportColumnSpec(
        key: 'sessionNumber', label: 'Session Number', primary: true),
    ReportColumnSpec(key: 'businessDate', label: 'Business Date'),
    ReportColumnSpec(key: 'outletName', label: 'Outlet'),
    ReportColumnSpec(key: 'tillName', label: 'Till'),
    ReportColumnSpec(key: 'cashierName', label: 'Cashier'),
    ReportColumnSpec(key: 'openedAt', label: 'Opened At'),
    ReportColumnSpec(key: 'closedAt', label: 'Closed At'),
    ReportColumnSpec(
        key: 'openingCashAmount', label: 'Opening Cash', financial: true),
    ReportColumnSpec(key: 'cashInAmount', label: 'Cash In', financial: true),
    ReportColumnSpec(
        key: 'cashDropAmount', label: 'Cash Drop', financial: true),
    ReportColumnSpec(
        key: 'expectedCashAmount', label: 'Expected Cash', financial: true),
    ReportColumnSpec(
        key: 'countedCashAmount', label: 'Counted Cash', financial: true),
    ReportColumnSpec(
        key: 'cashDifference', label: 'Cash Difference', financial: true),
    ReportColumnSpec(
        key: 'grossSalesAmount', label: 'Gross Sales', financial: true),
    ReportColumnSpec(
        key: 'discountAmount', label: 'Discounts', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(
        key: 'netSalesAmount', label: 'Net Sales', financial: true),
    ReportColumnSpec(key: 'refundAmount', label: 'Refunds', financial: true),
    ReportColumnSpec(key: 'voidCount', label: 'Voids'),
    ReportColumnSpec(key: 'orderCount', label: 'Orders'),
    ReportColumnSpec(
        key: 'sessionStatus', label: 'Session Status', status: true),
    ReportColumnSpec(
        key: 'approvalStatus', label: 'Approval Status', status: true),
  ];
}
