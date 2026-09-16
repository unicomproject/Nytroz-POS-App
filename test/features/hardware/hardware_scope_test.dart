import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_list_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'hardware_master_wizard_test.dart' show hardwareTestAccess;

TillMonitoringItem till(String id, String outlet, {bool active = true}) =>
    TillMonitoringItem(
      id: id,
      outletId: outlet,
      outletName: outlet,
      name: id,
      code: id,
      lifecycleStatus:
          active ? TillLifecycleStatus.active : TillLifecycleStatus.inactive,
      operationalStatus: TillOperationalStatus.unknown,
      displayStatus: TillDisplayStatus.unknown,
      needsAttention: false,
      attentionReasonCount: 0,
    );

void main() {
  for (final allowedIds in [
    <String>{'o'},
    <String>{},
    <String>{'foreign'}
  ]) {
    test('outlet selector intersects hardware restriction $allowedIds',
        () async {
      final container = ProviderContainer(overrides: [
        tenantAdminContextProvider
            .overrideWith((ref) async => hardwareTestAccess().context),
        hardwareAccessScopeProvider.overrideWith(
            (ref) async => HardwareAccessScope(true, allowedIds, {})),
        tillOutletOptionsProvider.overrideWith((ref) async => [
              const OutletOption(
                  id: 'o', name: 'Main', code: 'O', status: 'ACTIVE'),
              const OutletOption(
                  id: 'foreign', name: 'Other', code: 'X', status: 'ACTIVE'),
            ]),
      ]);
      addTearDown(container.dispose);
      final options =
          await container.read(hardwareOutletOptionsProvider.future);
      expect(
          options.map((o) => o.id), allowedIds.contains('o') ? ['o'] : isEmpty);
    });
  }
  for (final restricted in [false, true]) {
    test('hardware restriction intersects general till access: $restricted',
        () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, data: {
          'data': options.path.endsWith('create-options')
              ? {
                  'hardwareScope': {
                    'restricted': restricted,
                    'outletIds': ['o'],
                    'tillIds': ['selected']
                  }
                }
              : {'tillAccessScope': 'ALL_ACCESSIBLE_TILLS'}
        }));
      }));
      final container = ProviderContainer(overrides: [
        appDioProvider.overrideWithValue(dio),
        tenantAdminContextProvider
            .overrideWith((ref) async => hardwareTestAccess().context),
        hardwareTillsProvider.overrideWith((ref) async => [
              till('selected', 'o'),
              till('other', 'o'),
              till('outside', 'forbidden')
            ]),
      ]);
      addTearDown(container.dispose);
      addTearDown(dio.close);
      final result =
          await container.read(hardwareAssignableTillsProvider.future);
      expect(result.map((t) => t.id),
          restricted ? ['selected'] : ['selected', 'other']);
    });
  }
  for (final scope in ['SELECTED_TILLS', 'ALL_ACCESSIBLE_TILLS', 'UNKNOWN']) {
    test('assignment enforces explicit $scope and outlet/lifecycle boundaries',
        () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.path, '/api/v1/tenant-admin/users/u');
        handler.resolve(Response(requestOptions: options, data: {
          'data': {
            'tillAccessScope': scope,
            'tills': [
              {'tillId': 'selected'},
              {'id': 'outside'}
            ],
          }
        }));
      }));
      final container = ProviderContainer(overrides: [
        hardwareAccessScopeProvider.overrideWith(
            (ref) async => const HardwareAccessScope(false, {}, {})),
        appDioProvider.overrideWithValue(dio),
        tenantAdminContextProvider
            .overrideWith((ref) async => hardwareTestAccess().context),
        hardwareTillsProvider.overrideWith((ref) async => [
              till('selected', 'o'),
              till('other', 'o'),
              till('outside', 'forbidden'),
              till('inactive', 'o', active: false),
            ]),
      ]);
      addTearDown(container.dispose);
      addTearDown(dio.close);
      final result =
          await container.read(hardwareAssignableTillsProvider.future);
      expect(
          result.map((t) => t.id).toList(),
          scope == 'SELECTED_TILLS'
              ? ['selected']
              : scope == 'ALL_ACCESSIBLE_TILLS'
                  ? ['selected', 'other']
                  : isEmpty);
    });
  }
  test('missing till scope fails closed instead of granting all', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(requestOptions: options, data: {'data': {}}));
    }));
    final container = ProviderContainer(overrides: [
      appDioProvider.overrideWithValue(dio),
      tenantAdminContextProvider
          .overrideWith((ref) async => hardwareTestAccess().context),
    ]);
    addTearDown(container.dispose);
    addTearDown(dio.close);
    await expectLater(container.read(hardwareAssignableTillsProvider.future),
        throwsStateError);
  });
}
