import 'package:flutter/material.dart';

import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class CategoryParentOption {
  const CategoryParentOption({
    required this.id,
    required this.name,
    required this.hierarchyPath,
    required this.level,
    required this.status,
  });

  final String id;
  final String name;
  final String hierarchyPath;
  final int level;
  final String status;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get displayLabel =>
      hierarchyPath.trim().isNotEmpty ? hierarchyPath : name;
}

List<CategoryParentOption> flattenActiveCategoryTree(
  List<CategoryTreeNode> nodes,
) {
  final result = <CategoryParentOption>[];

  void walk(List<CategoryTreeNode> items) {
    for (final node in items) {
      if (node.isActive) {
        result.add(
          CategoryParentOption(
            id: node.id,
            name: node.categoryName,
            hierarchyPath: node.hierarchyPath,
            level: node.level,
            status: node.status,
          ),
        );
      }

      if (node.children.isNotEmpty) {
        walk(node.children);
      }
    }
  }

  walk(nodes);
  return result;
}

Future<CategoryParentSelection?> showCategoryParentSelector({
  required BuildContext context,
  required List<CategoryParentOption> options,
  CategoryParentOption? selected,
  String? excludeCategoryId,
}) {
  return showDialog<CategoryParentSelection>(
    context: context,
    builder: (context) => _CategoryParentSelectorDialog(
      options: options
          .where((option) => option.id != excludeCategoryId)
          .toList(growable: false),
      selected: selected,
    ),
  );
}

sealed class CategoryParentSelection {
  const CategoryParentSelection();

  const factory CategoryParentSelection.root() = CategoryParentRootSelection;

  const factory CategoryParentSelection.parent(CategoryParentOption option) =
      CategoryParentSelected;
}

class CategoryParentRootSelection extends CategoryParentSelection {
  const CategoryParentRootSelection();
}

class CategoryParentSelected extends CategoryParentSelection {
  const CategoryParentSelected(this.option);

  final CategoryParentOption option;
}

class CategoryParentSelectorField extends StatelessWidget {
  const CategoryParentSelectorField({
    super.key,
    required this.options,
    required this.selectedId,
    required this.selectedLabel,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
    this.excludeCategoryId,
    this.isEditMode = false,
  });

  final List<CategoryParentOption> options;
  final String? selectedId;
  final String? selectedLabel;
  final ValueChanged<CategoryParentOption?> onChanged;
  final bool enabled;
  final String? errorText;
  final String? excludeCategoryId;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final label = selectedId == null
        ? 'No parent selected'
        : (selectedLabel ?? 'Selected parent');

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Parent Category',
        helperText: isEditMode
            ? 'Optional. Clear selection to move to root category.'
            : 'Optional. Leave empty to create a root category.',
        errorText: errorText,
        border: const OutlineInputBorder(),
        suffixIcon: selectedId != null && enabled
            ? IconButton(
                tooltip: 'Clear parent',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      child: InkWell(
        onTap: !enabled
            ? null
            : () async {
                CategoryParentOption? selected;
                if (selectedId != null) {
                  for (final option in options) {
                    if (option.id == selectedId) {
                      selected = option;
                      break;
                    }
                  }
                }

                final result = await showCategoryParentSelector(
                  context: context,
                  options: options,
                  selected: selected,
                  excludeCategoryId: excludeCategoryId,
                );
                if (result == null) return;

                switch (result) {
                  case CategoryParentRootSelection():
                    onChanged(null);
                  case CategoryParentSelected(:final option):
                    onChanged(option);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            style: TenantAdminTextStyles.inputText(context),
          ),
        ),
      ),
    );
  }
}

class _CategoryParentSelectorDialog extends StatefulWidget {
  const _CategoryParentSelectorDialog({
    required this.options,
    this.selected,
  });

  final List<CategoryParentOption> options;
  final CategoryParentOption? selected;

  @override
  State<_CategoryParentSelectorDialog> createState() =>
      _CategoryParentSelectorDialogState();
}

class _CategoryParentSelectorDialogState
    extends State<_CategoryParentSelectorDialog> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.options.where((option) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      return option.name.toLowerCase().contains(normalizedQuery) ||
          option.hierarchyPath.toLowerCase().contains(normalizedQuery) ||
          option.displayLabel.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Parent Category',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name or hierarchy path',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              ListTile(
                title: const Text('No parent selected'),
                subtitle: const Text('Creates a root category'),
                selected: widget.selected == null,
                onTap: () => Navigator.of(context).pop(
                  const CategoryParentSelection.root(),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching categories.',
                          style: TenantAdminTextStyles.muted(context),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          return ListTile(
                            title: Text(option.name),
                            subtitle: Text(option.displayLabel),
                            selected: widget.selected?.id == option.id,
                            onTap: () => Navigator.of(context).pop(
                              CategoryParentSelection.parent(option),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
