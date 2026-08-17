/// Backend-authored cash movement type catalog row.
class CashMovementTypeOption {
  const CashMovementTypeOption({
    required this.movementTypeId,
    required this.code,
    required this.name,
    required this.direction,
    required this.requiresReason,
    required this.affectsExpectedCash,
  });

  final String movementTypeId;
  final String code;
  final String name;
  final String direction;
  final bool requiresReason;
  final bool affectsExpectedCash;
}
