import '../../domain/entities/cash_drawer_summary.dart';
import '../../domain/entities/cash_movement.dart';
import '../../domain/repositories/cash_drawer_repository.dart';
import '../datasources/cash_drawer_remote_datasource.dart';

class CashDrawerRepositoryImpl implements CashDrawerRepository {
  const CashDrawerRepositoryImpl(this._remote);
  final CashDrawerRemoteDatasource _remote;

  @override
  Future<CashDrawerSummary> getSummary(String deviceId) async {
    final json = await _remote.getSummary(deviceId);
    return CashDrawerSummary(
      tillSessionId: _text(json['tillSessionId']),
      tillId: _text(json['tillId']),
      tillName: _text(json['tillName']),
      status: _text(json['status']),
      openedBy: _text(json['openedBy']),
      openedTime: DateTime.tryParse(_text(json['openedAt'])),
      openingCash: _number(json['openingCash']),
      cashSales: _number(json['cashSales']),
      cashRefunds: _number(json['cashRefunds']),
      cashDrops: _number(json['cashDrops']),
      cashIns: _number(json['cashIn']),
      cashOuts: _number(json['cashOut']),
      currentExpectedCash: _number(json['currentExpectedCash']),
      currencyCode: _text(json['currencyCode']),
    );
  }

  @override
  Future<List<CashMovement>> getMovements(String deviceId,
      {int page = 1, int pageSize = 25}) async {
    final json = await _remote.getMovements(deviceId, page, pageSize);
    final items = json['items'];
    return items is List
        ? items
            .whereType<Map>()
            .map((x) => _movement(Map<String, dynamic>.from(x)))
            .toList()
        : const [];
  }

  @override
  Future<CashMovement> createMovement(
      {required String requestId,
      required String deviceId,
      required String tillSessionId,
      required CashMovementType type,
      required double amount,
      required String reason,
      String? referenceNumber}) async {
    final json = await _remote.createMovement({
      'requestId': requestId,
      'deviceId': deviceId,
      'tillSessionId': tillSessionId,
      'movementType': _code(type),
      'amount': amount,
      'reason': reason,
      'referenceNumber': referenceNumber,
    });
    return _movement(json);
  }

  CashMovement _movement(Map<String, dynamic> json) => CashMovement(
        id: _text(json['movementId']),
        type: _type(_text(json['movementType'])),
        amount: _number(json['amount']),
        dateTime: DateTime.parse(_text(json['performedAt'])),
        userName: _text(json['performedBy']),
        reason: json['reason']?.toString(),
        note: json['reference']?.toString(),
      );
  static String _text(Object? value) => value?.toString() ?? '';
  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.parse(value.toString());
  static String _code(CashMovementType type) => switch (type) {
        CashMovementType.cashIn => 'CASH_IN',
        CashMovementType.cashOut => 'CASH_OUT',
        CashMovementType.cashDrop => 'CASH_DROP',
        CashMovementType.cashSale => 'CASH_SALE',
        CashMovementType.cashRefund => 'CASH_REFUND',
      };
  static CashMovementType _type(String value) => switch (value) {
        'CASH_SALE' => CashMovementType.cashSale,
        'CASH_REFUND' => CashMovementType.cashRefund,
        'CASH_IN' => CashMovementType.cashIn,
        'CASH_OUT' => CashMovementType.cashOut,
        _ => CashMovementType.cashDrop,
      };
}
