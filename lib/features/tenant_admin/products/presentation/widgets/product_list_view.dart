import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/product.dart';
import '../config/product_row_action_configs.dart';
import '../utils/product_api_errors.dart';
import '../widgets/product_mobile_list.dart';
import 'product_thumbnail.dart';

class ProductListView extends StatefulWidget {
  const ProductListView({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
  });

  final ProductListResult result;
  final ProductListVisibility visibility;
  final bool isMobile;

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  // Track selected product IDs
  final Set<String> _selectedProductIds = {};

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: ProductMobileList(
          products: widget.result.items,
          visibility: widget.visibility,
        ),
      );
    }

    final showActions = widget.visibility.showActionsColumn;
    final canEdit = showActions &&
        widget.visibility.visibleRowActions.any(
          (action) => action.actionId == ProductRowActionId.edit,
        );

    final allSelected = widget.result.items.isNotEmpty &&
        _selectedProductIds.length == widget.result.items.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic column spacing to eliminate empty space on the right
        final double availableWidth = constraints.maxWidth - 40; // 20px horizontal margin
        const double approxContentWidth = 720.0; // Sum of approximate column widths
        double dynamicSpacing = 20.0;
        if (availableWidth > approxContentWidth) {
          dynamicSpacing = (availableWidth - approxContentWidth) / 7;
          if (dynamicSpacing < 20.0) dynamicSpacing = 20.0;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: DataTable(
              headingRowHeight: 52,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 72,
              columnSpacing: dynamicSpacing,
              horizontalMargin: 20,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF8FAFC),
              ),
              headingTextStyle: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              dataTextStyle: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dividerThickness: 0.5,
              columns: [
                // Header Checkbox
                DataColumn(
                  label: SizedBox(
                    width: 24,
                    child: Checkbox(
                      value: allSelected,
                      activeColor: TenantAdminColors.primary,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedProductIds.addAll(
                              widget.result.items.map((p) => p.id),
                            );
                          } else {
                            _selectedProductIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
                const DataColumn(
                  label: SizedBox(width: 48, child: Text('Image')),
                ),
                const DataColumn(
                  label: Text('Product Name'),
                ),
                const DataColumn(
                  label: Text('SKU'),
                ),
                const DataColumn(
                  label: Text('Category'),
                ),
                const DataColumn(
                  label: Text('Stock'),
                ),
                const DataColumn(
                  label: Text('Status'),
                ),
                const DataColumn(
                  label: Align(
                    alignment: Alignment.center,
                    child: Text('Action'),
                  ),
                ),
              ],
              rows: [
                for (var i = 0; i < widget.result.items.length; i++)
                  _buildRow(context, widget.result.items[i], i, canEdit),
              ],
            ),
          ),
        );
      },
    );
  }

  DataRow _buildRow(
    BuildContext context,
    Product product,
    int index,
    bool canEdit,
  ) {
    final isSelected = _selectedProductIds.contains(product.id);

    return DataRow(
      selected: isSelected,
      color: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFF1F5F9);
          }
          if (isSelected) {
            return TenantAdminColors.primary.withOpacity(0.04);
          }
          return null;
        },
      ),
      cells: [
        // Row Checkbox
        DataCell(
          SizedBox(
            width: 24,
            child: Checkbox(
              value: isSelected,
              activeColor: TenantAdminColors.primary,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedProductIds.add(product.id);
                  } else {
                    _selectedProductIds.remove(product.id);
                  }
                });
              },
            ),
          ),
        ),
        // Image column
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ProductThumbnail(
              productId: product.id,
              imageStorageKey: product.imageStorageKey,
              size: 44,
            ),
          ),
        ),
        // Product Name
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // SKU
        DataCell(
          Text(
            product.sku,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        // Category
        DataCell(
          Text(
            product.categoryName ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        // Stock
        DataCell(
          const Text(
            '-',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: TenantAdminColors.bodyText,
            ),
          ),
        ),
        // Status
        DataCell(
          TenantAdminStatusBadge(
            label: displayProductStatus(product.status),
            status: productStatusType(product.status),
          ),
        ),
        // Action - three dot menu
        DataCell(
          Center(
            child: _ActionMenuButton(
              product: product,
              canEdit: canEdit,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  const _ActionMenuButton({
    required this.product,
    required this.canEdit,
  });

  final Product product;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 18,
          color: TenantAdminColors.mutedText,
        ),
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      shadowColor: const Color(0x1A000000),
      offset: const Offset(0, 8),
      itemBuilder: (context) => [
        if (canEdit)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: TenantAdminColors.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Edit Product',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: TenantAdminColors.info,
              ),
              SizedBox(width: 10),
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(
                Icons.copy_outlined,
                size: 18,
                color: TenantAdminColors.mutedText,
              ),
              SizedBox(width: 10),
              Text(
                'Duplicate',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            context.go('/tenant-admin/products/${product.id}/edit');
            break;
          case 'view':
            context.go('/tenant-admin/products/${product.id}/edit');
            break;
          case 'duplicate':
            break;
        }
      },
    );
  }
}
