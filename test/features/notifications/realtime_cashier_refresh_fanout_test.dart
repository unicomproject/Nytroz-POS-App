import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/notifications/data/notifications_api.dart';
import 'package:nytroz_pos/features/notifications/domain/entities/notification_inbox_item.dart';
import 'package:nytroz_pos/features/notifications/domain/entities/realtime_notification_event.dart';
import 'package:nytroz_pos/features/notifications/presentation/providers/notification_provider.dart';
import 'package:nytroz_pos/features/notifications/presentation/providers/realtime_cashier_refresh_policy.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_notifications_remote_datasource.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_notifications_provider.dart';

void main() {
  group('Realtime cashier refresh fan-out', () {
    test('policy never treats payload as local unread increment source', () {
      const event = RealtimeNotificationEvent(
        type: RealtimeCashierRefreshPolicy.orderPlacedStaff,
        title: 'New order placed',
        body: 'Order ORD-1',
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshPosNotifications(event),
        isTrue,
      );
    });

    test('refreshFromRealtime preserves search/filter/page and uses outlet',
        () async {
      final repo = _FakeOrdersRepo();
      final container = ProviderContainer(overrides: [
        posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(posOnlineOrdersProvider.notifier);
      controller.setQuery('ORD');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      controller.setStatus('PENDING');
      await controller.load(resetPage: true);
      expect(repo.lastSearch, 'ORD');
      expect(repo.lastStatus, 'PENDING');
      expect(repo.listCalls, greaterThanOrEqualTo(1));
      final callsBefore = repo.listCalls;

      await controller.refreshFromRealtime();
      expect(repo.listCalls, callsBefore + 1);
      expect(repo.lastSearch, 'ORD');
      expect(repo.lastStatus, 'PENDING');
      expect(repo.lastPage, 1);
      expect(container.read(posOnlineOrdersProvider).query, 'ORD');
      expect(container.read(posOnlineOrdersProvider).status, 'PENDING');
    });

    test('duplicate realtime soft-refresh does not duplicate list items',
        () async {
      final repo = _FakeOrdersRepo();
      final container = ProviderContainer(overrides: [
        posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      ]);
      addTearDown(container.dispose);
      final controller = container.read(posOnlineOrdersProvider.notifier);
      await controller.refreshFromRealtime();
      await controller.refreshFromRealtime();
      final items = container.read(posOnlineOrdersProvider).items;
      expect(items, hasLength(1));
      expect(items.single.orderNumber, 'ORD-000001');
      expect(repo.listCalls, 2);
    });

    test('failed realtime refresh keeps previous list', () async {
      final repo = _FakeOrdersRepo();
      final container = ProviderContainer(overrides: [
        posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      ]);
      addTearDown(container.dispose);
      final controller = container.read(posOnlineOrdersProvider.notifier);
      await controller.load();
      expect(container.read(posOnlineOrdersProvider).items, hasLength(1));

      repo.failNext = true;
      await controller.refreshFromRealtime();
      final state = container.read(posOnlineOrdersProvider);
      expect(state.items, hasLength(1));
      expect(state.items.single.orderNumber, 'ORD-000001');
      expect(state.errorMessage, isNotNull);
    });

    test('refreshAuthoritativeSurfaces invalidates POS bell provider', () async {
      var bellFetches = 0;
      final container = ProviderContainer(overrides: [
        appDioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://127.0.0.1')),
        ),
        authSessionProvider.overrideWith(
          (ref) => _PresetAuth(
            AuthSession(
              accessToken: 'token',
              userId: 'u1',
              userDisplayName: 'Cashier',
              permissionCodes: const [
                PosPermissionCodes.viewNotifications,
                PosPermissionCodes.accessOnlineOrders,
                PosPermissionCodes.viewOnlineOrders,
              ],
            ),
          ),
        ),
        notificationsApiProvider.overrideWithValue(_FakeNotificationsApi()),
        posNotificationsRemoteDatasourceProvider.overrideWithValue(
          _CountingBellDatasource(() => bellFetches += 1),
        ),
        posOnlineOrdersRepositoryProvider.overrideWithValue(_FakeOrdersRepo()),
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      ]);
      addTearDown(container.dispose);

      container.listen(posNotificationsProvider, (_, __) {});
      await container.read(posNotificationsProvider.future);
      final before = bellFetches;

      await container
          .read(notificationInboxProvider.notifier)
          .refreshAuthoritativeSurfaces(includeOnlineOrders: true);

      await container.read(posNotificationsProvider.future);
      expect(bellFetches, greaterThan(before));
    });
  });
}

class _PresetAuth extends AuthSessionNotifier {
  _PresetAuth(AuthSession session) : super(_TestStorage()) {
    state = session;
  }
}

class _TestStorage extends AuthSessionStorage {
  _TestStorage() : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

class _FakeNotificationsApi extends NotificationsApi {
  _FakeNotificationsApi() : super(Dio());

  @override
  Future<List<NotificationInboxItem>> fetchInbox({
    int page = 1,
    int pageSize = 20,
  }) async =>
      const [];

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  Future<void> markAllRead() async {}
}

class _CountingBellDatasource extends PosNotificationsRemoteDatasource {
  _CountingBellDatasource(this.onFetch) : super(Dio());
  final void Function() onFetch;

  @override
  Future<PosNotificationInbox> getInbox() async {
    onFetch();
    return const PosNotificationInbox(unreadCount: 0, items: []);
  }
}

class _FakeOrdersRepo implements PosOnlineOrdersRepository {
  int listCalls = 0;
  String? lastSearch;
  String? lastStatus;
  int? lastPage;
  bool failNext = false;

  @override
  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  }) async {
    listCalls += 1;
    lastSearch = query.search;
    lastStatus = query.status;
    lastPage = query.page;
    if (failNext) {
      failNext = false;
      throw DioException(
        requestOptions: RequestOptions(path: '/orders'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/orders'),
          statusCode: 500,
        ),
      );
    }
    return PosOnlineOrderPage(
      items: const [
        PosOnlineOrder(
          id: 'o1',
          orderNumber: 'ORD-000001',
          customerName: 'Customer',
          status: 'CONFIRMED',
          statusLabel: 'Confirmed',
          paymentStatus: 'PAID',
          currencyCode: 'LKR',
          totalAmount: 10,
          lineCount: 1,
        ),
      ],
      summary: const PosOnlineOrderSummary(
        total: 1,
        pending: 1,
        preparing: 0,
        ready: 0,
        overdue: 0,
        newOrders: 1,
        collected: 0,
        cancelled: 0,
      ),
      page: query.page,
      pageSize: query.pageSize,
      totalCount: 1,
      totalPages: 1,
      serverTime: DateTime.utc(2026, 9, 9),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
