import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class OutletReviewSection extends StatelessWidget {
  const OutletReviewSection({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<OutletReviewItem> items;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.value.trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TenantAdminColors.primary),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          for (final item in visibleItems) ...[
            _ReviewLine(item: item),
            if (item != visibleItems.last)
              const SizedBox(height: TenantAdminSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class OutletReviewItem {
  const OutletReviewItem(this.label, this.value);

  final String label;
  final String value;
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.item});

  final OutletReviewItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(item.value),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 180,
              child: Text(
                item.label,
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Text(item.value)),
          ],
        );
      },
    );
  }
}
