# Nytroz POS - Tenant Admin Implementation Report

## 1. Project Setup

The Flutter project was upgraded into a professional multi-platform Flutter app structure.

### Added platform folders

- `android/` - Android native Gradle runner.
- `ios/` - iOS native Xcode runner.
- `web/` - Flutter web runner.
- `windows/` - Windows desktop runner.
- `linux/` - Linux desktop runner.
- `macos/` - macOS desktop runner.
- `test/` - Flutter test folder.

### Project identity

- App name: `Nytroz POS`
- Flutter package name: `nytroz_pos`
- Android organization/package base: `com.nytroz.pos`

## 2. Tenant Admin Foundation

Tenant Admin was implemented inside the same Flutter app, but with a separate operational layout from the POS/cashier layout.

### Main structure

```text
lib/features/tenant_admin/
--- tenant_admin_router.dart
--- data/
--- domain/
--- presentation/
```

### Key architecture rules followed

- Feature-based clean architecture.
- Riverpod for state management.
- GoRouter for routing.
- Dio for API calls.
- Backend-driven menu and access control.
- No hardcoded role names.
- No hardcoded sidebar access.
- Frontend checks are only UX checks.

## 3. Tenant Admin Context/Menu Foundation

The app calls backend-style APIs to load the current Tenant Admin context and allowed menu items.

### APIs wired

- `GET /api/tenant-admin/context`
- `GET /api/tenant-admin/menu`

### Context includes

- Tenant details.
- User details.
- Role summary.
- Feature entitlements.
- Permissions.
- Outlet scope.
- Runtime flags.
- Subscription status.

### Menu behavior

- Sidebar and bottom navigation are generated from backend menu response.
- Only allowed menu items are shown.
- Route guard checks menu visibility and permission access.

## 4. Tenant Admin Layout

Tenant Admin has its own responsive SaaS-style layout.

### Desktop/tablet

- Dark navy sidebar.
- Top bar.
- Light content area.
- Backend-driven sidebar menu.

### Mobile

- Top app bar.
- Bottom navigation.
- Menu generated from backend response.

## 5. Reusable Tenant Admin UI Kit

Reusable UI components were created for future modules.

### Widgets added

- `TenantAdminPageScaffold`
- `TenantAdminMetricCard`
- `TenantAdminStatusBadge`
- `TenantAdminSearchField`
- `TenantAdminFilterChip`
- `TenantAdminPrimaryButton`
- `TenantAdminSecondaryButton`
- `TenantAdminIconButton`
- `TenantAdminDataTable`
- `TenantAdminMobileListCard`
- `TenantAdminStepperHeader`
- `TenantAdminFormSection`
- `TenantAdminEmptyState`
- `TenantAdminErrorState`
- `TenantAdminLoadingSkeleton`
- `TenantAdminQuickActionCard`
- `TenantAdminActivityItem`
- `TenantAdminAlertItem`

### Theme helpers

- Centralized colors.
- Centralized spacing.
- Centralized border radius.
- Centralized responsive breakpoints.
- Shared typography helpers.

## 6. Tenant Admin Routing

Tenant Admin routing was implemented using GoRouter.

### Main routes

- `/tenant-admin/dashboard`
- `/tenant-admin/outlets`
- `/tenant-admin/outlets/add`
- `/tenant-admin/outlets/:id`
- `/tenant-admin/outlets/:id/edit`
- Placeholder protected routes for tills, staff, roles, products, stock, reports, billing, settings, and activity.

### Route guard behavior

- If user is not logged in, redirect to `/tenant-admin/login`.
- If menu/context is loading, show loading screen.
- If context/menu fails, show safe error screen.
- If permission is missing, show forbidden screen.

## 7. Tenant Admin Dashboard Module

Dashboard module was implemented using feature-based clean architecture.

### API wired

- `GET /api/tenant-admin/dashboard`

### Dashboard UI

- Today-s Sales metric.
- Orders metric.
- Active Outlets metric.
- Stock Alerts metric.
- Sales this week card.
- Needs attention card.
- Quick actions card.
- Recent activity card.

### Access

- Feature: `tenant_admin.dashboard`
- Permission: `dashboard.view`

## 8. Tenant Admin Outlets Module

Outlets frontend module was implemented.

### Routes

- `/tenant-admin/outlets`
- `/tenant-admin/outlets/add`
- `/tenant-admin/outlets/:id`
- `/tenant-admin/outlets/:id/edit`

### APIs wired

- `GET /api/tenant-admin/outlets`
- `GET /api/tenant-admin/outlets/{id}`
- `POST /api/tenant-admin/outlets`
- `PUT /api/tenant-admin/outlets/{id}`
- `PATCH /api/tenant-admin/outlets/{id}/status`

### Access

- `outlets.view` - list/details.
- `outlets.create` - add outlet.
- `outlets.update` - edit/status update.

### Screens added

- Outlet list screen.
- Outlet details screen.
- Add outlet screen.
- Edit outlet screen.

### Add outlet form

Implemented as a 4-step form:

1. Basic details.
2. Address and contact.
3. Opening hours.
4. Review and submit.

### Validation behavior

- Local required field validation.
- Backend validation errors shown under fields.
- Manager dropdown loaded from staff/manager API when available.

## 9. Tenant Admin Auth / Onboarding Flow

Pre-login payment flow and first-login setup flow were added under a separate feature.

### Structure

```text
lib/features/tenant_admin_auth/
--- tenant_admin_auth_router.dart
--- data/
--- domain/
--- presentation/
```

## 10. Pre-Login Payment Flow

### Routes

- `/tenant-admin/payment/:paymentToken`
- `/tenant-admin/payment/:paymentToken/summary`
- `/tenant-admin/payment/processing`
- `/tenant-admin/payment/success`

### APIs wired

- `GET /api/tenant-admin/onboarding/payment-summary/{paymentToken}`
- `POST /api/tenant-admin/onboarding/start-payment`
- `GET /api/tenant-admin/onboarding/payment-status/{paymentToken}`

### Screens

- Payment link landing screen.
- Billing summary screen.
- Payment processing screen.
- Payment success screen.

### Payment success message

`Payment completed successfully`

Next step message:

`Your admin account setup link has been sent to your email.`

## 11. First Login / Setup Flow

### Routes

- `/tenant-admin/setup/:setupToken`
- `/tenant-admin/setup/:setupToken/password`
- `/tenant-admin/setup/success`
- `/tenant-admin/login`

### APIs wired

- `GET /api/tenant-admin/onboarding/setup-token/{setupToken}/validate`
- `POST /api/tenant-admin/onboarding/setup-password`
- `POST /api/tenant-admin/auth/login`

### Screens

- Setup link validation screen.
- Set password screen.
- Setup success screen.
- Tenant Admin login screen.

### Password validation

- Password required.
- Confirm password required.
- Password and confirm password must match.
- Minimum 8 characters.
- Must include uppercase.
- Must include lowercase.
- Must include number.
- Must include special character.

## 12. Auth UI Design

The auth screens were redesigned to match the provided reference design.

### Final design direction

- Dark stadium-style background.
- Left branding/marketing panel on tablet and desktop.
- Centered white auth card.
- `Nytroz POS` branding.
- Compact responsive form layout.
- Removed the unwanted 1-2-3 progress stepper.
- Responsive mobile layout.

### Branding updates

- Old `SCS-TIX` branding was removed from Flutter source.
- New branding: `Nytroz POS`.

## 13. Session Handling

An in-memory Tenant Admin session provider was added.

### Behavior

- Login stores session in Riverpod state.
- Dio Authorization header is updated after login.
- Tenant Admin dashboard is blocked before login.
- After login, app refreshes Tenant Admin context/menu.

### Note

Persistent secure token storage is not implemented yet because no existing secure storage/session service was present in the current project.

## 14. Development API Fallback

A local development API fallback interceptor was added so UI can run without a backend.

### File

- `lib/dev/tenant_admin_dev_api_interceptor.dart`

### Purpose

- Allows dashboard, menu, context, outlets, payment, setup, and login flows to work locally.
- Can be disabled using the Dart define flag:

```bash
--dart-define=USE_DEV_API_FALLBACK=false
```

## 15. Current Run Command

The app is currently run using Flutter web server:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 53555
```

### Current test URLs

- Login: `http://127.0.0.1:53555/#/tenant-admin/login`
- Set password: `http://127.0.0.1:53555/#/tenant-admin/setup/setup-dev/password`
- Dashboard: `http://127.0.0.1:53555/#/tenant-admin/dashboard`

## 16. Validation Status

### Completed checks

- `flutter pub get` completed.
- `flutter analyze` passes with no issues.
- App runs on web server.

## 17. Backend Dependencies / Missing Real Integrations

The following backend pieces are still required for production:

- Real Tenant Admin context API.
- Real Tenant Admin menu API.
- Real dashboard API.
- Real outlets APIs.
- Real payment provider integration.
- Real setup-token validation.
- Real password setup API.
- Real login API with secure token/session handling.
- Persistent secure token storage on Flutter side.
- External payment return/deep-link handling.

## 18. Recommended Next Implementation Order

1. Add real backend authentication/session integration.
2. Replace dev API fallback with real backend APIs.
3. Add persistent secure token storage.
4. Complete Outlets backend validation integration.
5. Implement Tills module.
6. Implement Staff module.
7. Implement Roles & Access module.
8. Implement Products module.
9. Implement Stock module.
10. Implement Reports, Billing, Settings, and Activity.

## 19. Important Product Rules Preserved

- No e-commerce screens added.
- No offline sync UI added.
- No AI analytics added.
- No coupon features added.
- No supplier management added.
- No full accounting added.
- No advanced stock transfer added.
- No hardcoded role-based access.
- Backend remains final authority for real permission enforcement.

