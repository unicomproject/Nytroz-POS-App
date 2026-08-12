import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_product.dart';
import 'product_delete_action.dart';
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
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 52,
                  dataRowMinHeight: 68,
                  dataRowMaxHeight: 68,
                  columnSpacing: TenantAdminSpacing.xl,
                  horizontalMargin: TenantAdminSpacing.lg,
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFF7F8FA)),
                  headingTextStyle: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  dataTextStyle: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Variants')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Product Status')),
                    DataColumn(label: Text('Stock Status')),
                    DataColumn(label: Text('Actions')),
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
                            onTap: visibility.showViewAction
                                ? () => onView(product)
                                : null,
                          ),
                          DataCell(_PlainCell(_emptyDash(product.sku))),
                          DataCell(
                            _PlainCell(_emptyDash(
                                product.categoryName ?? 'Uncategorised')),
                          ),
                          DataCell(_PlainCell('${product.variantCount}')),
                          DataCell(_PlainCell(_formatPrice(product))),
                          DataCell(
                            _PlainCell(
                              product.stockQuantity == null
                                  ? '—'
                                  : '${product.stockQuantity}',
                            ),
                          ),
                          DataCell(ProductStatusBadge(status: product.status)),
                          DataCell(
                              StockStatusBadge(status: product.stockStatus)),
                          DataCell(
                            Row(
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
                                if (visibility.showDeleteAction ||
                                    visibility.showEditAction ||
                                    visibility.showViewAction) ...[
                                  const SizedBox(width: TenantAdminSpacing.sm),
                                  ProductDeleteAction(
                                    productId: product.id,
                                    productName: product.name,
                                    sku: product.sku,
                                    imageUrl: product.imageUrl,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _emptyDash(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  static String _formatPrice(TenantProduct product) {
    final currency =
        (product.currencyCode == null || product.currencyCode!.trim().isEmpty)
            ? 'LKR'
            : product.currencyCode!.toUpperCase();

    if (product.priceFrom == null && product.priceTo == null) {
      return '—';
    }

    if (product.priceFrom == product.priceTo || product.priceTo == null) {
      return '$currency ${product.priceFrom!.toStringAsFixed(2)}';
    }

    return '$currency ${product.priceFrom!.toStringAsFixed(2)} - ${product.priceTo!.toStringAsFixed(2)}';
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (product.primaryBarcode != null &&
                  product.primaryBarcode!.isNotEmpty)
                Text(
                  product.primaryBarcode!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 11.5,
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

class _ProductAvatar extends ConsumerWidget {
  const _ProductAvatar({
    required this.imageUrl,
    required this.name,
  });

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmed = name.trim();
    final initials =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final baseUrl = ref.watch(appDioProvider).options.baseUrl;
      final resolvedUrl =
          MediaUrlResolver.resolve(imageUrl!, apiBaseUrl: baseUrl) ??
              imageUrl!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Image.network(
          resolvedUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FallbackAvatar(initials: initials),
        ),
      );
    }

    return _FallbackAvatar(initials: initials);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
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
          fontSize: 18,
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
    // ignore: unused_element_parameter
    this.isDanger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? TenantAdminColors.danger : const Color(0xFF1890FF);
    final bg = isDanger
        ? TenantAdminColors.danger.withValues(alpha: 0.08)
        : const Color(0xFF1890FF).withValues(alpha: 0.08);
    final border = isDanger
        ? TenantAdminColors.danger.withValues(alpha: 0.3)
        : const Color(0xFF1890FF).withValues(alpha: 0.3);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
