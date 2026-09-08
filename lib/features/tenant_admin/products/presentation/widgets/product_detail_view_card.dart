import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_product_detail.dart';
import 'product_status_badge.dart';

class ProductDetailViewCard extends StatelessWidget {
  const ProductDetailViewCard({
    super.key,
    required this.detail,
    this.canUpdate = false,
  });

  final TenantProductDetail detail;
  final bool canUpdate;

  String get _computedStockStatus {
    if (!detail.trackInventory) {
      return 'NOT_TRACKED';
    }
    if (detail.stock == null) {
      return 'OUT_OF_STOCK';
    }
    final onHand = detail.stock!.onHandQuantity;
    final minAlert = detail.stock!.minimumStockAlertQuantity;

    if (onHand <= 0) {
      return 'OUT_OF_STOCK';
    } else if (minAlert != null && onHand <= minAlert) {
      return 'LOW_STOCK';
    }
    return 'IN_STOCK';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= TenantAdminBreakpoints.tablet;
        const gap = TenantAdminSpacing.md;

        if (!isWide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductImageCard(detail: detail, compact: true),
                const SizedBox(height: gap),
                _BasicDetailsCard(detail: detail, compact: true),
                const SizedBox(height: gap),
                _PricingSummaryCard(detail: detail, compact: true),
                const SizedBox(height: gap),
                _InventorySummaryCard(
                  detail: detail,
                  stockStatus: _computedStockStatus,
                  compact: true,
                ),
                const SizedBox(height: gap),
                _VariantSummaryCard(
                  detail: detail,
                  canUpdate: canUpdate,
                  compact: true,
                ),
                const SizedBox(height: gap),
                _ProductSummaryAuditCard(detail: detail, compact: true),
              ],
            ),
          );
        }

        final isDesktop =
            constraints.maxWidth >= TenantAdminBreakpoints.desktop;
        final imageWidth = isDesktop ? 240.0 : 200.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: imageWidth,
                  child: _ProductImageCard(
                    detail: detail,
                    compact: true,
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _BasicDetailsCard(
                    detail: detail,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PricingSummaryCard(
                      detail: detail,
                      compact: true,
                      stretch: true,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _InventorySummaryCard(
                      detail: detail,
                      stockStatus: _computedStockStatus,
                      compact: true,
                      stretch: true,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _VariantSummaryCard(
                      detail: detail,
                      canUpdate: canUpdate,
                      compact: true,
                      stretch: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: gap),
            _ProductSummaryAuditCard(
              detail: detail,
              compact: true,
            ),
          ],
        );
      },
    );
  }
}

String _formatCurrency(double value) {
  return 'LKR ${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

class _ProductImageCard extends StatelessWidget {
  const _ProductImageCard({
    required this.detail,
    this.compact = false,
    this.fillHeight = false,
  });

  final TenantProductDetail detail;
  final bool compact;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Product Image',
      compact: compact,
      fillHeight: fillHeight,
      child: fillHeight
          ? ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              child: _buildImageContent(),
            )
          : AspectRatio(
              aspectRatio: 1.1,
              child: _buildImageContent(),
            ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: detail.imageUrl != null && detail.imageUrl!.trim().isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              child: Image.network(
                detail.imageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 48 : 72,
            height: compact ? 48 : 72,
            decoration: const BoxDecoration(
              color: TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checkroom_outlined,
              size: compact ? 24 : 36,
              color: TenantAdminColors.primary,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              detail.productName,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicDetailsCard extends StatelessWidget {
  const _BasicDetailsCard({
    required this.detail,
    this.compact = false,
  });

  final TenantProductDetail detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gridItems = [
      _InfoItemData(
        icon: Icons.qr_code_2_outlined,
        label: 'Product Code',
        value: detail.productCode.isNotEmpty ? detail.productCode : '—',
      ),
      _InfoItemData(
        icon: Icons.tag_outlined,
        label: 'SKU',
        value: detail.sku.isNotEmpty ? detail.sku : '—',
      ),
      _InfoItemData(
        icon: Icons.barcode_reader,
        label: 'Barcode',
        value: detail.barcode?.isNotEmpty == true ? detail.barcode! : '—',
      ),
      _InfoItemData(
        icon: Icons.notes_outlined,
        label: 'Short description',
        value: detail.shortDescription?.isNotEmpty == true
            ? detail.shortDescription!
            : '—',
        maxValueLines: 2,
      ),
      _InfoItemData(
        icon: Icons.description_outlined,
        label: 'Long description',
        value: detail.longDescription?.isNotEmpty == true
            ? detail.longDescription!
            : '—',
        maxValueLines: null,
      ),
      _InfoItemData(
        icon: Icons.category_outlined,
        label: 'Category',
        value:
            detail.categoryName.isNotEmpty == true ? detail.categoryName : '—',
      ),
      _InfoItemData(
        icon: Icons.sell_outlined,
        label: 'Brand',
        value: detail.brandId?.isNotEmpty == true ? detail.brandId! : 'OneVerz',
      ),
      _InfoItemData(
        icon: Icons.published_with_changes_outlined,
        label: 'Variants',
        value: '${detail.variants.length}',
      ),
      _InfoItemData(
        icon: Icons.straighten_outlined,
        label: 'Unit Type',
        value: detail.unitType.isNotEmpty == true ? detail.unitType : 'Pieces',
      ),
    ];

    return _SectionCard(
      title: 'Basic Details',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoGrid(
            items: gridItems,
            compact: compact,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _ChannelVisibilitySection(compact: compact),
        ],
      ),
    );
  }
}

class _ChannelVisibilitySection extends StatelessWidget {
  const _ChannelVisibilitySection({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Channel Visibility',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChannelItem(
                icon: Icons.storefront_outlined,
                title: 'In-Store POS',
                isVisible: true,
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
            Expanded(
              child: _ChannelItem(
                icon: Icons.shopping_cart_outlined,
                title: 'Online Store',
                isVisible: true,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.items,
    this.compact = false,
  });

  final List<_InfoItemData> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const columns = 3;
    assert(items.length == columns * 3, 'Basic details grid expects 9 items');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var rowIndex = 0; rowIndex < 3; rowIndex++) ...[
            if (rowIndex > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: TenantAdminColors.border,
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var colIndex = 0; colIndex < columns; colIndex++) ...[
                    if (colIndex > 0)
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: TenantAdminColors.border,
                      ),
                    Expanded(
                      child: _InfoTile(
                        icon: items[rowIndex * columns + colIndex].icon,
                        label: items[rowIndex * columns + colIndex].label,
                        value: items[rowIndex * columns + colIndex].value,
                        compact: compact,
                        maxValueLines:
                            items[rowIndex * columns + colIndex].maxValueLines,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PricingSummaryCard extends StatelessWidget {
  const _PricingSummaryCard({
    required this.detail,
    this.compact = false,
    this.fillHeight = false,
    this.stretch = false,
  });

  final TenantProductDetail detail;
  final bool compact;
  final bool fillHeight;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pricing Summary',
      compact: compact,
      fillHeight: fillHeight,
      stretch: stretch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Cost Price',
            value: detail.costPrice != null
                ? _formatCurrency(detail.costPrice!)
                : '—',
            compact: compact,
          ),
          _SummaryRow(
            label: 'Standard Selling Price',
            value: _formatCurrency(detail.sellingPrice),
            compact: compact,
          ),
          _SummaryRow(
            label: 'Discount Price',
            value: detail.discountPrice != null
                ? _formatCurrency(detail.discountPrice!)
                : '—',
            compact: compact,
          ),
          _SummaryRow(
            label: 'Tax',
            value: detail.taxName?.isNotEmpty == true ? detail.taxName! : '—',
            trailing: detail.taxName?.isNotEmpty == true
                ? _IncludedBadge(compact: compact)
                : null,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _InventorySummaryCard extends StatelessWidget {
  const _InventorySummaryCard({
    required this.detail,
    required this.stockStatus,
    this.compact = false,
    this.fillHeight = false,
    this.stretch = false,
  });

  final TenantProductDetail detail;
  final String stockStatus;
  final bool compact;
  final bool fillHeight;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final onHand = detail.stock?.onHandQuantity ?? 0;
    final available = detail.stock?.availableQuantity ?? 0;
    final reserved = (onHand - available).clamp(0, double.infinity);

    return _SectionCard(
      title: 'Inventory Summary',
      compact: compact,
      fillHeight: fillHeight,
      stretch: stretch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Stock',
            value: onHand.toInt().toString(),
            compact: compact,
          ),
          _SummaryRow(
            label: 'Reserved Stock',
            value: reserved.toInt().toString(),
            compact: compact,
          ),
          _SummaryRow(
            label: 'Available Stock',
            value: available.toInt().toString(),
            compact: compact,
          ),
          _SummaryRow(
            label: 'Stock Status',
            value: '',
            trailing: StockStatusBadge(status: stockStatus),
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _VariantSummaryCard extends StatelessWidget {
  const _VariantSummaryCard({
    required this.detail,
    this.canUpdate = false,
    this.compact = false,
    this.fillHeight = false,
    this.stretch = false,
  });

  final TenantProductDetail detail;
  final bool canUpdate;
  final bool compact;
  final bool fillHeight;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final total = detail.variants.length;
    final active = detail.variants
        .where((v) => v.status.trim().toUpperCase() == 'ACTIVE')
        .length;
    final inactive = total - active;

    return _SectionCard(
      title: 'Variant Summary',
      compact: compact,
      fillHeight: fillHeight,
      stretch: stretch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(
            label: 'Total',
            value: '$total',
            compact: compact,
          ),
          _SummaryRow(
            label: 'Active',
            value: '$active',
            compact: compact,
          ),
          _SummaryRow(
            label: 'Inactive',
            value: '$inactive',
            compact: compact,
          ),
          if (stretch) const Spacer(),
          if (!stretch) const SizedBox(height: TenantAdminSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canUpdate
                  ? () => context.go(
                        '/tenant-admin/products/${detail.productId}/edit',
                      )
                  : null,
              icon: Icon(Icons.visibility_outlined, size: compact ? 14 : 16),
              label: Text(
                'View All Variants',
                style: TextStyle(fontSize: compact ? 12 : 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 6 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelItem extends StatelessWidget {
  const _ChannelItem({
    required this.icon,
    required this.title,
    required this.isVisible,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final bool isVisible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: TenantAdminColors.bodyText),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: TenantAdminColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: TenantAdminColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isVisible ? 'Visible' : 'Hidden',
                  style: TextStyle(
                    color: TenantAdminColors.success,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSummaryAuditCard extends StatelessWidget {
  const _ProductSummaryAuditCard({
    required this.detail,
    this.compact = false,
  });

  final TenantProductDetail detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final createdStr = dateFormat.format(detail.createdAt);
    final updatedStr = dateFormat.format(detail.updatedAt);

    return _SectionCard(
      title: 'Product Audit Information',
      compact: compact,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AuditTile(
                icon: Icons.person_outline,
                label: 'Created By',
                value: 'John Perera',
                secondaryValue: createdStr,
                compact: compact,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _AuditTile(
                icon: Icons.person_outline,
                label: 'Last Updated By',
                value: 'John Perera',
                compact: compact,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _AuditTile(
                icon: Icons.calendar_month_outlined,
                label: 'Last Updated',
                value: updatedStr,
                compact: compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.compact = false,
    this.fillHeight = false,
    this.stretch = false,
  });

  final String title;
  final Widget child;
  final bool compact;
  final bool fillHeight;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 13.5 : 16,
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
        SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg),
        if (fillHeight)
          Expanded(child: child)
        else if (stretch)
          Expanded(child: child)
        else
          child,
      ],
    );

    return Container(
      width: fillHeight || stretch ? double.infinity : null,
      height: fillHeight || stretch ? double.infinity : null,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: EdgeInsets.all(compact ? TenantAdminSpacing.md : TenantAdminSpacing.xl),
      child: content,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
    this.maxValueLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;
  final int? maxValueLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        vertical: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: compact ? 18 : 20,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: compact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: maxValueLines,
                  overflow:
                      maxValueLines == null ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 3 : 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value,
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _IncludedBadge extends StatelessWidget {
  const _IncludedBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.successSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TenantAdminColors.successBorder),
      ),
      child: Text(
        'Included',
        style: TextStyle(
          color: TenantAdminColors.success,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: compact ? 15 : 18,
          color: TenantAdminColors.mutedText,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 1),
                Text(
                  secondaryValue!,
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: compact ? 10 : 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItemData {
  const _InfoItemData({
    required this.icon,
    required this.label,
    required this.value,
    this.maxValueLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int? maxValueLines;
}
