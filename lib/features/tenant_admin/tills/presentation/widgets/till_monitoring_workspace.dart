import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../domain/entities/till_monitoring.dart';
import '../providers/till_providers.dart';
import 'till_monitoring_summary_cards.dart';
import 'till_monitoring_toolbar.dart';
import 'till_monitoring_list.dart';
import 'till_monitoring_side_panel.dart';

/// Desktop master-detail workspace for Till Monitoring.
///
/// ```text
/// Summary cards (full width)
/// ┌─────────────────────┬──────────────────┐
/// │ Search + Filters    │ Selected Till    │
/// │ Till List           │ Cashier/Activity │
/// │                     │ Hardware/Alerts  │
/// └─────────────────────┴──────────────────┘
/// ```
class TillMonitoringWorkspace extends ConsumerStatefulWidget {
  const TillMonitoringWorkspace({
    super.key,
    required this.visibility,
  });

  final TillListVisibility visibility;

  static const double desktopBreakpoint = 1000;

  @override
  ConsumerState<TillMonitoringWorkspace> createState() =>
      _TillMonitoringWorkspaceState();
}

class _TillMonitoringWorkspaceState
    extends ConsumerState<TillMonitoringWorkspace> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >=
        TillMonitoringWorkspace.desktopBreakpoint;
    final selectedTillId = ref.watch(selectedTillIdProvider);
    final listState = ref.watch(tillListResultFutureProvider);

    ref.listen(tillListResultFutureProvider, (previous, next) {
      _ensureSelection(next.asData?.value);
    });

    final pendingResult = listState.asData?.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureSelection(pendingResult);
    });

    final selectedItem = _findSelectedItem(pendingResult, selectedTillId);

    Widget buildLeftPane({required bool boundedHeight}) {
      final list = TillMonitoringList(
        scrollable: boundedHeight,
        onTillSelected: (tillId) {
          ref.read(selectedTillIdProvider.notifier).state = tillId;
          if (!isDesktop && context.mounted) {
            context.go('/tenant-admin/tills/$tillId');
          }
        },
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TillMonitoringToolbar(visibility: widget.visibility),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (widget.visibility.showList)
            boundedHeight ? Expanded(child: list) : list,
        ],
      );
    }

    final desktopWorkspace = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 65, child: buildLeftPane(boundedHeight: true)),
        const SizedBox(width: TenantAdminSpacing.xl),
        Expanded(
          flex: 35,
          child: TillMonitoringSidePanel(
            tillId: selectedTillId,
            listItem: selectedItem,
          ),
        ),
      ],
    );

    final stackedWorkspace = SingleChildScrollView(
      child: buildLeftPane(boundedHeight: false),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.visibility.showSummarySection) ...[
          const TillMonitoringSummaryCards(),
          const SizedBox(height: TenantAdminSpacing.lg),
        ],
        Expanded(child: isDesktop ? desktopWorkspace : stackedWorkspace),
      ],
    );
  }

  TillMonitoringItem? _findSelectedItem(
    TillMonitoringResult? result,
    String? selectedTillId,
  ) {
    if (result == null ||
        selectedTillId == null ||
        selectedTillId.isEmpty ||
        result.items.isEmpty) {
      return null;
    }
    for (final item in result.items) {
      if (item.id == selectedTillId) {
        return item;
      }
    }
    return null;
  }

  void _ensureSelection(TillMonitoringResult? result) {
    if (result == null) {
      return;
    }

    if (result.items.isEmpty) {
      if (ref.read(selectedTillIdProvider) != null) {
        ref.read(selectedTillIdProvider.notifier).state = null;
      }
      return;
    }

    final selectedId = ref.read(selectedTillIdProvider);
    final stillVisible =
        selectedId != null && result.items.any((item) => item.id == selectedId);

    if (!stillVisible) {
      ref.read(selectedTillIdProvider.notifier).state = result.items.first.id;
    }
  }
}
