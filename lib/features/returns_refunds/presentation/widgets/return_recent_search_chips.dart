import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnRecentSearchChips extends StatelessWidget {
  const ReturnRecentSearchChips({
    super.key,
    required this.items,
    required this.onSelected,
    required this.onRemoved,
    required this.onClearAll,
  });

  final List<String> items;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemoved;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearAll,
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            for (final item in items)
              InputChip(
                label: Text(item),
                onPressed: () => onSelected(item),
                onDeleted: () => onRemoved(item),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
      ],
    );
  }
}
