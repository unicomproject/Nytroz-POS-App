import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_cached_network_image.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_product.dart';
import 'product_delete_action.dart';
import 'product_status_action_menu.dart';
import 'product_status_badge.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    required this.visibility,
    required this.onView,
    required this.onEdit,
  });

  final List<TenantProduct> products;
  final ProductListVisibility visibility;
  final ValueChanged<TenantProduct> onView;
  final ValueChanged<TenantProduct> onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 72,
        columnSpacing: TenantAdminSpacing.xl,
        horizontalMargin: TenantAdminSpacing.lg,
        headingTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Status')),
          DataColumn(
            label: Align(
              alignment: Alignment.centerRight,
              child: Text('Actions'),
            ),
          ),
        ],
        rows: [
          for (final product in products)
            DataRow(
              cells: [
                DataCell(
                  _ProductIdentityCell(
                    product: product,
                    canView: visibility.showViewAction,
                  ),
                  onTap:
                      visibility.showViewAction ? () => onView(product) : null,
                ),
                DataCell(_PlainCell(_emptyDash(product.sku))),
                DataCell(
                  _PlainCell(
                      _emptyDash(product.categoryName ?? 'Uncategorised')),
                ),
                DataCell(_PlainCell(_formatPrice(product))),
                DataCell(_PlainCell('${product.stockQuantity}')),
                DataCell(ProductStatusBadge(status: product.status)),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (visibility.showViewAction)
                          _ActionIconButton(
                            icon: Icons.visibility_outlined,
                            tooltip: 'View details',
                            onPressed: () => onView(product),
                          ),
                        if (visibility.showEditAction) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit product',
                            onPressed: () => onEdit(product),
                          ),
                        ],
                        if (visibility.showStatusAction) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          ProductStatusActionMenu(
                            productId: product.id,
                            productName: product.name,
                            currentStatus: product.status,
                          ),
                        ],
                        if (visibility.showDeleteAction) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          ProductDeleteAction(
                            productId: product.id,
                            productName: product.name,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _emptyDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  static String _formatPrice(TenantProduct product) {
    if (product.sellingPrice == null) {
      return '-';
    }

    final currency =
        (product.currencyCode == null || product.currencyCode!.trim().isEmpty)
            ? 'LKR'
            : product.currencyCode!.toUpperCase();
    return '$currency ${product.sellingPrice!.toStringAsFixed(2)}';
  }
}

class _ProductIdentityCell extends StatelessWidget {
  const _ProductIdentityCell({
    required this.product,
    required this.canView,
  });

  final TenantProduct product;
  final bool canView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProductAvatar(imageUrl: product.imageUrl, name: product.name),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: canView
                      ? TenantAdminColors.primary
                      : TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.barcode != null && product.barcode!.isNotEmpty)
                Text(
                  product.barcode!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductAvatar extends StatelessWidget {
  const _ProductAvatar({
    required this.imageUrl,
    required this.name,
  });

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initials =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: AppCachedNetworkImage(
        imageUrl: imageUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        memCacheWidth: 72,
        errorWidget: _FallbackAvatar(initials: initials),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PlainCell extends StatelessWidget {
  const _PlainCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(value);
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: TenantAdminColors.bodyText,
      ),
    );
  }
}
