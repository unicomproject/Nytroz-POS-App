import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/till_providers.dart';
import '../../domain/entities/till_monitoring.dart';
import 'till_monitoring_row.dart';

class TillMonitoringList extends ConsumerWidget {
  const TillMonitoringList({
    super.key,
    required this.onTillSelected,
  });

  final ValueChanged<String> onTillSelected;

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

        return Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = result.items[index];
                  return TillMonitoringRow(
                    item: item,
                    isSelected: item.id == selectedTillId,
                    onTap: () => onTillSelected(item.id),
                  );
                },
              ),
              _buildPagination(ref, result),
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

  Widget _buildPagination(WidgetRef ref, TillMonitoringResult result) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Showing ${result.rangeStart} to ${result.rangeEnd} of ${result.totalCount} tills',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (result.totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: result.page > 1
                      ? () => ref.read(tillPageProvider.notifier).state =
                          result.page - 1
                      : null,
                ),
                Text('Page ${result.page} of ${result.totalPages}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: result.page < result.totalPages
                      ? () => ref.read(tillPageProvider.notifier).state =
                          result.page + 1
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
