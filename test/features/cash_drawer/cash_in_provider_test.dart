import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement_type.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/repositories/cash_drawer_repository.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drawer_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_in_provider.dart';

void main() {
  test('cash in form reuses requestId for same logical submission', () {
    final controller = CashInFormController();
    final first = controller.ensurePendingRequestId();
    final second = controller.ensurePendingRequestId();
    expect(first, isNotEmpty);
    expect(second, first);
    controller.clearPendingRequestId();
    final third = controller.ensurePendingRequestId();
    expect(third, isNot(first));
  });

  test('catalog ready includes tenant custom movement types', () async {
    final repository = _CatalogRepository(types: const [
      CashMovementTypeOption(
        movementTypeId: 'g1',
        code: 'FLOAT_ADDED',
        name: 'Float Added',
        direction: 'IN',
        requiresReason: false,
        affectsExpectedCash: true,
      ),
      CashMovementTypeOption(
        movementTypeId: 't1',
        code: 'STORE_TOP_UP',
        name: 'Weekend Festival Float Replenishment Request',
        direction: 'IN',
        requiresReason: true,
        affectsExpectedCash: true,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashInCatalogProvider.notifier).load();
    final state = container.read(cashInCatalogProvider);
    expect(state.status, CashInCatalogStatus.ready);
    expect(state.types.length, 2);
    expect(state.types.last.movementTypeId, 't1');
  });

  test('empty catalog does not invent hardcoded reasons', () async {
    final repository = _CatalogRepository(types: const []);
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashInCatalogProvider.notifier).load();
    final state = container.read(cashInCatalogProvider);
    expect(state.status, CashInCatalogStatus.empty);
    expect(state.types, isEmpty);
  });

  test('currency input prefix uses backend currency not LKR default', () {
    expect(currencyInputPrefix('USD'), 'USD');
    expect(currencyInputPrefix('EUR'), 'EUR');
    expect(currencyInputPrefix(''), '');
  });

  test('invalid amount and missing reason skip mutation', () {
    expect(validateCashInAmount(''), isNotNull);
    expect(validateCashInAmount('0'), isNotNull);
    expect(
      validateCashInMovementType(
        null,
        availableTypes: const [
          CashMovementTypeOption(
            movementTypeId: 'g1',
            code: 'FLOAT_ADDED',
            name: 'Float Added',
            direction: 'IN',
            requiresReason: false,
            affectsExpectedCash: true,
          ),
        ],
      ),
      isNotNull,
    );
  });
}

class _CatalogRepository implements CashDrawerRepository {
  _CatalogRepository({required this.types});

  final List<CashMovementTypeOption> types;

  @override
  Future<List<CashMovementTypeOption>> getCashInMovementTypes() async => types;

  @override
  Future<List<CashMovementTypeOption>> getCashDropMovementTypes() async => types;

  @override
  Future<CashMovement> createCashInMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashMovement> createCashDropMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashMovement> createMovement({
    required String requestId,
    required String deviceId,
    required String tillSessionId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? referenceNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CashMovement>> getMovements(String deviceId,
      {int page = 1, int pageSize = 25}) {
    throw UnimplementedError();
  }

  @override
  Future<CashDrawerSummary> getSummary(String deviceId) {
    throw UnimplementedError();
  }
}
