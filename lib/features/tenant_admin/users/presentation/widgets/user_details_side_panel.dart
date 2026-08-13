import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_api_errors.dart';
import 'user_status_badge.dart';

class UserDetailsSidePanel extends ConsumerWidget {
  const UserDetailsSidePanel({super.key, required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const _PanelShell(
        child: TenantAdminEmptyState(
          title: 'No user selected',
          message: 'Select a user to view their details.',
          icon: Icons.person_outline,
        ),
      );
    }

    final detailState = ref.watch(userDetailProvider(userId!));
    return _PanelShell(
      child: detailState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load user',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(userDetailProvider(userId!)),
        ),
        data: (user) => _UserDetailsContent(user: user),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        height: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: const BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border(left: BorderSide(color: TenantAdminColors.border)),
        ),
        child: SingleChildScrollView(child: child),
      );
}

class _UserDetailsContent extends ConsumerWidget {
  const _UserDetailsContent({required this.user});
  final TenantUserDetail user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(userUpdateAccessProvider);
    final canDeactivate = ref.watch(userDeleteAccessProvider);
    final outletNames = user.outlets
        .map((outlet) => outlet.name)
        .where((name) => name.trim().isNotEmpty)
        .join(', ');
    final outletCount = user.outletCount ?? user.outlets.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: TenantAdminColors.secondary,
              child: Text(
                _initials(user.fullName),
                style: const TextStyle(
                  color: TenantAdminColors.posHomeAccentOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: TenantAdminTextStyles.sectionTitle(context)),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  UserStatusBadge(status: user.status),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    'Last active ${formatUserLastActive(user.lastActiveAt)}',
                    style: TenantAdminTextStyles.muted(context)
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        const _SectionTitle('Contact information'),
        _DetailRow(icon: Icons.email_outlined, value: user.email),
        if ((user.phone ?? '').trim().isNotEmpty)
          _DetailRow(icon: Icons.phone_outlined, value: user.phone!),
        _DetailRow(
            icon: Icons.calendar_today_outlined,
            value: 'Joined on ${formatUserDate(user.createdAt)}'),
        const SizedBox(height: TenantAdminSpacing.lg),
        const _SectionTitle('Role & access'),
        _DetailRow(
            icon: Icons.badge_outlined,
            label: 'Assigned role',
            value: _dash(user.roleName)),
        if (_hasText(user.roleDescription))
          Padding(
            padding:
                const EdgeInsets.only(left: 36, bottom: TenantAdminSpacing.sm),
            child: Text(user.roleDescription!.trim(),
                style: TenantAdminTextStyles.muted(context)),
          ),
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: 'Outlet access',
          value: outletNames.isEmpty ? 'No outlets assigned' : outletNames,
          secondary: outletCount > 0
              ? '$outletCount ${outletCount == 1 ? 'Outlet' : 'Outlets'}'
              : null,
        ),
        if (user.accessSummary != null) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          const _SectionTitle('Access summary'),
          _AccessSummary(summary: user.accessSummary!),
        ],
        if (canEdit || canDeactivate) ...[
          const SizedBox(height: TenantAdminSpacing.xl),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              if (canEdit)
                TenantAdminSecondaryButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: () =>
                      context.go('/tenant-admin/staff/${user.id}/edit'),
                ),
              if (canDeactivate)
                TenantAdminSecondaryButton(
                  label: 'Deactivate',
                  icon: Icons.person_off_outlined,
                  onPressed: () => _confirmDeactivate(context, ref),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate user'),
        content: Text(
            'Deactivate "${user.fullName}"? They will no longer be able to sign in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: TenantAdminColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(deleteUserProvider).call(user.id);
      ref.read(selectedUserIdProvider.notifier).state = null;
      ref.invalidate(userDetailProvider(user.id));
      ref.invalidate(userListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.fullName} has been deactivated.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to deactivate user.')));
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
        child: Text(value.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: TenantAdminColors.bodyText)),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.value, this.label, this.secondary});
  final IconData icon;
  final String value;
  final String? label;
  final String? secondary;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: TenantAdminColors.mutedText),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Text(label!,
                          style: TenantAdminTextStyles.muted(context)
                              .copyWith(fontSize: 12)),
                    Text(value,
                        style: const TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700)),
                    if (secondary != null)
                      Text(secondary!,
                          style: TenantAdminTextStyles.muted(context)
                              .copyWith(fontSize: 12)),
                  ]),
            ),
          ],
        ),
      );
}

class _AccessSummary extends StatelessWidget {
  const _AccessSummary({required this.summary});
  final TenantUserAccessSummary summary;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: _SummaryCard(
                  label: 'Outlets',
                  value: summary.outletCount.toString(),
                  icon: Icons.location_on_outlined)),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
              child: _SummaryCard(
                  label: 'Modules',
                  value: summary.moduleCount.toString(),
                  icon: Icons.inventory_2_outlined)),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
              child: _SummaryCard(
                  label: 'Permissions',
                  value: summary.permissionCount.toString(),
                  icon: Icons.lock_outline)),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            vertical: TenantAdminSpacing.md, horizontal: TenantAdminSpacing.sm),
        decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm)),
        child: Column(children: [
          Icon(icon, size: 18, color: TenantAdminColors.posHomeAccentOrange),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: TenantAdminColors.mutedText)),
        ]),
      );
}

bool _hasText(String? value) => value?.trim().isNotEmpty == true;
String _dash(String value) => value.trim().isEmpty ? '—' : value.trim();
String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
