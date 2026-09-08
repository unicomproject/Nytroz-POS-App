import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../providers/notification_provider.dart';

const double _panelWidth = 380;
const double _panelMaxHeight = 480;

void showNotificationPanel(BuildContext context) {
  final button = context.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (button == null || overlay == null) return;

  final width = _panelWidth < overlay.size.width - 32
      ? _panelWidth
      : overlay.size.width - 32;

  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(
        button.size.bottomLeft(const Offset(0, 8)),
        ancestor: overlay,
      ),
      button.localToGlobal(
        button.size.bottomRight(const Offset(0, 8)),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );

  showMenu<void>(
    context: context,
    position: position,
    color: TenantAdminColors.surface,
    surfaceTintColor: TenantAdminColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
    ),
    items: [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: SizedBox(width: width, child: const _NotificationPanel()),
      ),
    ],
  );
}

class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationInboxProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _panelMaxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TenantAdminSpacing.lg,
              TenantAdminSpacing.md,
              TenantAdminSpacing.sm,
              TenantAdminSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
                if (state.unreadCount > 0)
                  TextButton(
                    onPressed: () =>
                        ref.read(notificationInboxProvider.notifier).markAllRead(),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Flexible(
            child: state.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(TenantAdminSpacing.xl),
                    child: Text('No notifications yet.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: TenantAdminColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return _NotificationTile(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final NotificationInboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: item.isRead
          ? null
          : () => ref.read(notificationInboxProvider.notifier).markRead(item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isRead
                      ? Colors.transparent
                      : TenantAdminColors.danger,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              item.isRead ? FontWeight.w500 : FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
