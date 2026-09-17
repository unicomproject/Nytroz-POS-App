import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../data/datasources/pos_notifications_remote_datasource.dart';

final posNotificationsRemoteDatasourceProvider =
    Provider<PosNotificationsRemoteDatasource>(
  (ref) => PosNotificationsRemoteDatasource(ref.watch(appDioProvider)),
);

final posNotificationsProvider =
    FutureProvider.autoDispose<PosNotificationInbox>(
  (ref) async {
    final session = ref.watch(authSessionProvider);
    if (session == null ||
        !session.isAuthenticated ||
        !session.hasPermission(PosPermissionCodes.viewNotifications)) {
      return const PosNotificationInbox(items: [], unreadCount: 0);
    }
    return ref.watch(posNotificationsRemoteDatasourceProvider).getInbox();
  },
);
