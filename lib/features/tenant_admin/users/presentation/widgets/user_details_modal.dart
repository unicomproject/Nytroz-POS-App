import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_api_errors.dart';
import 'user_status_badge.dart';

Future<void> showUserDetailsModal(BuildContext context, String userId) {
  return showDialog<void>(
    context: context,
    builder: (context) => UserDetailsModal(userId: userId),
  );
}

class UserDetailsModal extends ConsumerWidget {
  const UserDetailsModal({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(userDetailProvider(userId));
    final canEdit = ref.watch(userUpdateAccessProvider);
    final canDelete = ref.watch(userDeleteAccessProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: detailState.when(
            loading: () => const SizedBox(
              height: 240,
              child: TenantAdminLoadingSkeleton(rowCount: 5),
            ),
            error: (error, stackTrace) => SizedBox(
              height: 240,
              child: TenantAdminErrorState(
                title: 'Unable to load user',
                message: 'Please try again.',
                onRetry: () => ref.invalidate(userDetailProvider(userId)),
              ),
            ),
            data: (user) => _UserDetailsContent(
              user: user,
              canEdit: canEdit,
              canDelete: canDelete,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDetailsContent extends ConsumerWidget {
  const _UserDetailsContent({
    required this.user,
    required this.canEdit,
    required this.canDelete,
  });

  final TenantUserDetail user;
  final bool canEdit;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletNames = user.outlets.isEmpty
        ? 'All outlets'
        : user.outlets.map((o) => o.name).join(', ');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: TenantAdminColors.secondary,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: TenantAdminColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Wrap(
                      spacing: TenantAdminSpacing.sm,
                      runSpacing: TenantAdminSpacing.sm,
                      children: [
                        UserStatusBadge(status: user.status),
                        if (user.roleName.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TenantAdminSpacing.md,
                              vertical: TenantAdminSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: TenantAdminColors.secondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user.roleName,
                              style: const TextStyle(
                                color: TenantAdminColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.lg),
          _InfoRow(label: 'Full Name', value: user.fullName),
          _InfoRow(label: 'Email', value: user.email),
          _InfoRow(label: 'Phone', value: user.phone ?? '—'),
          _InfoRow(label: 'Role', value: _emptyDash(user.roleName)),
          _InfoRow(label: 'Outlet', value: outletNames),
          _InfoRow(label: 'Status', value: _titleCase(user.status)),
          _InfoRow(
            label: 'Last Active',
            value: formatUserLastActive(user.lastActiveAt),
          ),
          _InfoRow(label: 'Joined On', value: formatUserDate(user.createdAt)),
          if (canEdit || canDelete) ...[
            const SizedBox(height: TenantAdminSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canDelete)
                  TenantAdminSecondaryButton(
                    label: 'Delete User',
                    icon: Icons.delete_outline,
                    onPressed: () => _delete(context, ref),
                  ),
                if (canDelete && canEdit)
                  const SizedBox(width: TenantAdminSpacing.md),
                if (canEdit)
                  TenantAdminPrimaryButton(
                    label: 'Edit User',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/tenant-admin/staff/${user.id}/edit');
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Are you sure you want to disable "${user.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(deleteUserProvider).call(user.id);
      ref.invalidate(userListProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} has been disabled.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete user.')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TenantAdminTextStyles.muted(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _emptyDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '—';
  }

  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}

String _initials(String fullName) {
  final parts =
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
