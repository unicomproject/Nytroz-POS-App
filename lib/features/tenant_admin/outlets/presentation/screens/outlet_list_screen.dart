import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/outlet.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_api_errors.dart';
import '../utils/outlet_list_filters.dart';
import '../widgets/outlet_list_panel.dart';

class OutletListScreen extends ConsumerWidget {
  const OutletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(outletListVisibilityProvider);
    final outletsState = ref.watch(outletListProvider);
    final statusFilter = ref.watch(outletStatusFilterProvider);

    return visibilityState.when(
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
          message: outletLoadErrorMessage(error),
          onRetry: () => ref.invalidate(outletListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Outlets',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view outlets.',
            ),
          );
        }

        return outletsState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Outlets' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage the places where your business sells.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Outlets',
            subtitle: 'Manage the places where your business sells.',
            child: TenantAdminErrorState(
              title: 'Unable to load outlets',
              message: outletLoadErrorMessage(error),
              onRetry: () => ref.refresh(outletListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Outlets',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view outlets.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final showDetailsPanel = constraints.maxWidth >= 1250;
                final selectedOutlet =
                    result.items.isEmpty ? null : result.items.first;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Outlets' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage the places where your business sells.'
                      : null,
                  actions: [
                    if (visibility.showAddOutlet)
                      TenantAdminPrimaryButton(
                        label: 'Add outlet',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go('/tenant-admin/outlets/add'),
                      ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSummarySection) ...[
                        _ProfessionalOutletStats(
                          result: result,
                          compact: isMobile,
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (visibility.showList)
                        if (showDetailsPanel)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: OutletListPanel(
                                  result: result,
                                  visibility: visibility,
                                  statusFilter: statusFilter,
                                  isMobile: isMobile,
                                  showPanelTitle: true,
                                  showAddButton: false,
                                ),
                              ),
                              const SizedBox(width: TenantAdminSpacing.xl),
                              SizedBox(
                                width: 340,
                                child:
                                    _OutletDetailPanel(outlet: selectedOutlet),
                              ),
                            ],
                          )
                        else
                          OutletListPanel(
                            result: result,
                            visibility: visibility,
                            statusFilter: statusFilter,
                            isMobile: isMobile,
                            showPanelTitle: true,
                            showAddButton: false,
                          ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProfessionalOutletStats extends StatelessWidget {
  const _ProfessionalOutletStats({
    required this.result,
    required this.compact,
  });

  final OutletListResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final totalTills = result.items.fold<int>(
      0,
      (total, outlet) => total + outlet.tillCount,
    );
    final cards = [
      _StatCardData(
        title: 'Total Outlets',
        value: '${result.summary.totalOutlets}',
        subtitle: 'All outlets in this tenant',
        icon: Icons.storefront_outlined,
        color: TenantAdminColors.primary,
      ),
      _StatCardData(
        title: 'Active Outlets',
        value: '${result.summary.activeOutlets}',
        subtitle: 'Outlets currently active',
        icon: Icons.check_circle_outline,
        color: TenantAdminColors.success,
      ),
      _StatCardData(
        title: 'Inactive Outlets',
        value: '${result.summary.inactiveOutlets}',
        subtitle: 'Outlets currently inactive',
        icon: Icons.storefront_outlined,
        color: TenantAdminColors.danger,
      ),
      _StatCardData(
        title: 'Total Tills',
        value: '$totalTills',
        subtitle: 'Across loaded outlets',
        icon: Icons.point_of_sale_outlined,
        color: TenantAdminColors.primary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: 116,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _ProfessionalStatCard(cards[index]),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ProfessionalStatCard extends StatelessWidget {
  const _ProfessionalStatCard(this.data);

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: data.color,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
        ],
      ),
    );
  }
}

class _OutletDetailPanel extends StatelessWidget {
  const _OutletDetailPanel({required this.outlet});

  final Outlet? outlet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: outlet == null
          ? const TenantAdminEmptyState(
              title: 'No outlet selected',
              message: 'Select an outlet to preview details.',
              icon: Icons.storefront_outlined,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: TenantAdminColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: TenantAdminColors.primary,
                      ),
                    ),
                    const Spacer(),
                    TenantAdminStatusBadge(
                      label: displayOutletStatus(outlet!.status),
                      status: _outletStatusType(outlet!.status),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Text(
                  outlet!.name,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  '${outlet!.code}  •  ${_fallback(outlet!.outletType, 'Store')}',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                _DetailTabs(),
                const SizedBox(height: TenantAdminSpacing.lg),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Manager',
                  value: outlet!.staffCount > 0
                      ? '${outlet!.staffCount} staff'
                      : '—',
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _fallback(outlet!.contactNumber, '—'),
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _fallback(outlet!.location, '—'),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(TenantAdminSpacing.md),
                  decoration: BoxDecoration(
                    color: TenantAdminColors.background,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outlet Summary',
                        style: TenantAdminTextStyles.sectionTitle(context)
                            .copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniSummary(
                              label: 'Tills',
                              value: '${outlet!.tillCount}',
                            ),
                          ),
                          const SizedBox(width: TenantAdminSpacing.sm),
                          Expanded(
                            child: _MiniSummary(
                              label: 'Online',
                              value: '${outlet!.onlineTillCount}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniSummary(
                              label: 'Staff',
                              value: '${outlet!.staffCount}',
                            ),
                          ),
                          const SizedBox(width: TenantAdminSpacing.sm),
                          Expanded(
                            child: _MiniSummary(
                              label: 'Sales',
                              value: _fallback(outlet!.todaysSales, '—'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: TenantAdminSecondaryButton(
                    label: 'View details',
                    icon: Icons.chevron_right,
                    onPressed: () => context.go(
                      '/tenant-admin/outlets/${outlet!.id}',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: TenantAdminSpacing.md,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        _DetailTab(label: 'Overview', active: true),
        _DetailTab(label: 'Tills'),
        _DetailTab(label: 'Details'),
      ],
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: active ? TenantAdminColors.primary : TenantAdminColors.bodyText,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TenantAdminColors.mutedText, size: 18),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TenantAdminTextStyles.muted(context)),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.sm),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TenantAdminTextStyles.muted(context)),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _fallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

TenantAdminStatusType _outletStatusType(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('active') && !normalized.contains('inactive')) {
    return TenantAdminStatusType.active;
  }
  if (normalized.contains('inactive')) {
    return TenantAdminStatusType.inactive;
  }
  return TenantAdminStatusType.pending;
}
