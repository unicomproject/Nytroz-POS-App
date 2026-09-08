import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../application/tax_management_controller.dart';
import '../domain/tax_aggregate.dart';
import '../domain/tax_status.dart';
import 'providers/tax_list_providers.dart';
import 'providers/tax_visibility_provider.dart';
import 'tax_setup_details_page.dart';
import 'tax_setup_form_page.dart';
import 'widgets/tax_setup_table.dart';

class TaxManagementPage extends ConsumerWidget {
  const TaxManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(taxListVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Tax Setup',
        subtitle: 'Manage tax rates used by your products.',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Tax Setup',
        subtitle: 'Manage tax rates used by your products.',
        child: TenantAdminErrorState(
          title: 'Unable to load access rules',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(taxListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Tax Setup',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view tax setups.',
              icon: Icons.receipt_long_outlined,
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: visibility.showTitle ? 'Tax Setup' : '',
          subtitle: visibility.showSubtitle
              ? 'Manage tax rates used by your products.'
              : null,
          scrollable: false,
          fillHeight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaxToolbar(visibility: visibility),
              const SizedBox(height: TenantAdminSpacing.lg),
              if (visibility.showList)
                const Expanded(child: _TaxListBody()),
            ],
          ),
        );
      },
    );
  }
}

class _TaxToolbar extends ConsumerWidget {
  const _TaxToolbar({required this.visibility});

  final TaxSetupListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(taxStatusFilterProvider);
    final filtersActive = taxListFiltersActive(ref);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            constraints.maxWidth < TenantAdminBreakpoints.smallTablet;

        final search = TenantAdminSearchField(
          hint: 'Search tax by name or code...',
          value: ref.watch(taxSearchProvider),
          onChanged: (value) {
            ref.read(taxSearchProvider.notifier).state = value;
            ref.read(taxPageProvider.notifier).state = 1;
          },
        );

        final statusDropdown = SizedBox(
          height: 40,
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TaxStatus?>(
                value: statusFilter,
                isExpanded: true,
                hint: const Text('Status: All'),
                items: const [
                  DropdownMenuItem<TaxStatus?>(
                    value: null,
                    child: Text('All'),
                  ),
                  DropdownMenuItem<TaxStatus?>(
                    value: TaxStatus.active,
                    child: Text('Active'),
                  ),
                  DropdownMenuItem<TaxStatus?>(
                    value: TaxStatus.inactive,
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  ref.read(taxStatusFilterProvider.notifier).state = value;
                  ref.read(taxPageProvider.notifier).state = 1;
                },
              ),
            ),
          ),
        );

        final resetButton = filtersActive
            ? SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () => resetTaxListFilters(ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.primary,
                    side: const BorderSide(color: TenantAdminColors.border),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Reset'),
                ),
              )
            : const SizedBox.shrink();

        final addButton = visibility.showCreate
            ? TenantAdminPrimaryButton(
                label: 'Add Tax Setup',
                icon: Icons.add,
                backgroundColor: TenantAdminColors.posHomeAccentOrange,
                onPressed: () => _openForm(context, ref),
              )
            : null;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visibility.showSearch) search,
              if (visibility.showSearch)
                const SizedBox(height: TenantAdminSpacing.sm),
              statusDropdown,
              if (filtersActive) ...[
                const SizedBox(height: TenantAdminSpacing.sm),
                resetButton,
              ],
              if (addButton != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                addButton,
              ],
            ],
          );
        }

        return Row(
          children: [
            if (visibility.showSearch)
              Expanded(flex: 4, child: search),
            if (visibility.showSearch)
              const SizedBox(width: TenantAdminSpacing.sm),
            SizedBox(width: 160, child: statusDropdown),
            if (filtersActive) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              resetButton,
            ],
            if (addButton != null) ...[
              const SizedBox(width: TenantAdminSpacing.lg),
              addButton,
            ],
          ],
        );
      },
    );
  }
}

class _TaxListBody extends ConsumerWidget {
  const _TaxListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(taxListVisibilityProvider).valueOrNull;
    final listState = ref.watch(taxListScreenProvider);

    if (visibility == null) {
      return const TenantAdminLoadingSkeleton(rowCount: 6);
    }

    return listState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load tax setups',
        message: taxApiErrorMessage(error),
        onRetry: () => ref.invalidate(taxListScreenProvider),
      ),
      data: (result) {
        if (result == null) {
          return const TenantAdminEmptyState(
            title: 'No access',
            message: 'You do not have permission to view tax setups.',
            icon: Icons.receipt_long_outlined,
          );
        }

        final filtersActive = taxListFiltersActive(ref);
        if (result.items.isEmpty) {
          if (!filtersActive) {
            return TenantAdminEmptyState(
              title: 'No tax setups yet',
              message: 'No tax setups have been created yet.',
              icon: Icons.receipt_long_outlined,
              action: visibility.showCreate
                  ? TenantAdminPrimaryButton(
                      label: 'Add Tax Setup',
                      icon: Icons.add,
                      backgroundColor: TenantAdminColors.posHomeAccentOrange,
                      onPressed: () => _openForm(context, ref),
                    )
                  : null,
            );
          }

          return TenantAdminEmptyState(
            title: 'No matching tax setups',
            message: 'No tax setups match your search or filters.',
            icon: Icons.search_off_outlined,
            action: OutlinedButton(
              onPressed: () => resetTaxListFilters(ref),
              child: const Text('Reset'),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: TaxSetupTable(
                items: result.items,
                visibility: visibility,
                onOpen: (tax) => _openDetails(context, ref, taxId: tax.id),
                onEdit: (tax) => _openForm(context, ref, taxId: tax.id),
                onActivate: (tax) => _activate(context, ref, tax),
                onDeactivate: (tax) =>
                    _confirmDeactivate(context, ref, tax),
              ),
            ),
            if (result.totalCount > 0)
              TenantAdminPaginationBar(
                currentPage: result.pageNumber,
                pageSize: result.pageSize,
                totalCount: result.totalCount,
                itemLabel: 'tax setups',
                onPageChanged: (page) =>
                    ref.read(taxPageProvider.notifier).state = page,
              ),
          ],
        );
      },
    );
  }
}

Future<void> _openDetails(
  BuildContext context,
  WidgetRef ref, {
  required String taxId,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TaxSetupDetailsPage(taxId: taxId),
    ),
  );
  ref.invalidate(taxListProvider);
}

Future<void> _openForm(
  BuildContext context,
  WidgetRef ref, {
  String? taxId,
}) async {
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => TaxSetupFormPage(taxId: taxId),
    ),
  );
  if (changed == true) {
    ref.invalidate(taxListProvider);
  }
}

Future<void> _activate(
  BuildContext context,
  WidgetRef ref,
  TaxSetup tax,
) async {
  try {
    await ref.read(taxMutationControllerProvider.notifier).activate(tax.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax setup activated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(taxApiErrorMessage(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _confirmDeactivate(
  BuildContext context,
  WidgetRef ref,
  TaxSetup tax,
) async {
  final action = await showDialog<_DeactivateChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Deactivate tax setup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This tax setup is currently used by ${tax.productCount} products.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Existing products will retain this tax assignment, but the tax will no longer be available for new assignments.',
          ),
          const SizedBox(height: 12),
          const Text('Historical transactions remain unchanged.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _DeactivateChoice.keep),
          child: const Text('Keep Active'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TenantAdminColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.pop(context, _DeactivateChoice.deactivate),
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );

  if (!context.mounted ||
      action == null ||
      action == _DeactivateChoice.keep) {
    return;
  }

  try {
    await ref.read(taxMutationControllerProvider.notifier).deactivate(tax.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax setup deactivated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(taxApiErrorMessage(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _DeactivateChoice { keep, deactivate }
