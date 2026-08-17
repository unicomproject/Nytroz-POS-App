import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/brand_providers.dart';
import 'brand_details_side_panel.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';

const double _brandDesktopViewportBreakpoint = 1024;

class BrandTable extends ConsumerWidget {
  const BrandTable({
    super.key,
    required this.result,
    required this.canEdit,
    required this.canDelete,
    required this.onSelect,
  });

  final BrandListResult result;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<Brand> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      if (MediaQuery.sizeOf(context).width < _brandDesktopViewportBreakpoint) {
        return _BrandMobileCardList(
          brands: result.items,
          canEdit: canEdit,
          canDelete: canDelete,
          onSelect: onSelect,
        );
      }
      return TenantAdminDataTable(
        key: const Key('brand-data-table'),
        fillAvailableWidth: true,
        showCheckboxColumn: false,
        emptyTitle: 'No brands found',
        emptyMessage: 'Add a brand to use it when creating products.',
        footer: _BrandPagination(result: result),
        columns: const [
          DataColumn(label: _Centered('Brand Logo')),
          DataColumn(label: _Centered('Brand Name')),
          DataColumn(label: _Centered('Code')),
          DataColumn(label: _Centered('Product Count')),
          DataColumn(label: _Centered('Status')),
          DataColumn(label: _Centered('Updated On')),
          DataColumn(label: _Centered('Actions')),
        ],
        rows: [
          for (final brand in result.items)
            DataRow(
              selected: ref.watch(selectedBrandIdProvider) == brand.id,
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TenantAdminColors.posHomeOrangeEnd
                      .withValues(alpha: 0.08);
                }
                return null;
              }),
              onSelectChanged: (_) => onSelect(brand),
              cells: [
                DataCell(_Centered.child(child: brandLogoAvatar(brand))),
                DataCell(_Centered(brand.name)),
                DataCell(_Centered(brand.code)),
                DataCell(_Centered('${brand.productCount}')),
                DataCell(_Centered.child(
                  child: TenantAdminStatusBadge(
                    label: brand.isActive ? 'Active' : 'Inactive',
                    status: brand.isActive
                        ? TenantAdminStatusType.active
                        : TenantAdminStatusType.inactive,
                  ),
                )),
                DataCell(_Centered(formatBrandUpdatedOn(brand.updatedAt))),
                DataCell(_Centered.child(
                    child: _Actions(
                  brand: brand,
                  canEdit: canEdit,
                  canDelete: canDelete,
                ))),
              ],
            ),
        ],
      );
    });
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text) : child = null;
  const _Centered.child({required this.child}) : text = null;
  final String? text;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Center(
        child: child ?? Text(text!, textAlign: TextAlign.center),
      );
}

class _Actions extends ConsumerWidget {
  const _Actions(
      {required this.brand, required this.canEdit, required this.canDelete});
  final Brand brand;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit brand',
              style: IconButton.styleFrom(
                fixedSize: const Size(34, 34),
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
              ),
              onPressed: () =>
                  context.go(ProductsSidebarRoutes.editBrand(brand.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canEdit && canDelete) const SizedBox(width: 8),
          if (canDelete)
            IconButton(
              tooltip: 'Delete brand',
              style: IconButton.styleFrom(
                fixedSize: const Size(34, 34),
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
                foregroundColor: TenantAdminColors.danger,
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
              ),
              onPressed: () => _deleteBrand(context, ref, brand),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      );
}

class _BrandPagination extends ConsumerWidget {
  const _BrandPagination({required this.result});
  final BrandListResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = result.totalCount == 0
        ? 0
        : ((result.pageNumber - 1) * result.pageSize) + 1;
    final end =
        (result.pageNumber * result.pageSize).clamp(0, result.totalCount);
    return Padding(
      key: const Key('brand-pagination'),
      padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg, vertical: TenantAdminSpacing.sm),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: TenantAdminSpacing.md,
        children: [
          Text('Showing $start to $end of ${result.totalCount} brands',
              style: TenantAdminTextStyles.muted(context)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Semantics(
              label: 'Brands per page',
              child: DropdownButton<int>(
                value: result.pageSize,
                iconEnabledColor: TenantAdminColors.posHomeOrangeEnd,
                underline: Container(
                  height: 1,
                  color: TenantAdminColors.posHomeOrangeEnd,
                ),
                items: const [5, 10, 25]
                    .map((size) =>
                        DropdownMenuItem(value: size, child: Text('$size')))
                    .toList(),
                onChanged: (size) {
                  if (size == null) return;
                  ref.read(brandPageSizeProvider.notifier).state = size;
                  ref.read(brandPageProvider.notifier).state = 1;
                },
              ),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: result.pageNumber > 1
                  ? () => ref.read(brandPageProvider.notifier).state =
                      result.pageNumber - 1
                  : null,
              icon: const Icon(Icons.chevron_left),
              color: TenantAdminColors.bodyText,
              disabledColor: TenantAdminColors.mutedText,
            ),
            Container(
              key: const Key('brand-active-page'),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TenantAdminColors.posHomeOrangeEnd,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm)),
              child: Text('${result.pageNumber}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: result.pageNumber < result.totalPages
                  ? () => ref.read(brandPageProvider.notifier).state =
                      result.pageNumber + 1
                  : null,
              icon: const Icon(Icons.chevron_right),
              color: TenantAdminColors.bodyText,
              disabledColor: TenantAdminColors.mutedText,
            ),
          ]),
        ],
      ),
    );
  }
}

class _BrandMobileCardList extends ConsumerWidget {
  const _BrandMobileCardList(
      {required this.brands,
      required this.canEdit,
      required this.canDelete,
      required this.onSelect});
  final List<Brand> brands;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<Brand> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: brands.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: TenantAdminSpacing.md),
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Semantics(
            button: true,
            selected: ref.watch(selectedBrandIdProvider) == brand.id,
            label: 'View ${brand.name} brand details',
            child: InkWell(
              onTap: () => onSelect(brand),
              child: TenantAdminMobileListCard(
                leading: brandLogoAvatar(brand, size: 48),
                title: brand.name,
                subtitle: '${brand.code} · ${brand.productCount} products',
                trailing: TenantAdminStatusBadge(
                  label: brand.isActive ? 'Active' : 'Inactive',
                  status: brand.isActive
                      ? TenantAdminStatusType.active
                      : TenantAdminStatusType.inactive,
                ),
                footer: Row(children: [
                  Expanded(
                      child: Text(formatBrandUpdatedOn(brand.updatedAt),
                          style: TenantAdminTextStyles.muted(context))),
                  _Actions(
                      brand: brand, canEdit: canEdit, canDelete: canDelete),
                ]),
              ),
            ),
          );
        },
      );
}

Future<void> _deleteBrand(
    BuildContext context, WidgetRef ref, Brand brand) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete brand'),
      content: Text('Delete "${brand.name}"? This cannot be undone.'),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: TenantAdminColors.posHomeOrangeEnd),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: TenantAdminColors.posHomeOrangeEnd),
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
          const SnackBar(content: Text('Brand deleted successfully.')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(brandApiErrorMessage(error))));
    }
  }
}
