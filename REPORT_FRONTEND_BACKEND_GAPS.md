# Reports Frontend / Backend Gaps

## Scope

This file records verified gaps for the Tenant Admin Reports frontend. The
frontend must show an API-unavailable state for these gaps and must not replace
them with mock values or client-calculated authoritative totals.

## Current Evidence

| Area | Current evidence | Frontend behaviour |
|---|---|---|
| Routes | Flutter route definitions already contained dashboard, sales, stock, and outlet report paths | Placeholder routing is replaced by real report screens |
| Report APIs | No Reports controller, service, repository, or `/api/v1/tenant-admin/reports/*` route exists in `Unified-Commerce/src` | Typed calls use planned routes and map 404/405/501 to API unavailable |
| Dashboard endpoint | `/api/v1/tenant-admin/reports/dashboard` is planned but not implemented in the backend | Dashboard initializes valid filters and then shows a professional service-unavailable state when the endpoint returns 404/405/501 |
| Filter options endpoint | `/api/v1/tenant-admin/reports/filter-options` is planned but not implemented in the backend | Static mandatory context filters still render; optional filter dropdowns stay empty until the endpoint exists |
| Default dates | Backend does not yet expose tenant business date/timezone through Tenant Admin context | Frontend defaults to the current calendar month using the device date as the final UI fallback until tenant business date is available |
| Report summary tables | No daily report summary or report export job entity, DbSet, configuration, or migration exists | No summary-table assumption is made |
| Transaction sources | Sales, payment, refund, return, inventory, stock movement, till-session summary, product, till, and outlet entities exist | Frontend waits for dedicated backend projections |
| Export | No report export endpoint or export-job persistence exists | Export remains hidden because no seeded export permission exists |

## Missing Endpoints

- `GET /api/v1/tenant-admin/reports/filter-options`
- `GET /api/v1/tenant-admin/reports/dashboard`
- `GET /api/v1/tenant-admin/reports/sales`
- `GET /api/v1/tenant-admin/reports/sales/{orderId}`
- `GET /api/v1/tenant-admin/reports/stock`
- `GET /api/v1/tenant-admin/reports/outlets`
- `POST /api/v1/tenant-admin/reports/exports`
- `GET /api/v1/tenant-admin/reports/exports/{jobId}`

## Missing Backend Contracts

- Common filter options and dependent outlet/till, hierarchy, product/variant filters.
- Server-side date validation using tenant timezone and business-date rules.
- Outlet-scope enforcement for every report query and filter option.
- Server pagination and allow-listed sorting for all tabular sections.
- Dashboard KPI, trend, payment, product, and outlet projections.
- Dashboard aggregate response fields for gross sales, net sales, transactions,
  average order value, discounts, tax, refunds, current stock value, sales
  trend, payment-method breakdown, top products, and outlet performance.
- Sales summary, transaction, product, category, payment, tax, discount,
  return/refund, cashier, and daily projections.
- Stock current, low, out-of-stock, batch/expiry, movement, and valuation projections.
- Outlet performance, till summary, and cashier projections.
- Sales transaction detail projection with masked or permission-controlled PII.
- Backend-calculated net sales, refunds, tax snapshots, percentages, inventory
  valuation, shortage, expiry, and comparison-period values.
- CSV, XLSX, and PDF export generation for the full permitted result set.

## Permission Gaps

Verified existing or seeded codes:

- `reports.sales.view`
- `tenant.reports.sales.view`
- `tenant.reports.products.view`
- `tenant.outlets.revenue.view`
- `tenant.stock.view`
- `tenant.stock.value.view`
- `tenant.stock.movements.view`
- `tenant.stock.expiry.view`

Frontend aliases also reference `report.view`, `reports.view`,
`report.sales.view`, and `reports.sales.view`; aliases are compatibility helpers,
not proof that each code is seeded.

Proposed but unverified/unseeded codes:

- `tenant.reports.dashboard.view`
- `tenant.reports.payments.view`
- `tenant.reports.tax.view`
- `tenant.reports.discounts.view`
- `tenant.reports.returns.view`
- `tenant.reports.cashiers.view`
- `tenant.reports.outlets.view`
- `tenant.reports.tills.view`
- `tenant.reports.daily-sales.view`
- `tenant.reports.export`
- `tenant.reports.customer-pii.view`

The frontend does not grant proposed permissions through aliases. Tabs and
sensitive actions that require an unseeded permission remain hidden.

## Naming And Route Conflicts

- The menu uses `report.view`, while route definitions use `reports.view`.
- The backend has both legacy `reports.sales.view` and newer
  `tenant.reports.sales.view` evidence.
- Second Brain currently describes generic `/api/v1/reports/*` groups, while the
  approved frontend target uses `/api/v1/tenant-admin/reports/*`.
- Report Catalog, field mapping, API contract, responsive, permission,
  calculation, acceptance, and implementation-status Second Brain files were
  not present during this frontend implementation.

## Database Fields Not Yet Exposed By Report APIs

- Historical order/line totals, statuses, channel, till/session, customer snapshots.
- Historical order tax and discount snapshots.
- Payment and payment-transaction amounts and method data.
- Return, return-line, refund, refund-line, and refund-allocation amounts.
- Inventory balances, reorder rules, batches, movements, and cost layers.
- Till sessions, till-session summaries, payment summaries, and cash movements.
- Current product category/department/brand hierarchy and outlet/till labels.

## Required Backend Decisions

- Business date for non-till orders and tenant-timezone boundaries.
- Outlet attribution for online or non-till sales.
- Cashier attribution when an order has no explicit cashier field.
- Approved return quantity source; current return entities do not expose one
  unambiguously.
- Historical category/brand and payment-method display-name snapshot policy.
- Inventory valuation method and multi-currency report behaviour.
- Synchronous export limit and future asynchronous job persistence.
