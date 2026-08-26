import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_product_detail.dart';
import 'product_status_badge.dart';

class ProductDetailViewCard extends StatelessWidget {
  const ProductDetailViewCard({
    super.key,
    required this.detail,
  });

  final TenantProductDetail detail;

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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= TenantAdminBreakpoints.desktop;
    final isTablet = width >= TenantAdminBreakpoints.tablet &&
        width < TenantAdminBreakpoints.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Product Image + Basic Details
        if (isDesktop || isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isDesktop ? 280 : 240,
                child: _ProductImageCard(detail: detail),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: _BasicDetailsCard(detail: detail),
              ),
            ],
          )
        else ...[
          _ProductImageCard(detail: detail),
          const SizedBox(height: TenantAdminSpacing.lg),
          _BasicDetailsCard(detail: detail),
        ],

        const SizedBox(height: TenantAdminSpacing.lg),

        // Row 2: Inventory & Pricing + Channel Visibility
        if (isDesktop || isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _InventoryPricingCard(
                  detail: detail,
                  stockStatus: _computedStockStatus,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              const Expanded(
                flex: 3,
                child: _ChannelVisibilityCard(),
              ),
            ],
          )
        else ...[
          _InventoryPricingCard(
            detail: detail,
            stockStatus: _computedStockStatus,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const _ChannelVisibilityCard(),
        ],

        const SizedBox(height: TenantAdminSpacing.lg),

        // Row 3: Product Summary (Audit Info)
        _ProductSummaryAuditCard(detail: detail),
      ],
    );
  }
}

class _ProductImageCard extends StatelessWidget {
  const _ProductImageCard({required this.detail});

  final TenantProductDetail detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Product Image',
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Container(
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
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  ),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              size: 36,
              color: TenantAdminColors.primary,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            detail.productName,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BasicDetailsCard extends StatelessWidget {
  const _BasicDetailsCard({required this.detail});

  final TenantProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItemData(
        icon: Icons.inventory_2_outlined,
        label: 'Product name',
        value: detail.productName,
      ),
      _InfoItemData(
        icon: Icons.qr_code_2_outlined,
        label: 'Product code / SKU',
        value: detail.sku,
      ),
      _InfoItemData(
        icon: Icons.notes_outlined,
        label: 'Short description',
        value: detail.shortDescription?.isNotEmpty == true
            ? detail.shortDescription!
            : '—',
      ),
      _InfoItemData(
        icon: Icons.description_outlined,
        label: 'Long description',
        value: detail.longDescription?.isNotEmpty == true
            ? detail.longDescription!
            : '—',
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
        icon: Icons.barcode_reader,
        label: 'Barcode',
        value: detail.barcode?.isNotEmpty == true ? detail.barcode! : '—',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 720
              ? 3
              : constraints.maxWidth >= 420
                  ? 2
                  : 1;
          const spacing = TenantAdminSpacing.md;
          final itemWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: _InfoTile(
                    icon: item.icon,
                    label: item.label,
                    value: item.value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InventoryPricingCard extends StatelessWidget {
  const _InventoryPricingCard({
    required this.detail,
    required this.stockStatus,
  });

  final TenantProductDetail detail;
  final String stockStatus;

  @override
  Widget build(BuildContext context) {
    final formattedPrice =
        'LKR ${detail.sellingPrice.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    final stockQty = detail.stock != null
        ? detail.stock!.onHandQuantity.toInt().toString()
        : '0';

    return _SectionCard(
      title: 'Inventory & Pricing',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 360 ? 2 : 1;
          const spacing = TenantAdminSpacing.md;
          final itemWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
          final tiles = [
            _InfoTile(
              icon: Icons.attach_money_outlined,
              label: 'Price',
              value: formattedPrice,
            ),
            _InfoTile(
              icon: Icons.inventory_outlined,
              label: 'Stock',
              value: stockQty,
            ),
            _StatusBadgeTile(
              label: 'Product Status',
              badge: ProductStatusBadge(status: detail.status),
            ),
            _StatusBadgeTile(
              label: 'Stock Status',
              badge: StockStatusBadge(status: stockStatus),
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final tile in tiles)
                SizedBox(width: itemWidth, child: tile),
            ],
          );
        },
      ),
    );
  }
}

class _ChannelVisibilityCard extends StatelessWidget {
  const _ChannelVisibilityCard();

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= TenantAdminBreakpoints.desktop;

    return _SectionCard(
      title: 'Channel Visibility',
      child: isDesktop
          ? const Row(
              children: [
                Expanded(
                  child: _ChannelItem(
                    icon: Icons.storefront_outlined,
                    title: 'In-Store POS',
                    subtitle: 'This product is available in the in-store POS.',
                    isVisible: true,
                  ),
                ),
                SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: _ChannelItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Online Store',
                    subtitle: 'This product is visible on the online store.',
                    isVisible: true,
                  ),
                ),
              ],
            )
          : const Column(
              children: [
                _ChannelItem(
                  icon: Icons.storefront_outlined,
                  title: 'In-Store POS',
                  subtitle: 'This product is available in the in-store POS.',
                  isVisible: true,
                ),
                SizedBox(height: TenantAdminSpacing.md),
                _ChannelItem(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Online Store',
                  subtitle: 'This product is visible on the online store.',
                  isVisible: true,
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
    required this.subtitle,
    required this.isVisible,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: TenantAdminColors.bodyText),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TenantAdminColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: TenantAdminColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVisible ? 'Visible' : 'Hidden',
                      style: const TextStyle(
                        color: TenantAdminColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSummaryAuditCard extends StatelessWidget {
  const _ProductSummaryAuditCard({required this.detail});

  final TenantProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final createdStr = dateFormat.format(detail.createdAt);
    final updatedStr = dateFormat.format(detail.updatedAt);

    return _SectionCard(
      title: 'Product Summary (Audit Info)',
      child: Row(
        children: [
          Expanded(
            child: _AuditTile(
              icon: Icons.calendar_today_outlined,
              label: 'Created date',
              value: createdStr,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          const Expanded(
            child: _AuditTile(
              icon: Icons.person_outline,
              label: 'Added by',
              value: 'John Perera',
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: _AuditTile(
              icon: Icons.calendar_month_outlined,
              label: 'Last updated',
              value: updatedStr,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: TenantAdminColors.mutedText),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeTile extends StatelessWidget {
  const _StatusBadgeTile({
    required this.label,
    required this.badge,
  });

  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          badge,
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: TenantAdminColors.mutedText),
        const SizedBox(width: TenantAdminSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
  });

  final IconData icon;
  final String label;
  final String value;
}
