import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/layout/tenant_admin_breadcrumb.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/brand.dart';
import '../providers/brand_providers.dart';
import '../providers/brand_visibility_provider.dart';
import '../widgets/brand_details_side_panel.dart';
import '../widgets/brand_table.dart';

const double _brandInlineDetailViewportBreakpoint = 1024;

bool _showsInlineBrandDetails(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= _brandInlineDetailViewportBreakpoint;

class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(brandListVisibilityProvider);
    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Brands Management',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (_, __) => TenantAdminPageScaffold(
        title: 'Brands Management',
        child: TenantAdminErrorState(
          title: 'Unable to load brands',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(brandListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Brands',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view brands.',
              icon: Icons.sell_outlined,
            ),
          );
        }

        return LayoutBuilder(builder: (context, _) {
          final selectedId = ref.watch(selectedBrandIdProvider);
          final showInlineDetails =
              selectedId != null && _showsInlineBrandDetails(context);
          final list = _BrandListWorkspace(visibility: visibility);

          return Padding(
            padding: const EdgeInsets.only(top: TenantAdminSpacing.sm),
            child: Container(
              key: const Key('brand-shared-workspace'),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: TenantAdminShadows.card,
              ),
              child: showInlineDetails
                  ? Row(
                      key: const Key('brand-selected-layout'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 75, child: list),
                        const VerticalDivider(
                          key: Key('brand-workspace-divider'),
                          width: 1,
                          thickness: 1,
                          color: TenantAdminColors.border,
                        ),
                        Expanded(
                          flex: 25,
                          child: BrandDetailsSidePanel(brandId: selectedId),
                        ),
                      ],
                    )
                  : list,
            ),
          );
        });
      },
    );
  }
}

class _BrandListWorkspace extends ConsumerWidget {
  const _BrandListWorkspace({required this.visibility});
  final BrandListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      key: Key(ref.watch(selectedBrandIdProvider) == null
          ? 'brand-full-width-list'
          : 'brand-reduced-width-list'),
      color: TenantAdminColors.surface,
      child: SingleChildScrollView(
        padding: TenantAdminInsets.pageForWidth(
          MediaQuery.sizeOf(context).width,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TenantAdminBreadcrumb(
              items: [
                TenantAdminBreadcrumbItem(label: 'Product'),
                TenantAdminBreadcrumbItem(label: 'Brand'),
                TenantAdminBreadcrumbItem(label: 'Brand Management'),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visibility.showTitle)
                  Expanded(
                    child: Text(
                      'Brands Management',
                      style: TenantAdminTextStyles.pageTitle(context),
                    ),
                  )
                else
                  const Spacer(),
                if (visibility.showAddBrand)
                  TenantAdminPrimaryButton(
                    key: const Key('add-brand-button'),
                    label: 'Add Brand',
                    icon: Icons.add,
                    backgroundColor: TenantAdminColors.posHomeOrangeEnd,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Add Brand page implementation deferred.'),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            if (visibility.showSearch) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TenantAdminSearchField(
                    hint: 'Search brands...',
                    value: ref.watch(brandSearchProvider),
                    focusedBorderColor: TenantAdminColors.posHomeAccentOrange,
                    onChanged: (value) {
                      ref.read(brandSearchProvider.notifier).state = value;
                      ref.read(brandPageProvider.notifier).state = 1;
                    },
                  ),
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            if (visibility.showList) _BrandListBody(visibility: visibility),
          ],
        ),
      ),
    );
  }
}

class _BrandListBody extends ConsumerWidget {
  const _BrandListBody({required this.visibility});
  final BrandListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsState = ref.watch(brandListScreenProvider);
    return brandsState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (_, __) => TenantAdminErrorState(
        title: 'Unable to load brands',
        message: 'Please try again.',
        onRetry: () => ref.refresh(brandListScreenProvider),
      ),
      data: (result) {
        if (result == null) {
          return const TenantAdminEmptyState(
            title: 'No access',
            message: 'You do not have permission to view brands.',
            icon: Icons.sell_outlined,
          );
        }

        final selectedId = ref.read(selectedBrandIdProvider);
        if (selectedId != null &&
            !result.items.any((brand) => brand.id == selectedId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(selectedBrandIdProvider) == selectedId) {
              ref.read(selectedBrandIdProvider.notifier).state = null;
            }
          });
        }

        if (result.items.isEmpty) {
          final search = ref.watch(brandSearchProvider).trim();
          return TenantAdminEmptyState(
            title: search.isEmpty ? 'No brands yet' : 'No search results',
            message: search.isEmpty
                ? 'Add a brand to use it when creating products.'
                : 'No brands match "$search".',
            icon: Icons.sell_outlined,
          );
        }

        return BrandTable(
          result: result,
          canEdit: visibility.showEditBrand,
          canDelete: visibility.showDeleteBrand,
          onSelect: (brand) => _selectBrand(context, ref, brand),
        );
      },
    );
  }

  Future<void> _selectBrand(
      BuildContext context, WidgetRef ref, Brand brand) async {
    final selection = ref.read(selectedBrandIdProvider.notifier);
    selection.state = brand.id;
    if (_showsInlineBrandDetails(context)) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.92,
        child: BrandDetailsSidePanel(
          brandId: brand.id,
          onClose: () {
            selection.state = null;
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
    if (selection.state == brand.id) {
      selection.state = null;
    }
  }
}
