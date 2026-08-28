import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

import '../../domain/entities/tenant_product.dart';
import 'product_delete_action.dart';
import 'product_status_badge.dart';

class ProductTable extends StatefulWidget {
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

  static const double _imageSize = 68;
  static const double _rowHeight = 120;
  static const double _headingHeight = 48;
  static const int _visibleRows = 3;
  static const int pageSize = 6;

  @override
  State<ProductTable> createState() => _ProductTableState();
}

class _ProductTableState extends State<ProductTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const _colVariants = 120.0;
  static const _colPrice = 110.0;
  static const _colStock = 80.0;
  static const _colStatus = 110.0;
  static const _colStockStatus = 130.0;
  static const _colActions = 110.0;
  static const _colProduct = 240.0;
  static const _horizontalPadding = 16.0;

  static const _tableContentWidth = _horizontalPadding * 2 +
      _colProduct +
      _colVariants +
      _colPrice +
      _colStock +
      _colStatus +
      _colStockStatus +
      _colActions;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(
      () => _syncHorizontal(
        _headerHorizontalController,
        _bodyHorizontalController,
      ),
    );
    _bodyHorizontalController.addListener(
      () => _syncHorizontal(
        _bodyHorizontalController,
        _headerHorizontalController,
      ),
    );
  }

  void _syncHorizontal(ScrollController source, ScrollController target) {
    if (_syncingHorizontal || !source.hasClients || !target.hasClients) {
      return;
    }
    if (source.offset == target.offset) {
      return;
    }
    _syncingHorizontal = true;
    target.jumpTo(source.offset);
    _syncingHorizontal = false;
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : ProductTable._headingHeight +
                (ProductTable._rowHeight * ProductTable._visibleRows);

        const maxBodyHeight = ProductTable._rowHeight * ProductTable._visibleRows;
        final bodyHeight = (availableHeight - ProductTable._headingHeight)
            .clamp(0.0, maxBodyHeight)
            .toDouble();

        const minTableWidth = _tableContentWidth;
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;
        const productColWidth = _colProduct;

        final totalHeight = ProductTable._headingHeight + bodyHeight;

        return SizedBox(
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : tableWidth,
          height: totalHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              overscroll: false,
              physics: const ClampingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    border: Border(
                      bottom: BorderSide(color: TenantAdminColors.border),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      height: ProductTable._headingHeight,
                      child: _ProductTableHeaderRow(
                        productColWidth: productColWidth,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: bodyHeight,
                  child: SingleChildScrollView(
                    controller: _bodyHorizontalController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      height: bodyHeight,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        itemExtent: ProductTable._rowHeight,
                        itemCount: widget.products.length,
                        itemBuilder: (context, index) {
                          final product = widget.products[index];
                          return DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: TenantAdminColors.border,
                                ),
                              ),
                            ),
                            child: SizedBox(
                              height: ProductTable._rowHeight,
                              child: _ProductTableDataRow(
                                product: product,
                                productColWidth: productColWidth,
                                visibility: widget.visibility,
                                onView: () => widget.onView(product),
                                onEdit: () => widget.onEdit(product),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductTableHeaderRow extends StatelessWidget {
  const _ProductTableHeaderRow({required this.productColWidth});

  final double productColWidth;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF4B5563),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ProductTableState._horizontalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: productColWidth,
            child: const Text('Product', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colVariants,
            child: Center(child: Text('Variants', style: style)),
          ),
          const SizedBox(
            width: _ProductTableState._colPrice,
            child: Text('Price', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colStock,
            child: Center(child: Text('Stock', style: style)),
          ),
          const SizedBox(
            width: _ProductTableState._colStatus,
            child: Text('Status', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colStockStatus,
            child: Text('Stock Status', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colActions,
            child: Text('Actions', style: style),
          ),
        ],
      ),
    );
  }
}

class _ProductTableDataRow extends StatelessWidget {
  const _ProductTableDataRow({
    required this.product,
    required this.productColWidth,
    required this.visibility,
    required this.onView,
    required this.onEdit,
  });

  final TenantProduct product;
  final double productColWidth;
  final ProductListVisibility visibility;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _ProductTableState._horizontalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: productColWidth,
            child: InkWell(
              onTap: visibility.showViewAction ? onView : null,
              child: _ProductIdentityCell(product: product),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colVariants,
            child: Center(
              child: Text(
                '${product.variantCount}',
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colPrice,
            child: Text(
              _formatProductPrice(product),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colStock,
            child: Center(
              child: Text(
                product.stockQuantity == null
                    ? '—'
                    : '${product.stockQuantity}',
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colStatus,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ProductStatusBadge(status: product.status),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colStockStatus,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StockStatusBadge(status: product.stockStatus),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colActions,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ProductActionColumn(
                product: product,
                visibility: visibility,
                onView: onView,
                onEdit: onEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatProductPrice(TenantProduct product) {
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

class _ProductIdentityCell extends StatelessWidget {
  const _ProductIdentityCell({
    required this.product,
  });

  final TenantProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProductAvatar(imageUrl: product.imageUrl, name: product.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (product.sku.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.sku,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Image.network(
          resolvedUrl,
          width: ProductTable._imageSize,
          height: ProductTable._imageSize,
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
      width: ProductTable._imageSize,
      height: ProductTable._imageSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class ProductActionColumn extends ConsumerWidget {
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

  static const _actionBlue = Color(0xFF1890FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showView = visibility.showViewAction;
    final showEdit = visibility.showEditAction;
    final showDelete = visibility.showDeleteAction || showView || showEdit;

    if (!showView && !showEdit && !showDelete) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showView)
          _ActionLinkButton(
            icon: Icons.visibility_outlined,
            label: 'View',
            color: _actionBlue,
            onPressed: onView,
          ),
        if (showView && (showEdit || showDelete)) const SizedBox(height: 8),
        if (showEdit)
          _ActionLinkButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: _actionBlue,
            onPressed: onEdit,
          ),
        if (showEdit && showDelete) const SizedBox(height: 8),
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
    );
  }
}

class _ActionLinkButton extends StatelessWidget {
  const _ActionLinkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
