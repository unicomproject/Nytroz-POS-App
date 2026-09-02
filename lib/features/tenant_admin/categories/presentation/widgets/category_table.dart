import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../providers/category_tree_expansion_provider.dart';
import '../utils/category_form_utils.dart';
import 'category_actions.dart';

class CategoryTable extends ConsumerStatefulWidget {
  const CategoryTable({
    super.key,
    required this.nodes,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.canChangeStatus,
    this.forcedExpandedIds = const {},
  });

  final List<CategoryTreeNode> nodes;
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool canChangeStatus;
  final Set<String> forcedExpandedIds;

  static const double _imageSize = 56;
  static const double _headingHeight = 44;
  static const double _rowHeight = 92;
  static const int pageSize = 5;

  @override
  ConsumerState<CategoryTable> createState() => _CategoryTableState();
}

class _CategoryColumnWidths {
  const _CategoryColumnWidths({
    required this.category,
    required this.code,
    required this.level,
    required this.products,
    required this.status,
    required this.actions,
    required this.gap,
    required this.compact,
  });

  final double category;
  final double code;
  final double level;
  final double products;
  final double status;
  final double actions;
  final double gap;
  final bool compact;

  static const horizontalPadding = 16.0;
  static const _gap = 16.0;
  static const _maxCategory = 300.0;

  static const _baseCategory = 250.0;
  static const _baseCode = 140.0;
  static const _baseLevel = 80.0;
  static const _baseProducts = 128.0;
  static const _baseStatus = 108.0;
  static const _baseActions = 56.0;

  static const _flexCategory = 1.4;
  static const _flexCode = 2.0;
  static const _flexLevel = 1.0;
  static const _flexProducts = 1.4;
  static const _flexStatus = 1.2;
  static const _flexActions = 0.5;

  static bool isCompact(double width) =>
      width < TenantAdminBreakpoints.smallTablet;

  static double minTableWidth(bool compact) {
    final gapCount = compact ? 4 : 5;
    var width = horizontalPadding * 2 +
        gapCount * _gap +
        _baseCategory +
        _baseCode +
        _baseLevel +
        _baseStatus +
        _baseActions;
    if (!compact) {
      width += _baseProducts;
    }
    return width;
  }

  static _CategoryColumnWidths fromTableWidth({
    required double tableWidth,
    required bool compact,
  }) {
    final bases = <double>[
      _baseCategory,
      _baseCode,
      _baseLevel,
      if (!compact) _baseProducts,
      _baseStatus,
      _baseActions,
    ];
    final flexes = <double>[
      _flexCategory,
      _flexCode,
      _flexLevel,
      if (!compact) _flexProducts,
      _flexStatus,
      _flexActions,
    ];

    final extra =
        (tableWidth - minTableWidth(compact)).clamp(0.0, double.infinity);
    final flexTotal = flexes.fold<double>(0, (sum, value) => sum + value);
    final widths = [
      for (var i = 0; i < bases.length; i++)
        bases[i] + extra * (flexes[i] / flexTotal),
    ];

    if (widths[0] > _maxCategory) {
      final overflow = widths[0] - _maxCategory;
      widths[0] = _maxCategory;
      final restFlex = flexTotal - flexes[0];
      for (var i = 1; i < widths.length; i++) {
        widths[i] += overflow * (flexes[i] / restFlex);
      }
    }

    var index = 0;
    double next() => widths[index++];

    return _CategoryColumnWidths(
      category: next(),
      code: next(),
      level: next(),
      products: compact ? 0 : next(),
      status: next(),
      actions: next(),
      gap: _gap,
      compact: compact,
    );
  }
}

class _CategoryTableState extends ConsumerState<CategoryTable> {
  @override
  Widget build(BuildContext context) {
    final expandedIds = {
      ...ref.watch(categoryTreeExpansionProvider),
      ...widget.forcedExpandedIds,
    };
    final rows = visibleCategoryTreeRows(
      nodes: widget.nodes,
      expandedIds: expandedIds,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = _CategoryColumnWidths.isCompact(availableWidth);
        final minTableWidth = _CategoryColumnWidths.minTableWidth(compact);
        final tableWidth =
            availableWidth > minTableWidth ? availableWidth : minTableWidth;
        final needsHorizontalScroll = tableWidth > availableWidth + 0.5;
        final columns = _CategoryColumnWidths.fromTableWidth(
          tableWidth: tableWidth,
          compact: compact,
        );
        final bodyHeight = rows.length * CategoryTable._rowHeight;
        final tableHeight = CategoryTable._headingHeight + bodyHeight;

        Widget table = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(
                  bottom: BorderSide(color: TenantAdminColors.border),
                ),
              ),
              child: SizedBox(
                width: tableWidth,
                height: CategoryTable._headingHeight,
                child: _CategoryTableHeaderRow(columns: columns),
              ),
            ),
            for (final row in rows)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: TenantAdminColors.border),
                  ),
                ),
                child: SizedBox(
                  width: tableWidth,
                  height: CategoryTable._rowHeight,
                  child: _CategoryTableDataRow(
                    row: row,
                    columns: columns,
                    isExpanded: expandedIds.contains(row.node.id),
                    canView: widget.canView,
                    canEdit: widget.canEdit,
                    canDelete: widget.canDelete,
                    canChangeStatus: widget.canChangeStatus,
                    onToggleExpand: () => ref
                        .read(categoryTreeExpansionProvider.notifier)
                        .toggle(row.node.id),
                  ),
                ),
              ),
          ],
        );

        if (needsHorizontalScroll) {
          table = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(width: tableWidth, child: table),
          );
        }

        return SizedBox(
          width: availableWidth,
          height: tableHeight,
          child: table,
        );
      },
    );
  }
}

class _CategoryTableHeaderRow extends StatelessWidget {
  const _CategoryTableHeaderRow({required this.columns});

  final _CategoryColumnWidths columns;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF4B5563),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _CategoryColumnWidths.horizontalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: columns.category,
            child: const Text('Category', style: style),
          ),
          SizedBox(width: columns.gap),
          SizedBox(
            width: columns.code,
            child: const Text('Code', style: style),
          ),
          SizedBox(width: columns.gap),
          SizedBox(
            width: columns.level,
            child: const Center(child: Text('Level', style: style)),
          ),
          if (!columns.compact) ...[
            SizedBox(width: columns.gap),
            SizedBox(
              width: columns.products,
              child: const Center(child: Text('Product Count', style: style)),
            ),
          ],
          SizedBox(width: columns.gap),
          SizedBox(
            width: columns.status,
            child: const Text('Status', style: style),
          ),
          SizedBox(width: columns.gap),
          SizedBox(
            width: columns.actions,
            child: const Text('Actions', style: style),
          ),
        ],
      ),
    );
  }
}

class _CategoryTableDataRow extends ConsumerWidget {
  const _CategoryTableDataRow({
    required this.row,
    required this.columns,
    required this.isExpanded,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.canChangeStatus,
    required this.onToggleExpand,
  });

  final VisibleCategoryTreeRow row;
  final _CategoryColumnWidths columns;
  final bool isExpanded;
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool canChangeStatus;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = row.node;
    final category = categoryFromTreeNode(node, parentName: row.parentName);
    final hasExpandableChildren = node.hasChildren && node.children.isNotEmpty;

    void openDetails() {
      if (!canView) return;
      context.go(ProductsSidebarRoutes.categoryDetail(node.id));
    }

    const valueStyle = TextStyle(
      color: TenantAdminColors.bodyText,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _CategoryColumnWidths.horizontalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MouseRegion(
            cursor:
                canView ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: canView ? openDetails : null,
              child: Row(
                children: [
                  SizedBox(
                    width: columns.category,
                    child: _CategoryIdentityCell(
                      category: category,
                      depth: row.depth,
                      hasExpandableChildren: hasExpandableChildren,
                      isExpanded: isExpanded,
                      onToggleExpand:
                          hasExpandableChildren ? onToggleExpand : null,
                    ),
                  ),
                  SizedBox(width: columns.gap),
                  SizedBox(
                    width: columns.code,
                    child: Text(
                      category.categoryCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: columns.gap),
                  SizedBox(
                    width: columns.level,
                    child: Center(
                      child: Text('${category.level}', style: valueStyle),
                    ),
                  ),
                  if (!columns.compact) ...[
                    SizedBox(width: columns.gap),
                    SizedBox(
                      width: columns.products,
                      child: Center(
                        child: Text(
                          '${category.productCount}',
                          style: valueStyle,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: columns.gap),
                  SizedBox(
                    width: columns.status,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CategoryStatusPill(isActive: category.isActive),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: columns.gap),
          SizedBox(
            width: columns.actions,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CategoryActionColumn(
                category: category,
                canEdit: canEdit,
                canDelete: canDelete,
                canChangeStatus: canChangeStatus,
                onEdit: () => context.go(
                  ProductsSidebarRoutes.categoryEdit(category.id),
                ),
                onDelete: () => archiveCategory(context, ref, category),
                onToggleStatus: () =>
                    toggleCategoryStatus(context, ref, category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIdentityCell extends StatelessWidget {
  const _CategoryIdentityCell({
    required this.category,
    required this.depth,
    required this.hasExpandableChildren,
    required this.isExpanded,
    this.onToggleExpand,
  });

  final Category category;
  final int depth;
  final bool hasExpandableChildren;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: depth * 16.0),
        SizedBox(
          width: 36,
          height: 36,
          child: hasExpandableChildren
              ? IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                  onPressed: onToggleExpand,
                  icon: Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 22,
                    color: TenantAdminColors.mutedText,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Row(
            children: [
              _CategoryAvatar(category: category),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.categoryName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (!category.isRoot) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.parentDisplayLabel,
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
          ),
        ),
      ],
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final trimmed = category.categoryName.trim();
    final initials =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    final url = category.imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Image.network(
          url,
          width: CategoryTable._imageSize,
          height: CategoryTable._imageSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(initials: initials),
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
      width: CategoryTable._imageSize,
      height: CategoryTable._imageSize,
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

class _CategoryStatusPill extends StatelessWidget {
  const _CategoryStatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? TenantAdminColors.success : TenantAdminColors.offline;
    final background = isActive
        ? TenantAdminColors.successSurface
        : TenantAdminColors.offline.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _CategoryActionColumn extends StatelessWidget {
  const _CategoryActionColumn({
    required this.category,
    required this.canEdit,
    required this.canDelete,
    required this.canChangeStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  final Category category;
  final bool canEdit;
  final bool canDelete;
  final bool canChangeStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final actions = <TenantAdminOverflowAction>[
      if (canEdit)
        TenantAdminOverflowAction(
          id: 'edit',
          icon: Icons.edit_outlined,
          label: 'Edit',
          onSelected: onEdit,
        ),
      if (canChangeStatus)
        TenantAdminOverflowAction(
          id: 'status',
          icon: category.isActive
              ? Icons.toggle_off_outlined
              : Icons.toggle_on_outlined,
          label: category.isActive ? 'Inactivate' : 'Activate',
          onSelected: onToggleStatus,
        ),
      if (canDelete)
        TenantAdminOverflowAction(
          id: 'delete',
          icon: Icons.inventory_2_outlined,
          label: 'Archive',
          onSelected: onDelete,
          destructive: true,
        ),
    ];

    return TenantAdminOverflowMenu(actions: actions);
  }
}
