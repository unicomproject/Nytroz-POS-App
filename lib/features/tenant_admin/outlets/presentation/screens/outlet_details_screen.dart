import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet_detail_entities.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../providers/outlet_detail_providers.dart';
import '../providers/outlet_details_visibility_provider.dart';
import '../providers/outlet_visibility_provider.dart';
import '../widgets/outlet_assigned_users_tab.dart';
import '../widgets/outlet_detail_header.dart';
import '../widgets/outlet_information_tab.dart';
import '../widgets/outlet_revenue_tab.dart';
import '../widgets/outlet_tabs.dart';
import '../widgets/outlet_tills_tab.dart';

class OutletDetailsScreen extends ConsumerStatefulWidget {
  const OutletDetailsScreen({
    super.key,
    required this.outletId,
  });

  final String outletId;

  @override
  ConsumerState<OutletDetailsScreen> createState() =>
      _OutletDetailsScreenState();
}

class _OutletDetailsScreenState extends ConsumerState<OutletDetailsScreen> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(outletDetailProvider(widget.outletId));
    final visibilityState = ref.watch(outletDetailsVisibilityProvider);
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final outletsState = ref.watch(outletListProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminErrorState(
          title: 'Unable to load access',
          message: 'Please try again.',
          onRetry: () => ref.refresh(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canViewOutletDetail()) {
          return const TenantAdminPageScaffold(
            title: 'Outlet details',
            subtitle: 'View and manage this outlet in one place.',
            child: TenantAdminErrorState(
              title: 'No access to outlet details',
              message: 'You do not have permission to view this outlet.',
            ),
          );
        }

        return detailState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlet',
          message: 'Please try again.',
          onRetry: () => ref.refresh(outletDetailProvider(widget.outletId)),
        ),
      ),
      data: (outlet) => visibilityState.when(
        loading: () => const TenantAdminPageScaffold(
          title: 'Outlet details',
          subtitle: 'View and manage this outlet in one place.',
          child: TenantAdminLoadingSkeleton(rowCount: 8),
        ),
        error: (error, stackTrace) => TenantAdminPageScaffold(
          title: 'Outlet details',
          subtitle: 'View and manage this outlet in one place.',
          child: TenantAdminErrorState(
            title: 'Unable to load permissions',
            message: 'Please try again.',
            onRetry: () => ref.refresh(outletDetailsVisibilityProvider),
          ),
        ),
        data: (visibility) {
          final tabs = visibility.visibleTabs;
          if (tabs.isEmpty) {
            return TenantAdminPageScaffold(
              title: outlet.outletName,
              subtitle: 'View and manage this outlet in one place.',
              child: const TenantAdminErrorState(
                title: 'No tabs available',
                message: 'You do not have permission to view outlet detail sections.',
              ),
            );
          }

          final selectedTab =
              _selectedTab.clamp(0, tabs.length - 1);
          final outletOptions = outletsState.maybeWhen(
            data: (result) => result?.items
                    .map(
                      (item) => OutletDetail(
                        outletId: item.id,
                        outletName: item.name,
                        outletCode: item.code,
                        outletType: item.outletType ?? 'STORE',
                        status: item.status,
                      ),
                    )
                    .toList(growable: false) ??
                [outlet],
            orElse: () => [outlet],
          );

          return TenantAdminPageScaffold(
            title: outlet.outletName,
            subtitle: 'View and manage this outlet in one place.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutletDetailHeader(
                  outlet: outlet,
                  canEdit: access.canEditOutlet(),
                  outletOptions: outletOptions,
                  onOutletSelected: (id) =>
                      context.go('/tenant-admin/outlets/$id'),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                OutletTabs(
                  tabs: tabs,
                  selectedIndex: selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                _TabContent(
                  tabId: tabs[selectedTab].id,
                  outletId: widget.outletId,
                  outlet: outlet,
                  canEdit: access.canEditOutlet(),
                ),
              ],
            ),
          );
        },
      ),
    );
      },
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tabId,
    required this.outletId,
    required this.outlet,
    required this.canEdit,
  });

  final String tabId;
  final String outletId;
  final OutletDetail outlet;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    switch (tabId) {
      case 'revenue':
        return OutletRevenueTab(outletId: outletId);
      case 'assigned-users':
        return OutletAssignedUsersTab(outletId: outletId);
      case 'tills':
        return OutletTillsTab(outletId: outletId);
      case 'information':
        return OutletInformationTab(
          outlet: outlet,
          canEdit: canEdit,
          onEdit: () => context.go('/tenant-admin/outlets/$outletId/edit'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
