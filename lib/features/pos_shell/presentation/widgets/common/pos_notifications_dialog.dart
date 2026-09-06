import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Whether a notification row has any permitted presentational field.
/// Action-only rows are omitted: open/mark-read/dismiss have no API surface
/// in Chunk 9 Flutter (no gesture/action widgets invented).
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
    // Timestamp / open / mark-read / dismiss / mark-all-read: no dedicated
    // presentation or action widgets in current panel (no API). Not invented.
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
    final bodyText =
        canBody && item.body.trim().isNotEmpty ? item.body : null;

    final semanticParts = <String>[
      if (titleText != null) titleText,
      if (bodyText != null) bodyText,
    ];

    // Denied title/body must not appear in Semantics / Tooltip / offstage.
    // Open/mark-read/dismiss: no Flutter action surface or API in Chunk 9.
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
        onTap: null,
      ),
    );
  }
}
