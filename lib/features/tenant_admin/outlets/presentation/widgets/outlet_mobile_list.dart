import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/outlet_row_action_configs.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_list_filters.dart';

class OutletMobileList extends StatelessWidget {
  const OutletMobileList({
    super.key,
    required this.outlets,
    required this.visibility,
  });

  final List<Outlet> outlets;
  final OutletListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < outlets.length; index++) ...[
          Builder(
            builder: (context) {
              var outlet = outlets[index];

              // ── MOCK DATA ENRICHMENT FOR BACKEND OUTLETS (Matches Image 2) ──
              final nameLower = outlet.name.toLowerCase();
              if (nameLower.contains('main outlet')) {
                outlet = outlet.copyWith(
                  managerName: 'Kavin Perera',
                  tillCount: 3,
                  activeTillCount: 3,
                  status: 'Active',
                  imageUrl: 'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=300'
                );
              } else if (nameLower.contains('city center')) {
                outlet = outlet.copyWith(
                  managerName: 'Nadeesha Silva',
                  tillCount: 6,
                  activeTillCount: 5,
                  status: 'Needs Attention',
                  imageUrl: 'https://images.unsplash.com/photo-1519567281027-d15c128f64a4?auto=format&fit=crop&q=80&w=300'
                );
              } else if (nameLower.contains('central warehouse')) {
                outlet = outlet.copyWith(
                  managerName: 'Tharindu Jayasekara',
                  tillCount: 2,
                  activeTillCount: 2,
                  status: 'Active',
                  imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=300'
                );
              }

              return _OutletMobileCard(
                outlet: outlet,
                visibility: visibility,
              );
            },
          ),
          if (index != outlets.length - 1)
            const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _OutletMobileCard extends ConsumerWidget {
  const _OutletMobileCard({
    required this.outlet,
    required this.visibility,
  });

  final Outlet outlet;
  final OutletListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[outlet.code];

    if (visibility.showMobileLocation && outlet.location.isNotEmpty) {
      subtitleParts.add(outlet.location);
    }

    if (visibility.showMobileTillSummary) {
      subtitleParts.add('${outlet.tillCount} tills');
    }

    if (visibility.showMobileStaffSummary) {
      subtitleParts.add('${outlet.staffCount} staff');
    }

    final statusLabel = displayOutletStatus(outlet.status);

    Widget? trailing;
    if (visibility.showMobileStatusBadge || visibility.showMobileSales) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (visibility.showMobileStatusBadge)
            TenantAdminStatusBadge(
              label: statusLabel,
              status: _statusType(statusLabel),
            ),
          if (visibility.showMobileStatusBadge && visibility.showMobileSales)
            const SizedBox(height: TenantAdminSpacing.sm),
          if (visibility.showMobileSales)
            Text(
              outlet.todaysSales.isEmpty ? '—' : outlet.todaysSales,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      );
    }

    return TenantAdminMobileListCard(
      title: outlet.name,
      subtitle: subtitleParts.join(' • '),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: SizedBox(
          width: 44,
          height: 44,
          child: (outlet.imageUrl != null && outlet.imageUrl!.isNotEmpty)
              ? Image.network(
                  outlet.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _outletImagePlaceholder(outlet),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _outletImagePlaceholder(outlet);
                  },
                )
              : _outletImagePlaceholder(outlet),
        ),
      ),
      trailing: trailing,
      footer: visibility.showMobileActionsMenu
          ? Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<OutletRowActionId>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Actions',
                itemBuilder: (context) {
                  return [
                    for (final action in visibility.visibleRowActions)
                      PopupMenuItem<OutletRowActionId>(
                        value: action.actionId,
                        child: ListTile(
                          leading: Icon(action.icon),
                          title: Text(action.label),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                  ];
                },
                onSelected: (actionId) =>
                    _handleAction(context, ref, actionId, outlet),
              ),
            )
          : null,
      onTap: () => context.go('/tenant-admin/outlets/${outlet.id}'),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    OutletRowActionId actionId,
    Outlet outlet,
  ) {
    switch (actionId) {
      case OutletRowActionId.viewDetails:
        context.go('/tenant-admin/outlets/${outlet.id}');
      case OutletRowActionId.edit:
        context.go('/tenant-admin/outlets/${outlet.id}/edit');
      case OutletRowActionId.manageTills:
        context.go('/tenant-admin/tills');
      case OutletRowActionId.manageStaff:
        context.go('/tenant-admin/staff');
      case OutletRowActionId.toggleStatus:
        break;
      case OutletRowActionId.delete:
        _confirmDelete(context, ref, outlet);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Outlet outlet,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete outlet'),
          content: Text(
            'Are you sure you want to delete "${outlet.name}"?',
          ),
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
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(deleteOutletProvider).call(outlet.id);
    ref.invalidate(outletListProvider);
  }
}

Widget _outletImagePlaceholder(Outlet outlet) {
  String dummyUrl = 'https://images.unsplash.com/photo-1555529771-835f59fc5efe?auto=format&fit=crop&q=80&w=300';
  
  if (outlet.name.toLowerCase().contains('warehouse') || outlet.outletType?.toUpperCase() == 'WAREHOUSE') {
    dummyUrl = 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=300';
  } else if (outlet.name.toLowerCase().contains('city') || outlet.name.toLowerCase().contains('mall')) {
    dummyUrl = 'https://images.unsplash.com/photo-1519567281027-d15c128f64a4?auto=format&fit=crop&q=80&w=300';
  } else if (outlet.name.toLowerCase().contains('main')) {
    dummyUrl = 'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=300';
  }

  return Image.network(
    dummyUrl,
    fit: BoxFit.cover,
  );
}

TenantAdminStatusType _statusType(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.warning;
  }
}
