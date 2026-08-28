# Tenant Admin RBAC Phase 3 Flutter 5-Step Implementation

## Scope

Implemented the Tenant Admin Roles & Access setup flow in Flutter only. No
files under `Unified-Commerce` were changed.

## Canonical flow

The existing role setup routes now configure an existing system role through
five steps:

1. Select Role
2. Select Modules
3. Configure Permissions
4. Assign Users & Access Scope
5. Review & Save

Step 1 loads `GET /api/v1/tenant-admin/roles/setup-options` and filters its
rendered options defensively to `TENANT_ADMIN` and `CASHIER`. `SUPER_ADMIN`,
custom-role fields, draft saving, and role creation are not part of this flow.

## Backend contract usage

- Permission catalog: `GET /api/v1/tenant-admin/permission-catalog`
- Existing role permissions: `GET /api/v1/tenant-admin/roles/{roleId}/permissions`
- Existing assignments: `GET /api/v1/tenant-admin/roles/{roleId}/assignments`
- User search: existing tenant user API with name, email, and staff-code hint
- Outlet selection: existing outlet-options provider/API
- Final atomic save: `PUT /api/v1/tenant-admin/roles/{roleId}/setup`

The final request carries the authoritative permission set, per-user
`TENANT_WIDE` or `SELECTED_OUTLETS` assignment scope, selected outlet IDs, and
the optimistic-concurrency timestamp.

## UI and state behavior

- Module and permission controls honor `assignable` and `blockedReason`.
- Each selected user retains an independent access scope and outlet selection.
- Assignment review retains user display details after scope changes.
- The final save invalidates role, context, access-checker, and menu providers.
- The shared wizard shell and each step reflow for compact and tablet widths.

## Verification

- `dart format` on all touched Dart files: PASS
- Focused static analysis: PASS (`No issues found`)
- `flutter analyze`: PASS (`No issues found!`, 11.8s)
- `flutter test test/features/tenant_admin/role_setup_wizard_provider_test.dart`: PASS
- `git diff --check`: PASS (line-ending warnings only; no whitespace errors)

## Focused test coverage

`test/features/tenant_admin/role_setup_wizard_provider_test.dart` verifies:

- `SUPER_ADMIN` is excluded even if returned by a repository fixture.
- `TENANT_ADMIN` and `CASHIER` remain available.
- Existing permissions are preserved in the selected role setup.
- A user can be configured with selected-outlet scope.
- Final setup sends one atomic role setup request with the correct outlet IDs.

## Final verdict

BACKEND READY FOR 5-STEP FLUTTER IMPLEMENTATION
