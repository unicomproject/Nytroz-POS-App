/// Deprecated: Cash Drop reasons are loaded from backend `cash_movement_types`
/// with `direction=OUT`. Kept as an empty stub so old imports fail loudly in
/// review rather than silently driving financial authority.
@Deprecated('Use cashDropCatalogProvider / CashMovementTypeOption instead')
class CashDropReason {
  const CashDropReason._();
}
