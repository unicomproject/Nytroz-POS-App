import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
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
            physics: const NeverScrollableScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 52,
                  dataRowMinHeight: 80,
                  dataRowMaxHeight: 120,
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
                            ProductActionColumn(
                              product: product,
                              visibility: visibility,
                              onView: () => onView(product),
                              onEdit: () => onEdit(product),
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
          MediaUrlResolver.resolve(imageUrl!, apiBaseUrl: baseUrl) ?? imageUrl!;
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

class ProductActionColumn extends StatelessWidget {
  const ProductActionColumn({
    super.key,
    required this.product,
    required this.visibility,
    required this.onView,
    required this.onEdit,
  });

  final TenantProduct product;
  final ProductListVisibility visibility;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final showDelete = visibility.showDeleteAction ||
        visibility.showEditAction ||
        visibility.showViewAction;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (visibility.showViewAction) ...[
            _ActionRowButton(
              icon: Icons.visibility_outlined,
              label: 'View',
              onPressed: onView,
            ),
            if (visibility.showEditAction || showDelete)
              const SizedBox(height: 8),
          ],
          if (visibility.showEditAction) ...[
            _ActionRowButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onPressed: onEdit,
            ),
            if (showDelete) const SizedBox(height: 8),
          ],
          if (showDelete)
            ProductDeleteAction(
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              imageUrl: product.imageUrl,
              isLocalDraft: product.isLocalDraft,
              compact: false,
            ),
        ],
      ),
    );
  }
}

class _ActionRowButton extends StatelessWidget {
  const _ActionRowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1890FF);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
