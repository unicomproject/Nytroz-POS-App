import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/brand_providers.dart';
import 'brand_details_side_panel.dart';

class BrandTable extends ConsumerWidget {
  const BrandTable({
    super.key,
    required this.brands,
    required this.canEdit,
    required this.canDelete,
  });

  final List<Brand> brands;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brands.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _BrandCard(
        brand: brands[index],
        canEdit: canEdit,
        canDelete: canDelete,
        onEdit: () => openBrandDetailsPanel(
          context: context,
          existing: brands[index],
          canSave: canEdit,
        ),
        onDelete: () => _deleteBrand(context, ref, brands[index]),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Brand brand;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final information = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            brandLogoAvatar(brand, size: compact ? 52 : 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          brand.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _BrandTypeBadge(),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 22,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      _BrandMetric(label: 'Code', value: brand.code),
                      _BrandMetric(
                        label: 'Products',
                        value: '${brand.productCount}',
                      ),
                      _BrandMetric(
                        label: 'Sort Order',
                        value: '${brand.sortOrder}',
                      ),
                      _BrandMetric(
                        label: 'Updated',
                        value: formatBrandUpdatedOn(brand.updatedAt),
                      ),
                      TenantAdminStatusBadge(
                        label: brand.isActive ? 'Active' : 'Inactive',
                        status: brand.isActive
                            ? TenantAdminStatusType.active
                            : TenantAdminStatusType.inactive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = _BrandActions(
          canEdit: canEdit,
          canDelete: canDelete,
          onEdit: onEdit,
          onDelete: onDelete,
          horizontal: compact,
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    information,
                    if (canEdit || canDelete) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: TenantAdminColors.border),
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: information),
                    if (canEdit || canDelete) ...[
                      const SizedBox(width: 16),
                      actions,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _BrandTypeBadge extends StatelessWidget {
  const _BrandTypeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: TenantAdminColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'BRAND',
        style: TextStyle(
          color: TenantAdminColors.success,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BrandMetric extends StatelessWidget {
  const _BrandMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BrandActions extends StatelessWidget {
  const _BrandActions({
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.horizontal,
  });

  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (canEdit)
        TenantAdminRowAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onPressed: onEdit,
        ),
      if (canEdit && canDelete)
        SizedBox(width: horizontal ? 6 : 0, height: horizontal ? 0 : 4),
      if (canDelete)
        TenantAdminRowAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          destructive: true,
          onPressed: onDelete,
        ),
    ];

    return horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: children,
          );
  }
}

Future<void> _deleteBrand(
  BuildContext context,
  WidgetRef ref,
  Brand brand,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete brand'),
      content: Text('Delete "${brand.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(brandSaveControllerProvider.notifier).delete(brand.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand deleted successfully.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(brandApiErrorMessage(error))),
      );
    }
  }
}
