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

  static const double _imageSize = 80;
  static const double _headingHeight = 44;
  static const int _visibleRows = 4;
  static const int pageSize = TenantAdminContentTokens.defaultListPageSize;

  @override
  State<ProductTable> createState() => _ProductTableState();
}

class _ProductTableState extends State<ProductTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  bool _syncingHorizontal = false;

  static const _colProductCode = 180.0;
  static const _colType = 80.0;
  static const _colVariants = 80.0;
  static const _colPrice = 125.0;
  static const _colStockSummary = 135.0;
  static const _colStatus = 90.0;
  static const _colActions = 56.0;
  static const _colProduct = 200.0;
  static const _horizontalPadding = 16.0;

  static const _tableContentWidth = _horizontalPadding * 2 +
      _colProduct +
      _colProductCode +
      _colType +
      _colVariants +
      _colPrice +
      _colStockSummary +
      _colStatus +
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
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;

        final bodyHeight = availableHeight - ProductTable._headingHeight;
        final dynamicRowHeight =
            (bodyHeight / ProductTable._visibleRows).floorToDouble();

        const minTableWidth = _tableContentWidth;
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;
        const productColWidth = _colProduct;

        final totalHeight = ProductTable._headingHeight + bodyHeight;

        return SizedBox(
          width:
              constraints.maxWidth.isFinite ? constraints.maxWidth : tableWidth,
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
                        itemExtent: dynamicRowHeight,
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
                              height: dynamicRowHeight,
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
            width: _ProductTableState._colProductCode,
            child: Text('Product Code', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colType,
            child: Text('Type', style: style),
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
            width: _ProductTableState._colStockSummary,
            child: Text('Stock Summary', style: style),
          ),
          const SizedBox(
            width: _ProductTableState._colStatus,
            child: Text('Status', style: style),
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
          MouseRegion(
            cursor: visibility.showViewAction
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: visibility.showViewAction ? onView : null,
              child: Row(
                children: [
                  SizedBox(
                    width: productColWidth,
                    child: _ProductIdentityCell(product: product),
                  ),
                  SizedBox(
                    width: _ProductTableState._colProductCode,
                    child: _ProductCodeCell(product: product),
                  ),
                  SizedBox(
                    width: _ProductTableState._colType,
                    child: _ProductTypeCell(product: product),
                  ),
                  SizedBox(
                    width: _ProductTableState._colVariants,
                    child: Center(
                      child: Text(
                        '${product.variantCount}',
                        style: const TextStyle(
                          color: TenantAdminColors.bodyText,
                          fontSize: 13,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _ProductTableState._colStockSummary,
                    child: _StockSummaryCell(product: product),
                  ),
                  SizedBox(
                    width: _ProductTableState._colStatus,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ProductStatusBadge(status: product.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: _ProductTableState._colActions,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ProductActionColumn(
                product: product,
                visibility: visibility,
                onEdit: onEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Code cell ─────────────────────────────────────────────────────────

class _ProductCodeCell extends StatelessWidget {
  const _ProductCodeCell({required this.product});

  final TenantProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.productCode.isNotEmpty)
          Text(
            product.productCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (product.sku.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'SKU: ${product.sku}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (product.primaryBarcode != null &&
            product.primaryBarcode!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Barcode: ${product.primaryBarcode}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Product Type cell ─────────────────────────────────────────────────────────

class _ProductTypeCell extends StatelessWidget {
  const _ProductTypeCell({required this.product});

  final TenantProduct product;

  String get _typeLabel {
    final raw = product.productStructure?.trim().toUpperCase() ?? '';
    return switch (raw) {
      'VARIANT' => 'Variant\nProduct',
      'BUNDLE' => 'Bundle\nProduct',
      _ => 'Simple\nProduct',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _typeLabel,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
    );
  }
}

// ── Stock Summary cell ────────────────────────────────────────────────────────

class _StockSummaryCell extends StatelessWidget {
  const _StockSummaryCell({required this.product});

  final TenantProduct product;

  @override
  Widget build(BuildContext context) {
    final stockStatus = product.stockStatus?.trim().toUpperCase() ?? '';
    final qty = product.stockQuantity;

    if (stockStatus == 'NOT_TRACKED' || (qty == null && stockStatus.isEmpty)) {
      return const Text(
        'Not tracked',
        style: TextStyle(
          color: TenantAdminColors.mutedText,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final (dotColor, label) = switch (stockStatus) {
      'IN_STOCK' => (TenantAdminColors.success, '${qty ?? 0} in stock'),
      'LOW_STOCK' => (TenantAdminColors.warning, '${qty ?? 0} in stock'),
      'OUT_OF_STOCK' => (TenantAdminColors.danger, 'Out of stock'),
      _ => (TenantAdminColors.mutedText, qty != null ? '$qty in stock' : '—'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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

  return '$currency ${product.priceFrom!.toStringAsFixed(2)} –\n$currency ${product.priceTo!.toStringAsFixed(2)}';
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (product.categoryName != null &&
                  product.categoryName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.categoryName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
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
          fontSize: 18,
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
    required this.onEdit,
  });

  final TenantProduct product;
  final ProductListVisibility visibility;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showEdit = visibility.showEditAction;
    final showDelete = visibility.showDeleteAction || showEdit;

    if (!showEdit && !showDelete) {
      return const SizedBox.shrink();
    }

    return TenantAdminOverflowMenu(
      actions: [
        if (showEdit)
          TenantAdminOverflowAction(
            id: 'edit',
            icon: Icons.edit_outlined,
            label: 'Edit',
            onSelected: onEdit,
          ),
        if (showDelete)
          TenantAdminOverflowAction(
            id: 'delete',
            icon: Icons.delete_outline,
            label: 'Delete',
            destructive: true,
            onSelected: () => ProductDeleteAction.confirmAndDelete(
              context: context,
              ref: ref,
              productId: product.id,
              productName: product.name,
              sku: product.sku,
              imageUrl: product.imageUrl,
              isLocalDraft: product.isLocalDraft,
            ),
          ),
      ],
    );
  }
}
