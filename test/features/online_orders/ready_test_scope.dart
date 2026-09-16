import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';

/// Authorized, deterministic READY data for layout tests; no live API/storage.
class ReadyTestScope extends StatelessWidget {
  const ReadyTestScope({required this.order, required this.child, super.key});
  final PosPickingOrder order;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => _ReadySession()),
          posPickingOrderProvider(order.orderId).overrideWith((ref) async => order),
        ],
        child: child,
      );
}

class _ReadySession extends AuthSessionNotifier {
  _ReadySession() : super(_MemoryStorage()) {
    state = AuthSession(
      accessToken: 'test-token',
      userId: 'user-1',
      userDisplayName: 'Cashier',
      permissionCodes: const [
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
        PosPermissionCodes.viewOnlineOrderReady,
      ],
    );
  }
}

class _MemoryStorage extends AuthSessionStorage {
  _MemoryStorage() : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}
