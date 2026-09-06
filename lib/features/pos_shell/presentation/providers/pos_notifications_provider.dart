import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/pos_notifications_remote_datasource.dart';

final posNotificationsRemoteDatasourceProvider =
    Provider<PosNotificationsRemoteDatasource>(
  (ref) => PosNotificationsRemoteDatasource(ref.watch(appDioProvider)),
);

final posNotificationsProvider =
    FutureProvider.autoDispose<PosNotificationInbox>(
  (ref) => ref.watch(posNotificationsRemoteDatasourceProvider).getInbox(),
);
