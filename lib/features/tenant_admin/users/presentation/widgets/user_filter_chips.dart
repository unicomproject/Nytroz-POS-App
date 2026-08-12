import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
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
            _UserStatusFilterChip(
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

class _UserStatusFilterChip extends StatelessWidget {
  const _UserStatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = TenantAdminColors.posHomeAccentOrange;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label users',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF2E8) : TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? accent : TenantAdminColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? accent : TenantAdminColors.bodyText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
