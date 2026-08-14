import '../entities/cash_drawer_summary.dart';
import '../entities/cash_movement.dart';

abstract interface class CashDrawerRepository {
  Future<CashDrawerSummary> getSummary(String deviceId);
  Future<List<CashMovement>> getMovements(String deviceId,
      {int page = 1, int pageSize = 25});
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
