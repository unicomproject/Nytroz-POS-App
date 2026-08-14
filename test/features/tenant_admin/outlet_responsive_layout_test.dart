import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_detail_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/selected_outlet_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/utils/outlet_list_filters.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/widgets/outlet_detail_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/widgets/outlet_list_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  group('Outlet responsive layout polish', () {
    for (final viewport in _viewportCases) {
      testWidgets('keeps ${viewport.label} viewport overflow-free',
          (tester) async {
        await _pumpListPanel(
          tester,
          size: viewport.panelSize,
          boundedHeight: viewport.boundedHeight,
          isMobile: viewport.isMobile,
        );

        expect(find.text('High Street Store'), findsOneWidget);
        expect(_hasFlutterOverflow(tester), isFalse);
      });
    }

    testWidgets('renders desktop split list panel at 1600x900 without overflow',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(1040, 780),
        boundedHeight: true,
      );

      expect(find.text('Outlets'), findsOneWidget);
      expect(find.text('Manage all business outlets and sales locations.'),
          findsOneWidget);
      expect(find.text('High Street Store'), findsOneWidget);
      expect(find.text('Add Outlet'), findsOneWidget);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('keeps list internally scrollable in bounded desktop panel',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(900, 520),
        boundedHeight: true,
        outlets: _manyOutlets,
      );

      final listView = tester.widget<ListView>(find.byType(ListView).first);

      expect(listView.shrinkWrap, isFalse);
      expect(listView.physics, isA<ClampingScrollPhysics>());
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('renders 1366x768 compact desktop without overflow',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(820, 648),
        boundedHeight: true,
      );

      expect(find.text('Warehouse'), findsWidgets);
      expect(find.text('Needs Attention'), findsWidgets);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('renders 1024x768 tablet layout without overflow',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(620, 648),
        boundedHeight: true,
      );

      expect(find.text('Store'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('renders mobile stacked list without horizontal overflow',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(390, 844),
        isMobile: true,
      );

      expect(find.text('Add'), findsOneWidget);
      expect(find.text('High Street Store'), findsOneWidget);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('uses orange Add Outlet button and selected card emphasis',
        (tester) async {
      await _pumpListPanel(
        tester,
        size: const Size(900, 620),
        boundedHeight: true,
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final buttonColor = button.style?.backgroundColor?.resolve({});
      expect(buttonColor, TenantAdminColors.posHomeAccentOrange);

      final hasSelectedOrangeBorder = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .any((widget) {
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) {
          return false;
        }

        final border = decoration.border;
        return border is Border &&
            border.top.color == TenantAdminColors.posHomeAccentOrange;
      });

      expect(hasSelectedOrangeBorder, isTrue);
    });

    testWidgets('renders selected outlet detail panel metrics responsively',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedOutletIdProvider.overrideWith((ref) => 'outlet-1'),
            tenantAdminOutletOverviewProvider.overrideWith(
              (ref, id) async => _overview,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: OutletDetailPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('High Street Store'), findsOneWidget);
      expect(find.text('Contact Details'), findsOneWidget);
      expect(find.text("Today's Sales"), findsOneWidget);
      expect(find.text('Active Tills'), findsOneWidget);
      expect(find.text('Net sales today'), findsOneWidget);
      expect(_hasFlutterOverflow(tester), isFalse);
    });
  });
}

Future<void> _pumpListPanel(
  WidgetTester tester, {
  required Size size,
  bool boundedHeight = false,
  bool isMobile = false,
  List<Outlet> outlets = _outlets,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: isMobile
                ? SingleChildScrollView(
                    child: OutletListPanel(
                      result: OutletListResult(
                        summary: _summary,
                        items: outlets,
                        page: 1,
                        pageSize: 10,
                        totalCount: outlets.length,
                      ),
                      visibility: _visibility,
                      statusFilter: OutletStatusFilter.all,
                      isMobile: true,
                      boundedHeight: boundedHeight,
                    ),
                  )
                : OutletListPanel(
                    result: OutletListResult(
                      summary: _summary,
                      items: outlets,
                      page: 1,
                      pageSize: 10,
                      totalCount: outlets.length,
                    ),
                    visibility: _visibility,
                    statusFilter: OutletStatusFilter.all,
                    isMobile: false,
                    boundedHeight: boundedHeight,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

bool _hasFlutterOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) {
    return false;
  }

  return exception.toString().contains('RenderFlex overflowed');
}

const _summary = OutletListSummary(
  totalOutlets: 3,
  activeOutlets: 2,
  inactiveOutlets: 1,
  totalLocations: 3,
);

const _viewportCases = [
  _ViewportCase(
    label: '1920x1080 desktop',
    panelSize: Size(1260, 960),
    boundedHeight: true,
  ),
  _ViewportCase(
    label: '1600x900 desktop',
    panelSize: Size(1040, 780),
    boundedHeight: true,
  ),
  _ViewportCase(
    label: '1366x768 laptop',
    panelSize: Size(820, 648),
    boundedHeight: true,
  ),
  _ViewportCase(
    label: '1024x768 tablet landscape',
    panelSize: Size(620, 648),
    boundedHeight: true,
  ),
  _ViewportCase(
    label: '820x1180 tablet portrait',
    panelSize: Size(820, 1180),
  ),
  _ViewportCase(
    label: '768x1024 tablet portrait',
    panelSize: Size(768, 1024),
  ),
  _ViewportCase(
    label: '390x844 mobile',
    panelSize: Size(390, 844),
    isMobile: true,
  ),
];

class _ViewportCase {
  const _ViewportCase({
    required this.label,
    required this.panelSize,
    this.boundedHeight = false,
    this.isMobile = false,
  });

  final String label;
  final Size panelSize;
  final bool boundedHeight;
  final bool isMobile;
}

const _visibility = OutletListVisibility(
  showPage: true,
  showTitle: true,
  showSubtitle: true,
  showSearch: true,
  showFilter: true,
  showAddOutlet: true,
  showSummarySection: false,
  showList: true,
  showPagination: true,
  showMobileStatusBadge: true,
  showMobileLocation: true,
  showMobileTillSummary: true,
  showMobileStaffSummary: true,
  showMobileSales: true,
  showMobileActionsMenu: true,
  showActionsColumn: true,
  visibleSummaryCards: [],
  visibleColumns: [],
  visibleRowActions: [],
);

const _outlets = [
  Outlet(
    id: 'outlet-1',
    name: 'High Street Store',
    code: 'OUT-001',
    status: 'ACTIVE',
    outletType: 'Store',
    location: '12 High Street',
    city: 'Colombo',
    managerName: 'Kavin Perera',
    tillCount: 4,
    activeTillCount: 3,
    onlineTillCount: 3,
    canViewTillsAndHealth: true,
  ),
  Outlet(
    id: 'outlet-2',
    name: 'City Center Warehouse',
    code: 'OUT-002',
    status: 'INACTIVE',
    outletType: 'Warehouse',
    location: '44 Lake Road',
    city: 'Kandy',
    managerName: 'Nadeesha Dias',
    tillCount: 2,
    activeTillCount: 0,
    onlineTillCount: 0,
    canViewTillsAndHealth: true,
  ),
  Outlet(
    id: 'outlet-3',
    name: 'Negombo Outlet',
    code: 'OUT-003',
    status: 'ACTIVE',
    outletType: 'Store',
    location: '21 Beach Road',
    city: 'Negombo',
    managerName: 'Ruwan Madushanka',
    tillCount: 3,
    activeTillCount: 2,
    onlineTillCount: 2,
    canViewTillsAndHealth: true,
  ),
];

final _manyOutlets = [
  for (var index = 0; index < 12; index++)
    Outlet(
      id: 'outlet-$index',
      name: 'Outlet ${index + 1}',
      code: 'OUT-${(index + 1).toString().padLeft(3, '0')}',
      status: index.isEven ? 'ACTIVE' : 'INACTIVE',
      outletType: index.isEven ? 'Store' : 'Warehouse',
      location: 'Location ${index + 1}',
      city: 'Colombo',
      managerName: 'Manager ${index + 1}',
      tillCount: 4,
      activeTillCount: 2,
      onlineTillCount: 2,
      canViewTillsAndHealth: true,
    ),
];

const _overview = TenantAdminOutletOverview(
  id: 'outlet-1',
  name: 'High Street Store',
  code: 'OUT-001',
  type: 'Store',
  status: 'ACTIVE',
  addressLine1: '12 High Street',
  city: 'Colombo',
  managerName: 'Kavin Perera',
  managerEmail: 'kavin.perera@oneverz.com',
  managerPhone: '077 123 4567',
  totalTills: 4,
  activeTills: 3,
  onlineTills: 3,
  attentionTills: 1,
  todayNetSales: 125450,
  salesCurrency: 'LKR',
  stockValue: 480000,
  inventoryCurrency: 'LKR',
  openOrderCount: 8,
  healthStatus: 'HEALTHY',
  totalActiveAlertCount: 0,
  canViewTills: true,
  canViewSales: true,
  canViewInventory: true,
  canViewOrders: true,
  canViewAlerts: true,
);
