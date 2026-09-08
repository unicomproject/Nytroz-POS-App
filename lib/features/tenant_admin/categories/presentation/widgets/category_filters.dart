import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_list_query.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../providers/category_providers.dart';

class CategoryFiltersBar extends ConsumerWidget {
  const CategoryFiltersBar({super.key});

  static const _controlHeight = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(categoryStatusFilterProvider);
    final parentFilter = ref.watch(categoryParentFilterProvider);
    final treeAsync = ref.watch(categoryTreeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.smallTablet;

        final search = SizedBox(
          height: _controlHeight,
          child: TenantAdminSearchField(
            hint: 'Search categories by name or code',
            value: ref.watch(categorySearchProvider),
            isDense: true,
            onChanged: (value) {
              ref.read(categorySearchProvider.notifier).state = value;
              ref.read(categoryPageProvider.notifier).state = 1;
            },
          ),
        );

        final statusDropdown = SizedBox(
          height: _controlHeight,
          child: _StatusFilterDropdown(
            value: statusFilter,
            onChanged: (value) {
              ref.read(categoryStatusFilterProvider.notifier).state = value;
              ref.read(categoryPageProvider.notifier).state = 1;
            },
          ),
        );

        final parentDropdown = treeAsync.when(
          loading: () => const SizedBox(
            width: 180,
            height: _controlHeight,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (tree) => SizedBox(
            height: _controlHeight,
            child: _ParentFilterDropdown(
              tree: tree,
              value: parentFilter,
              onChanged: (value) {
                ref.read(categoryParentFilterProvider.notifier).state = value;
                ref.read(categoryPageProvider.notifier).state = 1;
              },
            ),
          ),
        );

        final resetButton = SizedBox(
          height: _controlHeight,
          child: OutlinedButton(
            onPressed: () {
              ref.read(categorySearchProvider.notifier).state = '';
              ref.read(categoryStatusFilterProvider.notifier).state =
                  CategoryStatusFilter.all;
              ref.read(categoryParentFilterProvider.notifier).state =
                  CategoryParentFilter.all;
              ref.read(categoryPageProvider.notifier).state = 1;
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: TenantAdminColors.primary,
              side: const BorderSide(color: TenantAdminColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, _controlHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Reset'),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: TenantAdminSpacing.sm),
              statusDropdown,
              const SizedBox(height: TenantAdminSpacing.sm),
              parentDropdown,
              const SizedBox(height: TenantAdminSpacing.sm),
              resetButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: search),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(flex: 2, child: statusDropdown),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(flex: 3, child: parentDropdown),
            const SizedBox(width: TenantAdminSpacing.sm),
            resetButton,
          ],
        );
      },
    );
  }
}

InputDecoration _filterDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: TenantAdminColors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.primary),
    ),
  );
}

class _FilterItemText extends StatelessWidget {
  const _FilterItemText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({
    required this.value,
    required this.onChanged,
  });

  final CategoryStatusFilter value;
  final ValueChanged<CategoryStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategoryStatusFilter>(
      key: ValueKey(value),
      initialValue: value,
      isDense: true,
      isExpanded: true,
      dropdownColor: TenantAdminOverlaySurfaces.color,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      decoration: _filterDecoration(),
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      items: const [
        DropdownMenuItem(
          value: CategoryStatusFilter.all,
          child: _FilterItemText('All Status'),
        ),
        DropdownMenuItem(
          value: CategoryStatusFilter.active,
          child: _FilterItemText('Active'),
        ),
        DropdownMenuItem(
          value: CategoryStatusFilter.inactive,
          child: _FilterItemText('Inactive'),
        ),
      ],
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }
}

class _ParentFilterDropdown extends StatelessWidget {
  const _ParentFilterDropdown({
    required this.tree,
    required this.value,
    required this.onChanged,
  });

  final List<CategoryTreeNode> tree;
  final CategoryParentFilter value;
  final ValueChanged<CategoryParentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final flatOptions = _flattenTree(tree);

    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedKey(value)),
      initialValue: _selectedKey(value),
      isDense: true,
      isExpanded: true,
      dropdownColor: TenantAdminOverlaySurfaces.color,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      decoration: _filterDecoration(),
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      items: [
        const DropdownMenuItem(
          value: 'all',
          child: _FilterItemText('All Parent Category'),
        ),
        const DropdownMenuItem(
          value: 'root',
          child: _FilterItemText('Root Categories'),
        ),
        ...flatOptions.map(
          (option) => DropdownMenuItem(
            value: option.id,
            child: _FilterItemText(
              '${'  ' * (option.level - 1)}${option.name}',
            ),
          ),
        ),
      ],
      onChanged: (key) {
        if (key == null) return;
        if (key == 'all') {
          onChanged(CategoryParentFilter.all);
          return;
        }
        if (key == 'root') {
          onChanged(const CategoryParentFilter(
            kind: CategoryParentFilterKind.rootOnly,
          ));
          return;
        }
        final match = flatOptions.firstWhere((item) => item.id == key);
        onChanged(CategoryParentFilter(
          kind: CategoryParentFilterKind.specific,
          parentCategoryId: match.id,
          parentCategoryName: match.name,
        ));
      },
    );
  }

  String _selectedKey(CategoryParentFilter filter) {
    switch (filter.kind) {
      case CategoryParentFilterKind.all:
        return 'all';
      case CategoryParentFilterKind.rootOnly:
        return 'root';
      case CategoryParentFilterKind.specific:
        return filter.parentCategoryId ?? 'all';
    }
  }
}

List<({String id, String name, int level})> _flattenTree(
  List<CategoryTreeNode> nodes,
) {
  final result = <({String id, String name, int level})>[];

  void walk(List<CategoryTreeNode> items) {
    for (final node in items) {
      result.add((id: node.id, name: node.categoryName, level: node.level));
      if (node.children.isNotEmpty) {
        walk(node.children);
      }
    }
  }

  walk(nodes);
  return result;
}
