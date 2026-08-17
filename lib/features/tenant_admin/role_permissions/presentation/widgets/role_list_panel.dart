import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../domain/entities/role_list_item.dart';
import '../providers/role_list_visibility_provider.dart';
import '../providers/roles_list_providers.dart';

class RoleListPanel extends ConsumerWidget {
  const RoleListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
    required this.showDetailPanel,
    required this.selectedRoleId,
    required this.onSelect,
  });

  final PaginatedRoleList result;
  final RoleListVisibility visibility;
  final bool isMobile;
  final bool showDetailPanel;
  final String? selectedRoleId;
  final ValueChanged<RoleListItem> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result.items.isEmpty) {
      return const TenantAdminDataTable(
        columns: [],
        rows: [],
        emptyTitle: 'No Roles Found',
        emptyMessage: 'No roles match your search criteria.',
      );
    }

    return TenantAdminDataTable(
      columns: const [
        DataColumn(label: Text('ROLE NAME')),
        DataColumn(
          label: SizedBox(
            width: 95,
            child: Text('PERMISSIONS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 60,
            child: Text('USERS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 80,
            child: Text('STATUS', textAlign: TextAlign.center),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: 100,
            child: Text('CREATED', textAlign: TextAlign.center),
          ),
        ),
      ],
      rows: result.items.map((role) {
        final isSelected = role.id == selectedRoleId && showDetailPanel;
        
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelect(role),
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return TenantAdminColors.posHomeAccentOrange.withAlpha(20);
            }
            if (states.contains(WidgetState.hovered)) {
              return TenantAdminColors.subtleBackground;
            }
            return null;
          }),
          cells: [
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        role.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected
                              ? TenantAdminColors.posHomeAccentOrange
                              : TenantAdminColors.bodyText,
                        ),
                      ),
                      if (role.isSystem) ...[
                        const SizedBox(width: TenantAdminSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TenantAdminColors.mutedText.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SYSTEM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: TenantAdminColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (role.description != null && role.description!.isNotEmpty)
                    Text(
                      role.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: 95,
                child: Text('${role.permissionCount}', textAlign: TextAlign.center),
              ),
            ),
            DataCell(
              SizedBox(
                width: 60,
                child: Text('${role.userCount}', textAlign: TextAlign.center),
              ),
            ),
            DataCell(
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md,
                      vertical: TenantAdminSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: role.isActive
                          ? TenantAdminColors.successSurface
                          : TenantAdminColors.dangerSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      role.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: role.isActive
                            ? TenantAdminColors.success
                            : TenantAdminColors.danger,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: Text(
                  DateFormat('MMM d, yyyy').format(role.createdAt.toLocal()),
                  style: const TextStyle(color: TenantAdminColors.mutedText),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ],
        );
      }).toList(),
      showCheckboxColumn: false,
      footer: result.totalPages > 1
          ? TenantAdminPaginationBar(
              currentPage: result.page,
              pageSize: 5,
              totalCount: result.totalCount,
              onPageChanged: (page) {
                final query = ref.read(rolesListQueryProvider);
                ref.read(rolesListQueryProvider.notifier).state = query.copyWith(page: page);
              },
            )
          : null,
    );
  }
}
