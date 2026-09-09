<!-- title: Tenant Admin Hardware Integration Six Screen Implementation -->
<!-- status: Active -->
<!-- system: OneVerz POS MVP -->
<!-- last_updated: 2026-09-09 -->

# Tenant Admin Hardware Integration — 2026-09-09

## Status and scope

Software refinement implemented locally; physical production acceptance remains pending.
This update does not supersede the physical acceptance matrix or approve payment terminals.
No database migration, duplicate hardware API, provider SDK or generic hardware agent was added.
No live hardware command, drawer pulse, email or production deployment was performed.

## As-Is vs To-Be

| Area | Before | Implemented |
|---|---|---|
| API wiring | Flutter requested nonexistent tenant/hardware routes | Existing tenant-admin registry and assignment routes |
| Dashboard | First page only, plain list | Search, five-row local pages, full registry loading, summary and action menus |
| Add | Raw configuration JSON; unsupported payment code | Category selection, typed form, supported backend values |
| Discover | No Admin entry | Existing Android USB / bonded Bluetooth printer facade |
| Configure | Flat generic fields | Conditional fields and responsive preview column |
| Assignment | Unfiltered till dropdown | Active same-outlet tills; trusted POS currently attached to selected till |
| Details | Placeholder | Registry details, assignment, release and test evidence |
| Access | Manage-only sidebar could reach view-only route denial | Hardware view OR manage accepted for list/details |
| Readiness | Lifecycle shown without physical distinction | Existing till heartbeat/latest-test projection |

## Screen mapping

Local documentation identifiers HW-01 through HW-06 are labels, not reserved global journey IDs.

| ID | Screen | Backend | Frontend | Remaining limit |
|---|---|---|---|---|
| HW-01 | Hardware Integration Dashboard | Existing registry + till readiness | Implemented | Readiness retrieval needs till API permissions |
| HW-02 | Add Hardware Device | Existing create | Implemented | Scale/display remain registry-only |
| HW-03 | Discover Devices | Native facade, not backend discovery | Partial by capability | Android printers only; Bluetooth already paired |
| HW-04 | Configure Device | Existing ConfigJson registry storage | Implemented metadata form | POS runtime configuration remains separate |
| HW-05 | Assign Device | Existing till/POS/release | Implemented | POS choice is selected till's trusted bound POS |
| HW-06 | Test & Go Live | Existing trusted telemetry/test projection | Guided flow implemented | Physical execution via existing POS settings; no remote queue |

## Screen flow and behavior

Dashboard -> Add -> select category -> Discover -> Configure -> Assign -> Test & Go Live.
Creation navigates to the created registry ID; a failed save stays on the form.
Search covers loaded devices, codes, types and outlet names; list pages show at most five rows.
Dashboard Test All Devices opens a per-device checklist; it does not pretend to dispatch remote commands.
The detail page shows the latest recorded test and directs staff to the assigned POS.
On native platforms, Open this POS hardware testing uses the existing /pos/settings route guard.
This opens that POS's settings, not an arbitrary remote registry device.
Complete Setup requires the selected device's displayed readiness to be Ready.
Start Selling requires all devices assigned to that same target to be Ready; normal POS authorization still applies.
White hardware content, orange primary actions, rounded Material cards and the existing dark sidebar are reused.
Configure preview uses two columns at available width >=700; smaller layouts stack.
Cancel/Back do not write; release asks for explicit confirmation before removing an assignment.
Edit URLs no longer silently create another device; runtime settings are changed on the POS.

## Backend/API mapping

All Tenant Admin paths below have prefix /api/v1/tenant-admin.

| Method/path | Existing responsibility |
|---|---|
| GET /hardware-devices | Registry listing with backend tenant scope |
| GET /hardware-devices/{id} | Metadata and active assignment |
| POST /hardware-devices | Register metadata/configuration |
| POST /tills/{id}/hardware-assignments | Direct till assignment |
| POST /pos-devices/{id}/hardware-assignments | POS-device assignment |
| POST /hardware-assignments/{id}/release | Release assignment |
| Existing till hardware-readiness API | Trusted connection and latest test projection |
| POST /api/v1/pos/devices/{id}/hardware-heartbeat | Existing native telemetry |
| POST /api/v1/pos/hardware-tests | Existing append-only test reporting |

## Frontend/provider mapping

Module: lib/features/tenant_admin/hardware.
hardwareListProvider loads registry pages; hardwareDetailProvider loads one device.
hardwareTillsProvider loads till options; hardwareReadinessProvider reuses TillRepository.getTillHardwareReadiness.
HardwareRemoteDataSourceImpl still uses appDioProvider; no second HTTP client or state management pattern.
MethodChannelAndroidReceiptPrinter is reused for USB permission and bonded Bluetooth enumeration.
Existing printer, drawer and scanner controllers remain authoritative for physical POS tests.
New hardware_setup_widgets.dart scopes the light/orange theme and reusable cards/preview layout.

## Validation and boundaries

Code/name required; maximum 80/150 characters; optional metadata limited to 120.
Network host required by the new form; port 1-65535; backend handles malformed JSON safely.
Payment Terminal maps to CARD_READER + PROVIDER; raw transport registration is rejected.
No payment credentials or card data are requested by these screens.
Drawer parent metadata is optional for legacy records but required by the new printer-attached drawer form.
When supplied, parent must be an active receipt printer in the same tenant/outlet.
Drawer assignment requires its parent to have the exact same direct-till or POS assignment target.
Printer release is rejected while an assigned drawer references it.
Only ACTIVE hardware can be newly assigned.
Existing backend tenant/outlet checks, single active assignment and permissions remain in place.
Parent references use existing ConfigJson, not a new relational FK; concurrent reassign/release hardening remains a gap.

## Status definitions

ACTIVE is lifecycle, never proof of Ready.
Unassigned -> Not Configured; missing evidence -> Unknown.
Backend Disconnected -> Disconnected; maintenance/attention or failed latest test -> Issues.
Connected plus latest PASSED/SUCCESS -> Ready; connected without passing test -> Not Configured.
Readiness is a fetched snapshot; Refresh reloads it. Unknown devices are disclosed separately from summary counts.
Registration does not apply printer transport settings to the POS runtime configuration automatically.

## Verification

Flutter hardware regression/model tests: 6 passed (including 1024x768 list/search and setup validation).
Flutter analyze --no-pub: No issues found.
Backend isolated hardware service/readiness tests: 21 passed.
Full backend UnitTests compilation is blocked by unrelated invitation-composer ambiguity and stale AdminPassword test reference.
Isolated harness: .codex-tmp/hardware-verification/HardwareVerification.csproj; links actual repository tests and Application project.
No live DB integration, native discovery on physical equipment, provider test or production E2E acceptance in this update.

## R&D sources and remaining work

Android USB enumeration/permission model: [Android USB host](https://developer.android.com/develop/connectivity/usb/host).
Provider-certified reader/SDK architecture reference: [Stripe Terminal overview](https://docs.stripe.com/terminal/overview); this does not select Stripe for OneVerz.
LAN/serial automatic discovery, new Bluetooth pairing UI and non-printer auto-discovery remain unavailable.
Provider integration, runtime registration-to-configuration transfer and physical printer/scanner/drawer matrix remain pending.
No sample Epson/Zebra/APG/Verifone entries are presented as detected devices.
Second Brain: 15_IMPLEMENTATION_TRACKING/Flutter/Hardware/Tenant_Admin_Hardware_Integration_2026-09-09.md; linked from integration overview, tenant journey and feature index.

## Modified files

Flutter paths are relative to lib/features/tenant_admin/:

- hardware/data/datasources/hardware_remote_datasource.dart — fix six API routes.
- hardware/presentation/providers/hardware_list_provider.dart — paginated registry loading, details, tills, readiness.
- hardware/presentation/screens/hardware_list_screen.dart — dashboard, search, table, five-row pages, test checklist.
- hardware/presentation/screens/add_hardware_screen.dart — category/discovery/configure flow and validation.
- hardware/presentation/screens/hardware_detail_screen.dart — assignment, details, release, test evidence and POS handoff.
- hardware/presentation/widgets/assign_hardware_dialog.dart — filtered assignment choices.
- tenant_admin_router.dart — align list/details view-or-manage permission.
- Unified-Commerce/src/E_POS.Application/Modules/Tenant/HardwareCash/Services/TenantAdminHardwareService.cs — JSON/provider/parent/assignment checks.
- Unified-Commerce/tests/E_POS.UnitTests/HardwareCash/TenantAdminHardwareServiceTests.cs — regression tests.

## Added files

- lib/features/tenant_admin/hardware/presentation/widgets/hardware_setup_widgets.dart — scoped theme, responsive panels and supported-device help.
- test/features/hardware/tenant_admin_hardware_setup_test.dart — route, readiness, dashboard and configuration widget regressions.
- docs/implementation/HARDWARE_INTEGRATION_IMPLEMENTATION_2026-09-09.md — this report.
- Second Brain hardware implementation note (path above).
- Local test harness and staging documentation under workspace .codex-tmp; not application source.

## Delivery limitations

The six UI stages are implemented as three existing route screens plus assignment dialog/internal steps, not six duplicate top-level routes.
Metadata is saved to the registry; the established POS configuration workflow must still configure the physical runtime.
No native APK build/install or authenticated emulator/API end-to-end was performed.
No payment provider or physical device credentials were supplied or invented.
The full feature is not certified production-ready.
Git changes are local; no commit, push or deployment was performed for this request.
