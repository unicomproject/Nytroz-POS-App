import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/tenant_admin_access_provider.dart';
import '../../../widgets/tenant_admin_buttons.dart';
import '../../../widgets/tenant_admin_filter_chip.dart';
import '../../../widgets/tenant_admin_page_scaffold.dart';
import '../../../widgets/tenant_admin_search_field.dart';
import '../../../widgets/tenant_admin_states.dart';
import '../providers/outlet_providers.dart';
import '../widgets/outlet_metric_cards.dart';
import '../widgets/outlet_mobile_list.dart';
import '../widgets/outlet_table.dart';

class OutletListScreen extends ConsumerWidget {
  const OutletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsState = ref.watch(outletListProvider);
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final canCreate = accessState.maybeWhen(
      data: (checker) => checker.canShowAction(
        'tenant_admin.outlets',
        'outlets.create',
      ),
      orElse: () => false,
    );
    final canUpdate = accessState.maybeWhen(
      data: (checker) => checker.canShowAction(
        'tenant_admin.outlets',
        'outlets.update',
      ),
      orElse: () => false,
    );

    return outletsState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlets',
          message: 'Please try again.',
          onRetry: () => ref.refresh(outletListProvider),
        ),
      ),
      data: (result) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return TenantAdminPageScaffold(
              title: 'Outlets',
              subtitle: 'Manage the places where your business sells.',
              actions: [
                if (canCreate)
                  TenantAdminPrimaryButton(
                    label: isMobile ? 'Add' : 'Add outlet',
                    icon: Icons.add,
                    onPressed: () => context.go('/tenant-admin/outlets/add'),
                  ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TenantAdminSearchField(
                          hint: 'Search outlets...',
                          value: ref.watch(outletSearchProvider),
                          onChanged: (value) {
                            ref.read(outletSearchProvider.notifier).state = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      TenantAdminSecondaryButton(
                        label: 'Filters',
                        icon: Icons.filter_list,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TenantAdminFilterChip(
                        label: 'All',
                        selected: true,
                        count: result.summary.totalOutlets,
                        onTap: () {},
                      ),
                      TenantAdminFilterChip(
                        label: 'Active',
                        selected: false,
                        count: result.summary.activeOutlets,
                        onTap: () {},
                      ),
                      TenantAdminFilterChip(
                        label: 'Inactive',
                        selected: false,
                        count: result.summary.inactiveOutlets,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutletMetricCards(summary: result.summary, compact: isMobile),
                  const SizedBox(height: 24),
                  if (result.items.isEmpty)
                    const TenantAdminEmptyState(
                      title: 'No outlets found',
                      message: 'Create an outlet or adjust your search.',
                    )
                  else if (isMobile)
                    OutletMobileList(outlets: result.items)
                  else
                    OutletTable(
                      outlets: result.items,
                      canUpdate: canUpdate,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
