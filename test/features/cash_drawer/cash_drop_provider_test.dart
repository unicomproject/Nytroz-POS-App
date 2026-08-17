import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement_type.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/repositories/cash_drawer_repository.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drawer_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drop_provider.dart';

void main() {
  test('cash drop form reuses requestId for same logical submission', () {
    final controller = CashDropFormController();
    final first = controller.ensurePendingRequestId();
    final second = controller.ensurePendingRequestId();
    expect(first, isNotEmpty);
    expect(second, first);
    controller.clearPendingRequestId();
    final third = controller.ensurePendingRequestId();
    expect(third, isNot(first));
  });

  test('catalog loads OUT movement types only', () async {
    final repository = _CatalogRepository(types: const [
      CashMovementTypeOption(
        movementTypeId: 'd1',
        code: 'CASH_DROP',
        name: 'Safe Drop',
        direction: 'OUT',
        requiresReason: false,
        affectsExpectedCash: true,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashDropCatalogProvider.notifier).load();
    final state = container.read(cashDropCatalogProvider);
    expect(state.status, CashDropCatalogStatus.ready);
    expect(state.types.single.direction, 'OUT');
    expect(repository.lastDirection, 'OUT');
  });

  test('empty OUT catalog does not invent hardcoded reasons', () async {
    final repository = _CatalogRepository(types: const []);
    final container = ProviderContainer(
      overrides: [
        cashDrawerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cashDropCatalogProvider.notifier).load();
    final state = container.read(cashDropCatalogProvider);
    expect(state.status, CashDropCatalogStatus.empty);
    expect(state.types, isEmpty);
  });

  test('amount above available cash is invalid', () {
    expect(
      validateCashDropAmount('101', maxAvailable: 100),
      isNotNull,
    );
    expect(
      validateCashDropAmount('100', maxAvailable: 100),
      isNull,
    );
  });

  test('movement type must come from loaded catalog', () {
    expect(
      validateCashDropMovementType(
        'missing',
        availableTypes: const [
          CashMovementTypeOption(
            movementTypeId: 'd1',
            code: 'CASH_DROP',
            name: 'Safe Drop',
            direction: 'OUT',
            requiresReason: false,
            affectsExpectedCash: true,
          ),
        ],
      ),
      isNotNull,
    );
  });

  test('remaining expected cash is local preview only', () {
    final remaining = cashDropRemainingExpectedCash(
      currentExpectedCash: 1000,
      form: const CashDropFormState(amountText: '250'),
    );
    expect(remaining, 750);
  });
}

class _CatalogRepository implements CashDrawerRepository {
  _CatalogRepository({required this.types});

  final List<CashMovementTypeOption> types;
  String? lastDirection;

  @override
  Future<List<CashMovementTypeOption>> getCashInMovementTypes() async =>
      const [];

  @override
  Future<List<CashMovementTypeOption>> getCashDropMovementTypes() async {
    lastDirection = 'OUT';
    return types;
  }

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
