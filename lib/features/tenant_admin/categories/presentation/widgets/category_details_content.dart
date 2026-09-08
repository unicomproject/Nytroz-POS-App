import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../utils/category_form_utils.dart';

class CategoryDetailsContent extends StatelessWidget {
  const CategoryDetailsContent({
    super.key,
    required this.category,
    this.childCategories = const [],
    this.childrenLoading = false,
    this.onChildCategoryTap,
  });

  final Category category;
  final List<CategoryTreeNode> childCategories;
  final bool childrenLoading;
  final ValueChanged<String>? onChildCategoryTap;

  static const _sectionGap = TenantAdminSpacing.md;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        final basicInfo = _DetailSection(
          title: 'Basic Information',
          children: [
            _DetailField(label: 'Category Name', value: category.categoryName),
            _DetailField(label: 'Category Code', value: category.categoryCode),
            _DetailField(
              label: 'Status',
              valueWidget: TenantAdminStatusBadge(
                label: category.isActive ? 'Active' : 'Inactive',
                status: category.isActive
                    ? TenantAdminStatusType.active
                    : TenantAdminStatusType.inactive,
              ),
            ),
            _DetailField(
              label: 'Sort Order',
              value: '${category.sortOrder}',
            ),
          ],
        );

        final hierarchy = _DetailSection(
          title: 'Hierarchy',
          children: [
            _DetailField(
              label: 'Parent Category',
              value: category.parentDisplayLabel,
            ),
            _DetailField(label: 'Level', value: '${category.level}'),
            _DetailField(
              label: 'Hierarchy Path',
              value: category.hierarchyPath.isEmpty
                  ? category.categoryName
                  : category.hierarchyPath,
            ),
            _DetailField(
              label: 'Child Categories',
              value: '${category.childCount}',
            ),
          ],
        );

        final description = _DetailSection(
          title: 'Description',
          children: [
            _DetailField(
              label: 'Description',
              value: category.description?.trim().isNotEmpty == true
                  ? category.description!.trim()
                  : '—',
            ),
          ],
        );

        final childrenSection = _ChildCategoriesSection(
          childCount: category.childCount,
          childCategories: childCategories,
          loading: childrenLoading,
          onChildTap: onChildCategoryTap,
        );

        final productUsage = _DetailSection(
          title: 'Product Usage',
          children: [
            _DetailField(
              label: 'Product Count',
              value: '${category.productCount}',
            ),
            _DetailField(
              label: 'Has Children',
              value: category.hasChildren ? 'Yes' : 'No',
            ),
          ],
        );

        final audit = _DetailSection(
          title: 'Audit Information',
          children: [
            _DetailField(
              label: 'Created At',
              value: formatCategoryUpdatedOn(category.createdAt),
            ),
            _DetailField(
              label: 'Updated At',
              value: formatCategoryUpdatedOn(category.updatedAt),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoryHeaderCard(category: category, compact: twoColumn),
            const SizedBox(height: _sectionGap),
            if (twoColumn) ...[
              _EqualHeightRow(left: basicInfo, right: hierarchy),
              const SizedBox(height: _sectionGap),
              _EqualHeightRow(left: description, right: childrenSection),
              const SizedBox(height: _sectionGap),
              _EqualHeightRow(left: productUsage, right: audit),
            ] else ...[
              basicInfo,
              const SizedBox(height: _sectionGap),
              hierarchy,
              const SizedBox(height: _sectionGap),
              description,
              const SizedBox(height: _sectionGap),
              childrenSection,
              const SizedBox(height: _sectionGap),
              productUsage,
              const SizedBox(height: _sectionGap),
              audit,
            ],
          ],
        );
      },
    );
  }
}

class _EqualHeightRow extends StatelessWidget {
  const _EqualHeightRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: CategoryDetailsContent._sectionGap),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _CategoryHeaderCard extends StatelessWidget {
  const _CategoryHeaderCard({
    required this.category,
    required this.compact,
  });

  final Category category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 56.0 : 72.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? TenantAdminSpacing.md : TenantAdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Category Image',
            child: categoryImageAvatar(category, size: avatarSize),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.cardTitle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  category.categoryCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          TenantAdminStatusBadge(
            label: category.isActive ? 'Active' : 'Inactive',
            status: category.isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.md,
        TenantAdminSpacing.md,
        TenantAdminSpacing.md,
        TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TenantAdminTextStyles.cardTitle(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: TenantAdminTextStyles.fieldLabel(context).copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  style: TenantAdminTextStyles.body(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _ChildCategoriesSection extends StatelessWidget {
  const _ChildCategoriesSection({
    required this.childCount,
    required this.childCategories,
    required this.loading,
    this.onChildTap,
  });

  final int childCount;
  final List<CategoryTreeNode> childCategories;
  final bool loading;
  final ValueChanged<String>? onChildTap;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Child Categories',
      children: [
        if (loading && childCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: TenantAdminSpacing.sm),
            child: LinearProgressIndicator(),
          )
        else if (childCategories.isEmpty)
          _DetailField(
            label: 'Children',
            value: childCount == 0
                ? 'None yet.'
                : 'Expand this parent in Category Management to see $childCount nested ${childCount == 1 ? 'item' : 'items'}.',
          )
        else
          ...childCategories.map(
            (child) => _ChildCategoryTile(
              node: child,
              onTap: onChildTap == null ? null : () => onChildTap!(child.id),
            ),
          ),
      ],
    );
  }
}

class _ChildCategoryTile extends StatelessWidget {
  const _ChildCategoryTile({
    required this.node,
    this.onTap,
  });

  final CategoryTreeNode node;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Material(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: 6,
            ),
            child: Row(
              children: [
                treeNodeImageAvatar(node, size: 32),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TenantAdminTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        node.categoryCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TenantAdminStatusBadge(
                  label: node.isActive ? 'Active' : 'Inactive',
                  status: node.isActive
                      ? TenantAdminStatusType.active
                      : TenantAdminStatusType.inactive,
                ),
                if (onTap != null) ...[
                  const SizedBox(width: TenantAdminSpacing.sm),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: TenantAdminColors.mutedText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
