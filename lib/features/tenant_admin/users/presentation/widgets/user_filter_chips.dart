import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_filter_chip.dart';
import '../providers/tenant_user_providers.dart';
import '../utils/user_list_filters.dart';

class UserFilterChips extends ConsumerWidget {
  const UserFilterChips({super.key, required this.selectedFilter});

  final UserStatusFilter selectedFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in UserStatusFilter.values) ...[
            TenantAdminFilterChip(
              label: filter.label,
              selected: selectedFilter == filter,
              onTap: () {
                ref.read(userStatusFilterProvider.notifier).state = filter;
                ref.read(userPageProvider.notifier).state = 1;
              },
            ),
            if (filter != UserStatusFilter.values.last)
              const SizedBox(width: TenantAdminSpacing.sm),
          ],
        ],
      ),
    );
  }
}
