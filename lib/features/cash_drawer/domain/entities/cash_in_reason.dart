/// Historical local reason labels.
///
/// Production Cash In reasons are loaded from
/// `GET /api/v1/pos/cash-movement-types?direction=IN` and selected by
/// `movementTypeId`. Do not restore a hardcoded production reason catalog.
@Deprecated('Use CashMovementTypeOption from the backend catalog')
class CashInReason {
  const CashInReason._();
}
