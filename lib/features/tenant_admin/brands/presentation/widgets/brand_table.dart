import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/brand_providers.dart';
import 'brand_form_dialog.dart';

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
    return TenantAdminDataTable(
      showCheckboxColumn: false,
      emptyTitle: 'No brands found',
      emptyMessage: 'Add a brand to use it when creating products.',
      columns: const [
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: [
        for (final brand in brands)
          DataRow(
            cells: [
              DataCell(Text(brand.name)),
              DataCell(Text(brand.code)),
              DataCell(
                TenantAdminStatusBadge(
                  label: brand.isActive ? 'Active' : 'Inactive',
                  status: brand.isActive
                      ? TenantAdminStatusType.active
                      : TenantAdminStatusType.inactive,
                ),
              ),
              DataCell(
                Row(
                  children: [
                    if (canEdit)
                      IconButton(
                        tooltip: 'Edit brand',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editBrand(context, ref, brand),
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
  }

  Future<void> _editBrand(
    BuildContext context,
    WidgetRef ref,
    Brand brand,
  ) async {
    final input = await showBrandFormDialog(context: context, existing: brand);
    if (input == null || !context.mounted) {
      return;
    }

    try {
      await ref.read(brandSaveControllerProvider.notifier).save(
            brandId: brand.id,
            input: input,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brand updated successfully.')),
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
}
