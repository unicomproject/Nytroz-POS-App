import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class CategoryFormScrollableColumns extends StatelessWidget {
  const CategoryFormScrollableColumns({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
  });

  final Widget leftColumn;
  final Widget rightColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn =
            constraints.maxWidth >= TenantAdminBreakpoints.smallTablet;

        if (twoColumn) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _scrollableColumn(leftColumn)),
              const SizedBox(width: TenantAdminSpacing.xl),
              Expanded(child: _scrollableColumn(rightColumn)),
            ],
          );
        }

        return _scrollableColumn(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftColumn,
              const SizedBox(height: TenantAdminSpacing.md),
              rightColumn,
            ],
          ),
        );
      },
    );
  }

  Widget _scrollableColumn(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

class CategoryHierarchyIndicator extends StatelessWidget {
  const CategoryHierarchyIndicator({
    super.key,
    required this.isRoot,
    this.parentHierarchyPath,
  });

  final bool isRoot;
  final String? parentHierarchyPath;

  @override
  Widget build(BuildContext context) {
    final color = isRoot ? TenantAdminColors.success : TenantAdminColors.primary;
    final background =
        isRoot ? TenantAdminColors.success.withValues(alpha: 0.08) : TenantAdminColors.primary.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRoot ? Icons.account_tree_outlined : Icons.subdirectory_arrow_right,
            color: color,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRoot ? 'Root Category' : 'Child Category',
                  style: TenantAdminTextStyles.sectionTitle(context).copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRoot
                      ? 'No parent selected. This will be a root category.'
                      : 'Parent: ${parentHierarchyPath ?? 'Selected parent category'}',
                  style: TenantAdminTextStyles.body(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
