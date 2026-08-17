import '../entities/cash_drawer_summary.dart';
import '../entities/cash_movement.dart';
import '../entities/cash_movement_type.dart';

abstract interface class CashDrawerRepository {
  Future<CashDrawerSummary> getSummary(String deviceId);
  Future<List<CashMovement>> getMovements(String deviceId,
      {int page = 1, int pageSize = 25});
  Future<List<CashMovementTypeOption>> getCashInMovementTypes();
  Future<List<CashMovementTypeOption>> getCashDropMovementTypes();
  Future<CashMovement> createCashInMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  });
  Future<CashMovement> createCashDropMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  });

  /// Legacy Cash Out mutation until that Chunk is aligned.
  Future<CashMovement> createMovement({
    required String requestId,
    required String deviceId,
    required String tillSessionId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? referenceNumber,
  });
}
