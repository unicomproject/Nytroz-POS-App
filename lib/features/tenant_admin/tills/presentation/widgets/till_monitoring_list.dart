import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/till_providers.dart';
import 'till_monitoring_row.dart';

class TillMonitoringList extends ConsumerWidget {
  const TillMonitoringList({
    super.key,
    required this.onTillSelected,
    this.scrollable = false,
  });

  final ValueChanged<String> onTillSelected;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(tillListResultFutureProvider);
    final selectedTillId = ref.watch(selectedTillIdProvider);

    return listState.when(
      data: (result) {
        if (result == null || result.items.isEmpty) {
          return const TenantAdminEmptyState(
            title: 'No Tills Found',
            message: 'Try adjusting your filters or search query.',
          );
        }

        final listView = ListView.separated(
          primary: false,
          shrinkWrap: !scrollable,
          physics: scrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: result.items.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: TenantAdminColors.border,
          ),
          itemBuilder: (context, index) {
            final item = result.items[index];
            return TillMonitoringRow(
              item: item,
              isSelected: item.id == selectedTillId,
              onTap: () => onTillSelected(item.id),
            );
          },
        );

        return Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            children: [
              if (scrollable) Expanded(child: listView) else listView,
              TenantAdminPaginationBar(
                currentPage: result.page,
                pageSize: result.pageSize,
                totalCount: result.totalCount,
                itemLabel: 'tills',
                onPageChanged: (page) =>
                    ref.read(tillPageProvider.notifier).state = page,
              ),
            ],
          ),
        );
      },
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
      error: (error, stack) => TenantAdminErrorState(
        title: 'Unable to load tills',
        message: 'Please try again.',
        onRetry: () => ref.invalidate(tillListResultFutureProvider),
      ),
    );
  }
}
