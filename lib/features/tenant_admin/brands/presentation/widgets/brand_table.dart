import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < TenantAdminBreakpoints.smallTablet) {
          return _BrandMobileCardList(
            brands: brands,
            canEdit: canEdit,
            canDelete: canDelete,
          );
        }

        return TenantAdminDataTable(
          showCheckboxColumn: false,
          emptyTitle: 'No brands found',
          emptyMessage: 'Add a brand to use it when creating products.',
          columns: const [
            DataColumn(label: Text('Brand Logo')),
            DataColumn(label: Text('Brand Name')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Product Count'), numeric: true),
            DataColumn(label: Text('Sort Order'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Updated On')),
            DataColumn(label: Text('Actions')),
          ],
          rows: [
            for (final brand in brands)
              DataRow(
                cells: [
                  DataCell(brandLogoAvatar(brand)),
                  DataCell(Text(brand.name)),
                  DataCell(Text(brand.code)),
                  DataCell(Text('${brand.productCount}')),
                  DataCell(Text('${brand.sortOrder}')),
                  DataCell(
                    TenantAdminStatusBadge(
                      label: brand.isActive ? 'Active' : 'Inactive',
                      status: brand.isActive
                          ? TenantAdminStatusType.active
                          : TenantAdminStatusType.inactive,
                    ),
                  ),
                  DataCell(Text(formatBrandUpdatedOn(brand.updatedAt))),
                  DataCell(
                    Row(
                      children: [
                        if (canEdit)
                          IconButton(
                            tooltip: 'Edit brand',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => openBrandDetailsPanel(
                              context: context,
                              existing: brand,
                              canSave: canEdit,
                            ),
                          ),
                        if (canDelete)
                          IconButton(
                            tooltip: 'Delete brand',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: TenantAdminColors.danger,
                            ),
                            onPressed: () => _deleteBrand(context, ref, brand),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _BrandMobileCardList extends ConsumerWidget {
  const _BrandMobileCardList({
    required this.brands,
    required this.canEdit,
    required this.canDelete,
  });

  final List<Brand> brands;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (brands.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brands.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: TenantAdminSpacing.md),
      itemBuilder: (context, index) {
        final brand = brands[index];
        return TenantAdminMobileListCard(
          leading: brandLogoAvatar(brand, size: 48),
          title: brand.name,
          subtitle: '${brand.code} · ${brand.productCount} products',
          trailing: TenantAdminStatusBadge(
            label: brand.isActive ? 'Active' : 'Inactive',
            status: brand.isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
          footer: Row(
            children: [
              Text(
                'Sort ${brand.sortOrder} · ${formatBrandUpdatedOn(brand.updatedAt)}',
                style: TenantAdminTextStyles.muted(context),
              ),
              const Spacer(),
              if (canEdit)
                IconButton(
                  tooltip: 'Edit brand',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => openBrandDetailsPanel(
                    context: context,
                    existing: brand,
                    canSave: canEdit,
                  ),
                ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete brand',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: TenantAdminColors.danger,
                  ),
                  onPressed: () => _deleteBrand(context, ref, brand),
                ),
            ],
          ),
        );
      },
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

  if (confirmed != true || !context.mounted) {
    return;
  }

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
