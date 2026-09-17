import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/online_order_detail_screen.dart';

import 'online_order_test_fixtures.dart';
import 'test_auth_session_storage.dart';

Widget pickingHarness({
  required List<String> permissions,
  required Widget child,
}) =>
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions,
            ),
          ),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

Widget detailHarness({
  required List<String> permissions,
  required String status,
}) =>
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OnlineOrderDetailScreen(
            state: PosOnlineOrdersState(
              selected: testOnlineOrderDetail(status),
            ),
          ),
        ),
      ),
    );

void testNoop() {}
