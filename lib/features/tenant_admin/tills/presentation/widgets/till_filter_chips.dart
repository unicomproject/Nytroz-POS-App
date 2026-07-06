import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_filter_chip.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../utils/till_list_filters.dart';

class TillFilterChips extends ConsumerWidget {
  const TillFilterChips({
    super.key,
    required this.summary,
    required this.selectedFilter,
    required this.enabled,
  });

  final TillListSummary summary;
  final TillStatusFilter selectedFilter;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TillStatusFilter.values) ...[
            TenantAdminFilterChip(
              label: filter.label,
              selected: selectedFilter == filter,
              count: filter == TillStatusFilter.needsAttention
                  ? summary.needsAttentionCount
                  : null,
              onTap: () {
                ref.read(tillStatusFilterProvider.notifier).state = filter;
                ref.read(tillPageProvider.notifier).state = 1;
              },
            ),
            if (filter != TillStatusFilter.values.last)
              const SizedBox(width: TenantAdminSpacing.sm),
          ],
        ],
      ),
    );
  }
}
