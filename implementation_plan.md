# Task 4 Outlet Pixel-Accurate Flutter Implementation Plan

Status: Backend contract completed in Task 4A; Flutter Task 4B may consume the verified tenant-admin contracts below.

## Verified Task 4A backend contract

1. Canonical Tenant Admin list route: `GET /api/v1/tenant-admin/outlets`. `GET /api/v1/outlets` remains unchanged for generic consumers.
2. List query parameters: `pageNumber`, `pageSize`, `search`, `outletType`, `status`, `operationalHealth`, `sortBy`, and `sortDirection`.
3. List response envelope is `{ "data": { "items", "pageNumber", "pageSize", "totalCount" } }`. Each item has `id`, `name`, `code`, `type`, `status`, nullable `imageUrl`, nullable `manager` (`tenantUserId`, nullable `displayName`, nullable `avatarUrl`), nullable `tills` (`totalCount`, `activeCount`, `onlineCount`), nullable `operationalHealth` (`status`, `activeAlertCount`), nullable `location` (`addressLine`, `city`, `displayLocation`), and `access.canViewTillsAndHealth`.
4. `search` is server-side and covers outlet name, code, primary manager display name, physical address line, and city. Type, lifecycle status, and operational health filters are separate and combine before total count and pagination.
5. Operational-health values are `HEALTHY`, `NEEDS_ATTENTION`, `CRITICAL`, and `UNKNOWN`. Online requires an active assigned device with a heartbeat inside `TillMonitoring:HeartbeatTimeoutSeconds`; list and overview share the same classification.
6. Canonical lifecycle mutation: `PUT /api/v1/tenant-admin/outlets/{outletId}/status` with `{ "status": "ACTIVE" }` or `{ "status": "INACTIVE" }`. Disable does not delete. It requires `tenant.outlets.manage` or `tenant.outlets.update` and rejects default outlets, open till sessions, active tills, open orders, and reserved inventory.
7. List access accepts `tenant.outlets.view`, `tenant.outlets.details.view`, or `tenant.outlets.manage`. Till and health previews require `tenant.outlets.tills.view`, `tenant.tills.view`, or `tenant.outlets.manage`; otherwise both are null and `access.canViewTillsAndHealth` is false. Manager data is restricted to the preview fields above; no manager email or phone is present.
8. Nullable manager, image, and location fields must remain null in Flutter. Do not replace them with business-looking placeholders. Till and health summaries are list-authorized preview sections, not detail identifiers.

## Mandatory implementation corrections

### 1. Route usage

- Keep the paginated list on the verified implemented route `GET /api/v1/outlets` unless backend introduces a canonical tenant-admin list endpoint.
- Use `GET /api/v1/tenant-admin/outlets/{id}/overview` only for the selected outlet overview pane.
- Do not guess between list routes in Flutter code.

### 2. Backend integration rules

- Use the tenant-admin list contract for rows and call the overview endpoint only for the selected outlet.
- Do not issue overview requests per list item and do not client-filter a server-paginated list.
- Use the lifecycle status endpoint for Activate and Disable; never call Delete for Disable.

## Planned Flutter changes after blockers are resolved

### 3. Selection state

- Add `selectedOutletIdProvider` initialized to `null`.
- After the first successful list load:
  - preserve the current selection if that outlet still exists in the latest page payload
  - otherwise select the first outlet in the returned list
  - keep `null` when the list is empty

### 4. Stale-request protection

- Protect rapid outlet switching on the selected overview request.
- Use the project Dio layer with request cancellation or request identity validation in an `autoDispose` provider so an older overview response cannot replace a newer selection.

### 5. Filter dimensions

- Replace the current coupled filter model with separate dimensions:
  - Outlet type
  - Lifecycle status
  - Operational health
  - Additional filters
- Do not model `Store`, `Warehouse`, `Active`, and `Needs Attention` as one mutually exclusive enum.

### 6. Clean data path

- Keep the data flow fully layered:
  - DTO
  - Domain entity
  - DTO-to-domain mapping
  - Remote datasource
  - Repository interface
  - Repository implementation
  - Providers/notifiers
  - API response-envelope parsing
  - Error mapping
- Do not expose raw JSON or DTOs directly to presentation widgets.

### 7. Overview scope

- Manager and image shown in the screenshot must come from the selected overview API only.
- Do not add manager or image management controls to the visible desktop layout unless an already-approved interaction entry point exists.

### 8. Unauthorized sections

- Render unauthorized overview sections as restricted or hidden states.
- Do not show fake zero values.
- Do not leak restricted values through semantics, tooltips, logs, or debug UI.

### 9. Feature-scoped styling

- Scope outlet-specific layout, size, spacing, and token adjustments to `lib/features/tenant_admin/outlets`.
- Do not modify shared tenant-admin shell behavior in ways that affect unrelated screens.

### 10. Testing and validation

- Use Flutter's standard `test/` directory only.
- Add tests for:
  - DTO mapping
  - provider and state behavior
  - widget behavior
  - responsive layout
  - accessibility
  - no-overflow behavior
  - keyboard and focus traversal
  - tooltip behavior
  - semantics
  - color contrast verification where testable
- Final visual validation must include:
  - screenshot at exactly `1600 x 900`
  - browser zoom `100%`
  - recorded device-pixel ratio
  - side-by-side comparison
  - overlay or difference comparison
  - documented remaining pixel differences

## Current Flutter mismatches already identified

- `lib/features/tenant_admin/outlets/data/datasources/outlet_remote_datasource.dart` is hard-coded to `/api/v1/outlets`.
- `lib/features/tenant_admin/outlets/presentation/widgets/outlet_table.dart` currently uses `_mockManager(...)`, which violates the real-data-only requirement.
- The current presentation filter model only supports outlet type and lifecycle status, not separate operational-health and additional-filter dimensions.
- No `selectedOutletIdProvider` exists yet in the current outlet providers.

## Execution decision

- Do not start Flutter feature implementation until the backend contract gaps above are resolved or the task scope is amended.
- Once backend support exists, continue with the Flutter changes in this order:
  1. DTO and domain updates
  2. mapper and datasource updates
  3. repository and error-envelope updates
  4. provider and selection-state updates
  5. overview stale-request protection
  6. desktop, tablet, and mobile UI updates
  7. permission and unauthorized rendering
  8. activate and disable flows
  9. tests
  10. visual validation artifacts
