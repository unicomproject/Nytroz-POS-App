import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'pos_status_chip.dart';

class PosHomeHeader extends ConsumerWidget {
  const PosHomeHeader({
    super.key,
    required this.dashboard,
  });

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = dashboard.grantedPermissionKeys ?? const {};
    final userDisplayName = dashboard.fallbackUserDisplayName;
    final canViewNotifications =
        perms.contains(PosPermissionCodes.viewNotifications);
    final canViewTillSession =
        perms.contains(PosPermissionCodes.viewTillSession);
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final greeting = _Greeting(
          userDisplayName: userDisplayName,
          statusMessage: dashboard.isTillOpen
              ? dashboard.statusMessage
              : '${dashboard.tillDisplayLabel.isNotEmpty ? dashboard.tillDisplayLabel : dashboard.tillLabel} is not open.',
        );
        final contextItems = _HeaderContext(
          now: now,
          dashboard: dashboard,
          showNotification: canViewNotifications,
          showTillStatus: canViewTillSession,
          notificationCount: dashboard.notificationCount,
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
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: contextItems,
              ),
            ),
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
    required this.showTillStatus,
    required this.notificationCount,
  });

  final DateTime now;
  final PosHomeDashboardState dashboard;
  final bool showNotification;
  final bool showTillStatus;
  final int notificationCount;

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
            notificationCount: notificationCount,
          ),
        if (showTillStatus && _shouldShowTillChip(dashboard))
          PosStatusChip(
            displayLabel: dashboard.tillDisplayLabel,
            tillLabel: dashboard.tillLabel,
            statusLabel: dashboard.tillStatusLabel,
            isOpen: dashboard.isTillOpen,
          ),
        _DateTimeChip(
          serverNowUtc: dashboard.serverNowUtc,
          serverTimeReceivedAt: dashboard.serverTimeReceivedAt,
          outletTimezone: dashboard.outletTimezone,
          fallbackNow: now,
        ),
      ],
    );
  }
}

bool _shouldShowTillChip(PosHomeDashboardState dashboard) {
  if (dashboard.tillDisplayLabel.trim().isNotEmpty) {
    return true;
  }

  return dashboard.tillLabel.trim().isNotEmpty &&
      dashboard.tillLabel != 'Till pending';
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onPressed,
    required this.notificationCount,
  });

  final VoidCallback onPressed;
  final int notificationCount;

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
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: TenantAdminColors.bodyText,
                size: 25,
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: TenantAdminColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Center(
                        child: Text(
                          notificationCount > 99
                              ? '99+'
                              : notificationCount.toString(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TenantAdminColors.surface,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatefulWidget {
  const _DateTimeChip({
    required this.serverNowUtc,
    required this.serverTimeReceivedAt,
    required this.outletTimezone,
    required this.fallbackNow,
  });

  final DateTime? serverNowUtc;
  final DateTime? serverTimeReceivedAt;
  final String? outletTimezone;
  final DateTime fallbackNow;

  @override
  State<_DateTimeChip> createState() => _DateTimeChipState();
}

class _DateTimeChipState extends State<_DateTimeChip> {
  Timer? _timer;
  late DateTime _displayNow;

  @override
  void initState() {
    super.initState();
    _displayNow = _resolveOutletNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _displayNow = _resolveOutletNow();
      });
    });
  }

  @override
  void didUpdateWidget(covariant _DateTimeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverNowUtc != widget.serverNowUtc ||
        oldWidget.serverTimeReceivedAt != widget.serverTimeReceivedAt ||
        oldWidget.outletTimezone != widget.outletTimezone) {
      setState(() {
        _displayNow = _resolveOutletNow();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime _resolveOutletNow() {
    final serverNowUtc = widget.serverNowUtc;
    final receivedAt = widget.serverTimeReceivedAt;
    if (serverNowUtc == null || receivedAt == null) {
      return widget.fallbackNow;
    }

    final elapsed = DateTime.now().toUtc().difference(receivedAt);
    final anchoredUtc = serverNowUtc.add(elapsed);
    return anchoredUtc.add(_timezoneOffset(widget.outletTimezone));
  }

  Duration _timezoneOffset(String? outletTimezone) {
    switch (outletTimezone?.trim()) {
      case 'Asia/Colombo':
        return const Duration(hours: 5, minutes: 30);
      default:
        return Duration.zero;
    }
  }

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
              '${_formatTime(_displayNow)}  •  ${_formatDate(_displayNow)}',
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
