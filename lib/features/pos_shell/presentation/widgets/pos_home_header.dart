import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import 'pos_status_chip.dart';

class PosHomeHeader extends ConsumerWidget {
  const PosHomeHeader({
    super.key,
    required this.dashboard,
  });

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final sessionName = session?.userDisplayName.trim();
    final userDisplayName = sessionName != null && sessionName.isNotEmpty
        ? sessionName
        : dashboard.fallbackUserDisplayName;
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final greeting = _Greeting(
          userDisplayName: userDisplayName,
          statusMessage: dashboard.isTillOpen
              ? dashboard.statusMessage
              : '${dashboard.tillLabel} is not open.',
        );
        final contextItems = _HeaderContext(
          now: now,
          dashboard: dashboard,
          showNotification: true,
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: TenantAdminSpacing.lg),
              contextItems,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: TenantAdminSpacing.xl),
            contextItems,
          ],
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.userDisplayName,
    required this.statusMessage,
  });

  final String userDisplayName;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userDisplayName 👋',
          style: TenantAdminTextStyles.pageTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          statusMessage,
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
    );
  }
}

class _HeaderContext extends StatelessWidget {
  const _HeaderContext({
    required this.now,
    required this.dashboard,
    required this.showNotification,
  });

  final DateTime now;
  final PosHomeDashboardState dashboard;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showNotification)
          _NotificationButton(
            // Presentation-only until a notification module exists.
            onPressed: () {},
          ),
        PosStatusChip(
          tillLabel: dashboard.tillLabel,
          statusLabel: dashboard.tillStatusLabel,
          isOpen: dashboard.isTillOpen,
        ),
        _DateTimeChip(now: now),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: TenantAdminColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: TenantAdminColors.bodyText,
                size: 25,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  const _DateTimeChip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 20,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              '${_formatTime(now)}  •  ${_formatDate(now)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatDate(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} '
      '${value.day}';
}
