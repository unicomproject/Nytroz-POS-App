import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/access/effective_permission_set.dart';
import '../../../../../core/access/permission_access_providers.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../data/datasources/pos_notifications_remote_datasource.dart';
import '../../providers/pos_notifications_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_shell_top_bar_visibility.dart';

Future<void> showPosNotificationsDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _PosNotificationsDialog(),
    );

class _PosNotificationsDialog extends ConsumerWidget {
  const _PosNotificationsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosShellTopBarVisibility.canShowNotificationPanel(permissions)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    final canList = permissions.hasPermission(
      PosPermissionCodes.notificationsMessagesList,
    );
    final state = ref.watch(posNotificationsProvider);
    final unreadCount = state.asData?.value.unreadCount ?? 0;

    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: !canList
            ? const SizedBox.shrink()
            : state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(posNotificationsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
                data: (inbox) {
                  final visibleItems = inbox.items
                      .where(
                        (item) => notificationRowHasVisibleContent(
                          item,
                          permissions,
                        ),
                      )
                      .toList(growable: false);
                  if (visibleItems.isEmpty) {
                    return const Center(child: Text('No notifications'));
                  }
                  return ListView.separated(
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => _NotificationTile(
                      item: visibleItems[index],
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (canList && unreadCount > 0)
          TextButton(
            onPressed: () async {
              await ref
                  .read(posNotificationsRemoteDatasourceProvider)
                  .markAllRead();
              ref.invalidate(posNotificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Whether a notification row has any permitted presentational field.
/// Mark-read/dismiss are still omitted: no API surface for them on the POS
/// notifications endpoint. Tapping a row to open the order it refers to is
/// supported (see [_NotificationTile]) and needs no additional permission
/// beyond seeing the row itself — the backend already scopes which
/// notifications a cashier receives to what they're allowed to view.
bool notificationRowHasVisibleContent(
  PosNotificationItem item,
  EffectivePermissionSet permissions,
) {
  final canTitle = permissions.hasPermission(
    PosPermissionCodes.notificationsMessagesTitle,
  );
  final canBody = permissions.hasPermission(
    PosPermissionCodes.notificationsMessagesBody,
  );
  // Timestamp / dismiss: no dedicated presentation or action widgets in
  // current panel (no API). Not invented.
  return (canTitle && item.title.trim().isNotEmpty) ||
      (canBody && item.body.trim().isNotEmpty);
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});
  final PosNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final canTitle = permissions.hasPermission(
      PosPermissionCodes.notificationsMessagesTitle,
    );
    final canBody = permissions.hasPermission(
      PosPermissionCodes.notificationsMessagesBody,
    );

    final titleText =
        canTitle && item.title.trim().isNotEmpty ? item.title : null;
    final bodyText = canBody && item.body.trim().isNotEmpty ? item.body : null;

    final semanticParts = <String>[
      if (titleText != null) titleText,
      if (bodyText != null) bodyText,
    ];

    // Denied title/body must not appear in Semantics / Tooltip / offstage.
    return Semantics(
      container: true,
      label: semanticParts.isEmpty ? 'Notification' : semanticParts.join('. '),
      child: ListTile(
        leading: Icon(
          item.isRead ? Icons.notifications_none : Icons.notifications_active,
          color: item.isRead
              ? TenantAdminColors.mutedText
              : TenantAdminColors.primary,
        ),
        title: titleText != null ? Text(titleText) : null,
        subtitle: bodyText != null
            ? Text(
                bodyText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: item.isOnlineOrderNotification
            ? const Icon(Icons.chevron_right_rounded)
            : null,
        onTap: () => _handleTap(context),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    // Read the container directly (rather than this tile's own WidgetRef)
    // so the pending mark-read call is unaffected by the dialog — and this
    // tile — closing and disposing as part of the same tap when navigating.
    final container = ProviderScope.containerOf(context, listen: false);

    if (item.isOnlineOrderNotification) {
      Navigator.of(context).pop();
      context.push('/pos/online-orders/${item.sourceReferenceId}');
    }

    if (!item.isRead) {
      unawaited(
        container
            .read(posNotificationsRemoteDatasourceProvider)
            .markRead(item.id)
            .then((_) => container.invalidate(posNotificationsProvider)),
      );
    }
  }
}
