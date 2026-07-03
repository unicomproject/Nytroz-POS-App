import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../domain/entities/product.dart';
import 'product_api_capabilities.dart';
import 'product_permission_config.dart';

enum ProductRowActionId {
  edit,
  delete,
}

class ProductRowActionConfig extends ProductWidgetPermissionConfig {
  const ProductRowActionConfig({
    required super.id,
    required this.actionId,
    required this.label,
    required this.icon,
    super.permission,
    super.permissionsAny = const [],
    super.showInMoreMenu = false,
  });

  final ProductRowActionId actionId;
  final String label;
  final IconData icon;
}

const productRowActionConfigs = <ProductRowActionConfig>[
  ProductRowActionConfig(
    id: 'edit',
    actionId: ProductRowActionId.edit,
    label: 'Edit',
    icon: Icons.edit_outlined,
    permissionsAny: [
      TenantAdminPermissionCodes.catalogProductsUpdate,
      'catalog.product.update',
    ],
  ),
  ProductRowActionConfig(
    id: 'delete',
    actionId: ProductRowActionId.delete,
    label: 'Delete',
    icon: Icons.delete_outline,
    permission: TenantAdminPermissionCodes.catalogProductsDelete,
    showInMoreMenu: true,
  ),
];

List<ProductRowActionConfig> visibleProductRowActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny, {
  bool Function()? canUpdateProduct,
}) {
  final configs = filterProductConfigs(
    productRowActionConfigs.where((config) => !config.showInMoreMenu).toList(),
    can,
    canAny,
  );

  if (canUpdateProduct == null) {
    return configs;
  }

  return configs
      .where(
        (config) =>
            config.actionId != ProductRowActionId.edit || canUpdateProduct(),
      )
      .toList(growable: false);
}

List<ProductRowActionConfig> visibleProductMoreMenuActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  final configs = filterProductConfigs(
    productRowActionConfigs.where((config) => config.showInMoreMenu).toList(),
    can,
    canAny,
  );

  if (!ProductApiCapabilities.deleteProduct) {
    return configs
        .where((config) => config.actionId != ProductRowActionId.delete)
        .toList(growable: false);
  }

  return configs;
}

class ProductSummaryCardConfig extends ProductWidgetPermissionConfig {
  const ProductSummaryCardConfig({
    required super.id,
    super.permission,
    super.permissionsAny = const [],
    required this.title,
    required this.icon,
    required this.valueBuilder,
    required this.subtitleBuilder,
  });

  final String title;
  final IconData icon;
  final String Function(ProductListSummary summary) valueBuilder;
  final String Function(ProductListSummary summary) subtitleBuilder;
}

const productSummaryCardConfigs = <ProductSummaryCardConfig>[
  ProductSummaryCardConfig(
    id: 'total_products',
    permissionsAny: [
      TenantAdminPermissionCodes.productView,
      TenantAdminPermissionCodes.catalogProductView,
      TenantAdminPermissionCodes.catalogProductsView,
    ],
    title: 'Total Products',
    icon: Icons.inventory_2_outlined,
    valueBuilder: _totalProductsValue,
    subtitleBuilder: _totalProductsSubtitle,
  ),
  ProductSummaryCardConfig(
    id: 'active_products',
    permissionsAny: [
      TenantAdminPermissionCodes.productView,
      TenantAdminPermissionCodes.catalogProductView,
      TenantAdminPermissionCodes.catalogProductsView,
    ],
    title: 'Active Products',
    icon: Icons.shopping_bag_outlined,
    valueBuilder: _activeProductsValue,
    subtitleBuilder: _activeProductsSubtitle,
  ),
  ProductSummaryCardConfig(
    id: 'inactive_products',
    permissionsAny: [
      TenantAdminPermissionCodes.productView,
      TenantAdminPermissionCodes.catalogProductView,
      TenantAdminPermissionCodes.catalogProductsView,
    ],
    title: 'Inactive Products',
    icon: Icons.sell_outlined,
    valueBuilder: _inactiveProductsValue,
    subtitleBuilder: _inactiveProductsSubtitle,
  ),
  ProductSummaryCardConfig(
    id: 'categories',
    permissionsAny: [
      TenantAdminPermissionCodes.productView,
      TenantAdminPermissionCodes.catalogProductView,
      TenantAdminPermissionCodes.catalogProductsView,
    ],
    title: 'Categories',
    icon: Icons.category_outlined,
    valueBuilder: _categoriesValue,
    subtitleBuilder: _categoriesSubtitle,
  ),
];

String _totalProductsValue(ProductListSummary summary) =>
    '${summary.totalProducts}';

String _totalProductsSubtitle(ProductListSummary summary) => 'All products';

String _activeProductsValue(ProductListSummary summary) =>
    '${summary.activeProducts}';

String _activeProductsSubtitle(ProductListSummary summary) {
  return '${_percent(summary.activeProducts, summary.totalProducts)}% of total';
}

String _inactiveProductsValue(ProductListSummary summary) =>
    '${summary.inactiveProducts}';

String _inactiveProductsSubtitle(ProductListSummary summary) {
  return '${_percent(summary.inactiveProducts, summary.totalProducts)}% of total';
}

String _categoriesValue(ProductListSummary summary) =>
    '${summary.productCategories}';

String _categoriesSubtitle(ProductListSummary summary) => 'Product categories';

int _percent(int value, int total) {
  if (total <= 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

List<ProductSummaryCardConfig> visibleProductSummaryCards(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterProductConfigs(productSummaryCardConfigs, can, canAny);
}
