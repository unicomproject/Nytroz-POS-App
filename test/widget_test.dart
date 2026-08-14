import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/app/app.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_bootstrap_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/post_login_navigation_provider.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/features/device_activation/data/datasources/device_context_storage.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/domain/repositories/device_activation_repository.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/pos_shell/domain/entities/pos_home_action.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_home_remote_datasource.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_shell_navigation_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_home_screen.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_desktop_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_mobile_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/pos_new_sale_top_bar_content.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/product_card/pos_product_card.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/dashboard_action_card.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/sidebar/pos_sidebar.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_barcode_lookup_result.dart';
import 'package:nytroz_pos/features/pos/data/datasources/remote/pos_barcode_remote_datasource.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_new_sale_search_coordinator.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/screens/pos_close_till_screen.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/new_sale/pos_barcode_scan_controller.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/new_sale/pos_camera_scanner_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart';
import 'package:nytroz_pos/features/pos/presentation/screens/new_sale/pos_new_sale_screen.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';
import 'package:nytroz_pos/features/hardware/barcode_scanner/presentation/providers/barcode_scanner_configuration_provider.dart';
import 'package:nytroz_pos/features/hardware/device_configuration/models/pos_hardware_models.dart';

import 'support/pos_catalog_test_fixtures.dart';

void main() {
  group('POS Home', () {
    const posTabletViewport = Size(1280, 768);
    testWidgets('/pos/home renders the current dashboard actions', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Start New Sale'), findsWidgets);
      expect(find.text('Cash Drawer'), findsWidgets);
    });

    testWidgets('End Shift opens Close Till with the end-shift flag', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1200, 900),
        permissionCodes: const [
          ..._defaultPermissions,
          PosPermissionCodes.closeTill,
        ],
      );

      final endShiftAction = find.byWidgetPredicate(
        (widget) => widget is PosHomeActionTile && widget.title == 'End Shift',
      );
      expect(endShiftAction, findsOneWidget);
      await tester.tap(endShiftAction);
      await tester.pumpAndSettle();

      expect(find.byType(PosCloseTillScreen), findsOneWidget);
      final state = GoRouterState.of(
        tester.element(find.byType(PosCloseTillScreen)),
      );
      expect(state.uri.path, '/pos/cash-drawer/close-till');
      expect(state.uri.queryParameters['endShift'], 'true');
    });

    testWidgets('renders the complete reference dashboard cards', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.text('Manage Online Orders'), findsNothing);
      expect(find.text('Returns & Exchanges'), findsOneWidget);
      expect(find.text('Resume Held Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
      expect(find.text('Returns Today'), findsNothing);
      expect(find.text('Refunded Today'), findsNothing);
      expect(find.text('Total Customers'), findsNothing);
      expect(find.text('this week'), findsNothing);
      expect(find.text('Parked Sales Today'), findsNothing);
      expect(find.text('Older than 30 mins'), findsNothing);
      expect(find.text('Current Balance'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'View Returns'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Add Customer'), findsNothing);
      expect(
        find.widgetWithText(OutlinedButton, 'View Parked Sales'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'View Cash Drawer'),
        findsNothing,
      );
    });

    testWidgets('does not recreate Online Orders when backend omits the card', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1200, 900),
        permissionCodes: _permissionsWithOnlineOrders,
      );

      expect(find.text('Manage Online Orders'), findsNothing);
      expect(find.text('Start New Sale'), findsWidgets);
      expect(find.text('Returns & Exchanges'), findsOneWidget);
      expect(find.text('Resume Held Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
    });

    testWidgets('POS Home uses its dedicated navigation at tablet width', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      expect(find.byType(PosSidebar), findsNothing);
      expect(find.byType(PosDesktopTopBar), findsNothing);
      expect(find.byType(PosMobileTopBar), findsNothing);
      expect(find.byType(PosHomeScreen), findsOneWidget);
    });

    testWidgets('POS Home shell renders while dashboard provider is loading', (
      tester,
    ) async {
      final pendingDashboard = Completer<PosHomeDashboardState>();

      await _pumpPosHome(
        tester,
        size: const Size(1200, 900),
        dashboardOverride: (_) => pendingDashboard.future,
        settle: false,
      );

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Start New Sale'), findsWidgets);
      expect(find.text('Dashboard information is loading.'), findsOneWidget);

      pendingDashboard.complete(_referenceDashboardState(_defaultPermissions));
    });

    testWidgets('POS Home shell renders with dashboard provider error', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1200, 900),
        dashboardOverride: (_) => Future<PosHomeDashboardState>.error(
          const PosHomeException('Dashboard failed'),
        ),
      );

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Start New Sale'), findsWidgets);
      expect(find.text('Dashboard failed'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Retry'), findsNWidgets(2));
      expect(
        find.byKey(const Key('pos-home-summary-retry')),
        findsOneWidget,
      );
    });

    testWidgets('Home remains on /pos/home when tapped', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      _goFromCurrentRoute(tester, '/pos/home');
      await tester.pumpAndSettle();

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('New Sale route does not render sidebar without permission', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [PosPermissionCodes.viewHome],
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosSidebar), findsNothing);
      expect(find.byType(PosCashierBottomNavigation), findsNothing);
    });

    testWidgets('New Sale renders fixed navigation from backend permissions', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewOrders,
          PosPermissionCodes.viewNewSaleCustomers,
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.viewRefunds,
          PosPermissionCodes.viewCashDrawer,
          'reports.view',
        ],
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosSidebar), findsNothing);
      expect(find.byType(PosCashierBottomNavigation), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('New Sale'), findsWidgets);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('New Sale home destination opens the sale screen', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.text('Quick Products'), findsOneWidget);
      expect(find.text('No items added'), findsOneWidget);
      expect(find.byType(PosHomeScreen), findsNothing);
    });

    testWidgets('home-only user can view POS Home but cannot open New Sale', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [PosPermissionCodes.viewHome],
      );

      expect(find.byType(PosHomeScreen), findsOneWidget);

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsNothing);
      expect(
        find.text('You do not have permission to access this area.'),
        findsOneWidget,
      );
    });

    testWidgets('user with pos.new_sale.view can open New Sale shell', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.byType(PosTopBar), findsOneWidget);
      expect(find.byType(PosNewSaleTopBarContent), findsOneWidget);
      expect(find.text('New Sale'), findsWidgets);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('user with sales.create alias can open New Sale shell', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.createSale,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
    });

    testWidgets('Add Customer action hides with customers.view only', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.viewNewSaleCustomers,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Add Customer'), findsNothing);
    });

    testWidgets('Add Customer action does not show even with customers.create',
        (tester) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.createNewSaleCustomer,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Add Customer'),
        findsNothing,
      );
    });

    testWidgets('product quick-add and card taps update New Sale totals', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.addCartItem,
          PosPermissionCodes.updateCartItem,
          PosPermissionCodes.removeCartItem,
          PosPermissionCodes.checkoutSale,
          PosPermissionCodes.acceptCashPayment,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      final paymentButton = find.widgetWithText(
        FilledButton,
        'Proceed to Payment',
      );
      expect(tester.widget<FilledButton>(paymentButton).onPressed, isNull);
      expect(find.text('No items added'), findsOneWidget);
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('Discount'), findsNothing);
      expect(find.text('Tax'), findsNothing);

      await tester.tap(find.text('More Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tickets'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PosProductCard).first);
      await tester.pumpAndSettle();

      expect(find.text('No items added'), findsNothing);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('Tax'), findsOneWidget);
      expect(find.text('Qty 1'), findsOneWidget);
      // Product card + cart unit price show catalog values; line total waits for
      // authoritative checkout pricing.
      expect(find.text('LKR 1,500.00'), findsNWidgets(2));
      expect(find.text('—'), findsOneWidget);
      // Without a successful checkout-summary response, payment stays gated.
      expect(tester.widget<FilledButton>(paymentButton).onPressed, isNull);

      await tester.tap(find.text('General Admission').first);
      await tester.pumpAndSettle();

      expect(find.text('Qty 2'), findsOneWidget);
      expect(find.text('LKR 3,000.00'), findsWidgets);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(find.text('Qty 1'), findsOneWidget);
      expect(find.text('LKR 1,500.00'), findsNWidgets(2));
      expect(find.text('—'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove item'));
      await tester.pumpAndSettle();

      expect(find.text('No items added'), findsOneWidget);
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('Discount'), findsNothing);
      expect(find.text('Tax'), findsNothing);
      expect(tester.widget<FilledButton>(paymentButton).onPressed, isNull);
    });

    testWidgets('New Sale shared search filters product grid while typing', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.searchProducts,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      final scannerButton = find.byKey(
        const Key('new-sale-scanner-button'),
      );
      final searchField = find.byType(TextField);
      expect(scannerButton, findsOneWidget);
      expect(find.text('Scan barcode or search products'), findsOneWidget);
      expect(tester.getSize(searchField).height, 58);

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pumpAndSettle();

      expect(find.text('Coffee Voucher'), findsOneWidget);
      expect(find.text('General Admission'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Popular Products (13)'), findsOneWidget);
      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('Snack Combo'), findsOneWidget);
    });

    testWidgets(
        'camera scanner reuses exact pipeline and preserves leading zero',
        (tester) async {
      final exact = _WidgetBarcodeGateway();
      var launcherCalls = 0;
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        cameraSupported: true,
        cameraLauncher: (_) async {
          launcherCalls++;
          return const PosCameraScanResult.barcode('0012345678905');
        },
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'manual query');

      await tester.tap(find.byKey(const Key('new-sale-scanner-button')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosNewSaleScreen)));
      expect(launcherCalls, 1);
      expect(exact.calls.single.$2, '0012345678905');
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
          isEmpty);
      expect(container.read(posNewSaleSearchQueryProvider), isEmpty);
      expect(container.read(posNewSaleCartProvider).items, hasLength(1));
      expect(find.text('2 × Team Jersey — Blue added'), findsOneWidget);
    });

    testWidgets(
        'camera cancellation is silent and two intentional sessions run',
        (tester) async {
      final exact = _WidgetBarcodeGateway();
      final results = <PosCameraScanResult>[
        const PosCameraScanResult.cancelled(),
        const PosCameraScanResult.barcode('2000000000114'),
        const PosCameraScanResult.barcode('2000000000114'),
      ];
      var launcherCalls = 0;
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        cameraSupported: true,
        cameraLauncher: (_) async => results[launcherCalls++],
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('new-sale-scanner-button'));

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(exact.calls, isEmpty);

      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(launcherCalls, 3);
      expect(exact.calls.map((call) => call.$2),
          ['2000000000114', '2000000000114']);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(PosNewSaleScreen)));
      expect(
        container.read(posNewSaleCartProvider).items.values.single.quantity,
        4,
      );
    });

    testWidgets(
        'Windows camera fallback does not launch plugin or exact lookup',
        (tester) async {
      final exact = _WidgetBarcodeGateway();
      var launcherCalls = 0;
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        cameraSupported: false,
        cameraLauncher: (_) async {
          launcherCalls++;
          return const PosCameraScanResult.failed();
        },
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new-sale-scanner-button')));
      await tester.pump();

      expect(launcherCalls, 0);
      expect(exact.calls, isEmpty);
      expect(find.textContaining('Camera scanning is unavailable'),
          findsOneWidget);
    });

    testWidgets('camera permission denial shows safe settings guidance',
        (tester) async {
      final exact = _WidgetBarcodeGateway();
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        cameraSupported: true,
        cameraLauncher: (_) async =>
            const PosCameraScanResult.permissionDenied(),
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('new-sale-scanner-button')));
      await tester.pump();

      expect(exact.calls, isEmpty);
      expect(
        find.text(
          'Camera access is disabled. Enable it in system settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'focused HID scan clears search, cancels catalog search and shows feedback once',
        (tester) async {
      final exact = _WidgetBarcodeGateway();
      final catalogSearches = <String>[];
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        catalogSearches: catalogSearches,
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      final search = find.byType(TextField);
      await tester.tap(search);
      await tester.enterText(search, '82111001003');
      for (final digit in '82111001003'.split('')) {
        await simulateKeyDownEvent(_widgetDigitKey(digit), character: digit);
        await simulateKeyUpEvent(_widgetDigitKey(digit));
      }
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      await simulateKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final container = ProviderScope.containerOf(tester.element(search));
      expect(tester.widget<TextField>(search).controller?.text, isEmpty);
      expect(container.read(posNewSaleSearchQueryProvider), isEmpty);
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();

      expect(exact.calls, [('device-1', '82111001003')]);
      expect(catalogSearches, isNot(contains('82111001003')));
      expect(find.text('2 × Team Jersey — Blue added'), findsOneWidget);
      expect(container.read(posNewSaleCartProvider).items, hasLength(1));

      container.read(posNewSaleSelectedCategoryIdProvider.notifier).state =
          'harmless-rebuild';
      await tester.pump();
      expect(find.text('2 × Team Jersey — Blue added'), findsOneWidget);

      await tester.enterText(search, 'jersey');
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller?.text, 'jersey');
      expect(container.read(posNewSaleSearchQueryProvider), 'jersey');
      expect(catalogSearches, contains('jersey'));
      expect(exact.calls, hasLength(1));
    });

    testWidgets('failed exact lookup stays clear and next scan succeeds',
        (tester) async {
      final exact = _WidgetBarcodeGateway(notFoundFirst: true);
      final catalogSearches = <String>[];
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        barcodeGateway: exact,
        catalogSearches: catalogSearches,
      );
      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();
      final search = find.byType(TextField);
      final container = ProviderScope.containerOf(tester.element(search));

      Future<void> scan(String barcode) async {
        await tester.tap(search);
        await tester.enterText(search, barcode);
        for (final digit in barcode.split('')) {
          await simulateKeyDownEvent(_widgetDigitKey(digit), character: digit);
          await simulateKeyUpEvent(_widgetDigitKey(digit));
        }
        await simulateKeyDownEvent(LogicalKeyboardKey.enter);
        await simulateKeyUpEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
      }

      await scan('82111001003');
      expect(tester.widget<TextField>(search).controller?.text, isEmpty);
      expect(container.read(posNewSaleSearchQueryProvider), isEmpty);
      expect(catalogSearches, isNot(contains('82111001003')));
      expect(find.text('Product not found for barcode 82111001003'),
          findsOneWidget);

      await scan('2000000000114');
      expect(
          exact.calls.map((call) => call.$2), ['82111001003', '2000000000114']);
      expect(tester.widget<TextField>(search).controller?.text, isEmpty);
      expect(find.text('2 × Team Jersey — Blue added'), findsOneWidget);
      expect(container.read(posBarcodeScanControllerProvider).feedbackEvent?.id,
          2);
    });

    testWidgets('New Sale reopens with empty search while preserving cart', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.searchProducts,
          PosPermissionCodes.addCartItem,
          PosPermissionCodes.updateCartItem,
          PosPermissionCodes.removeCartItem,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      await tester.tap(find.text('General Admission'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pumpAndSettle();

      expect(find.text('Coffee Voucher'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('General Admission'),
        ),
        findsNothing,
      );
      expect(find.text('Qty 1'), findsOneWidget);

      _goFromWidget<PosNewSaleScreen>(tester, '/pos/home');
      await tester.pumpAndSettle();
      _goFromWidget<PosHomeScreen>(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
          isEmpty);
      expect(find.text('Popular Products (13)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('General Admission'),
        ),
        findsOneWidget,
      );
      expect(find.text('Qty 1'), findsOneWidget);
    });

    testWidgets('New Sale category chips filter product grid', (tester) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.searchProducts,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('Snack Combo'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'More Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tickets'));
      await tester.pumpAndSettle();

      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('VIP Entry'), findsOneWidget);
      expect(find.text('Snack Combo'), findsNothing);
      expect(find.text('Popular Tickets Products'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'More Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All').last);
      await tester.pumpAndSettle();

      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('Snack Combo'), findsOneWidget);
      expect(find.text('Popular Products (13)'), findsOneWidget);
    });

    test('stockLabelFromApi maps API stock status to labels', () {
      expect(stockLabelFromApi('in_stock', null), 'In Stock');
      expect(stockLabelFromApi('out_of_stock', 0), 'Out of Stock');
      expect(stockLabelFromApi('low_stock', 3), '3 in stock');
      expect(stockLabelFromApi('in_stock', 12), '12 in stock');
    });

    test('New Sale cart promotes recently added product to the top', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const generalAdmission = PosNewSaleProduct(
        id: 'general-admission',
        productId: 'general-admission',
        name: 'General Admission',
        category: 'Tickets',
        price: 1500,
      );
      const vipEntry = PosNewSaleProduct(
        id: 'vip-entry',
        productId: 'vip-entry',
        name: 'VIP Entry',
        category: 'Tickets',
        price: 4500,
      );

      container.read(posNewSaleCartProvider.notifier)
        ..addToCart(generalAdmission)
        ..addToCart(vipEntry)
        ..addToCart(generalAdmission);

      final items = container.read(posNewSaleCartProvider).itemList;
      expect(items.first.product.name, 'General Admission');
      expect(items.first.quantity, 2);
      expect(items.last.product.name, 'VIP Entry');
      expect(container.read(posNewSaleCartProvider).subtotal, 7500);
    });

    test('sidebar permissions do not read POS home dashboard provider',
        () async {
      var dashboardReads = 0;
      final permissionCodes = [
        PosPermissionCodes.viewHome,
        PosPermissionCodes.viewNewSale,
      ];
      final session = AuthSession(
        accessToken: 'test-access-token',
        userId: 'test-user',
        userDisplayName: 'Cashier',
        permissionCodes: permissionCodes,
      );
      final container = ProviderContainer(
        overrides: [
          appDioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'https://test.local')),
          ),
          authSessionStorageProvider.overrideWithValue(
            _TestAuthSessionStorage(session),
          ),
          posHomeDashboardProvider.overrideWith((ref) async {
            dashboardReads++;
            return _referenceDashboardState(permissionCodes);
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.notifier).setSession(session);
      final grantedPermissions =
          container.read(posShellGrantedPermissionsProvider);

      expect(grantedPermissions, contains(PosPermissionCodes.viewHome));
      expect(grantedPermissions, contains(PosPermissionCodes.viewNewSale));
      expect(dashboardReads, 0);
    });

    test('POS home dashboard attaches auth header before API request',
        () async {
      String? authorizationHeader;
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            authorizationHeader = options.headers['Authorization']?.toString();
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: _posHomeApiResponse,
              ),
            );
          },
        ),
      );
      const session = AuthSession(
        accessToken: 'test-access-token',
        userId: 'test-user',
        userDisplayName: 'Cashier',
        permissionCodes: _defaultPermissions,
      );
      final container = ProviderContainer(
        overrides: [
          appDioProvider.overrideWithValue(dio),
          authSessionStorageProvider.overrideWithValue(
            _TestAuthSessionStorage(session),
          ),
          deviceContextStorageProvider.overrideWithValue(
            _TestDeviceContextStorage(_trustedDevice),
          ),
          tillSessionStorageProvider.overrideWithValue(
            _TestTillSessionStorage(_openTillSession),
          ),
          activateDeviceProvider.overrideWithValue(
            ActivateDevice(_FakeDeviceActivationRepository(_trustedDevice)),
          ),
          openTillProvider.overrideWithValue(
            OpenTill(_FakeTillRepository(_openTillSession)),
          ),
          deviceActivationProvider.overrideWith(
            (ref) => _PresetDeviceActivationController(
              ref.watch(activateDeviceProvider),
              ref.watch(deviceContextStorageProvider),
              _trustedDevice,
            ),
          ),
          tillProvider.overrideWith(
            (ref) => _PresetTillController(
              ref.watch(openTillProvider),
              ref.watch(tillSessionStorageProvider),
              _openTillSession,
            ),
          ),
          posSessionBootstrapProvider.overrideWith((ref) {
            final notifier = PosSessionBootstrapNotifier(
              ref,
              autoStart: false,
            );
            notifier.state = const PosSessionBootstrapState(isReady: true);
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.notifier).setSession(session);
      await container.read(posHomeDashboardProvider.future);

      expect(authorizationHeader, 'Bearer test-access-token');
    });

    testWidgets(
        'Start New Sale button is disabled when backend card is disabled',
        (tester) async {
      await _pumpPosHome(
        tester,
        size: const Size(1200, 900),
        dashboardState: _referenceDashboardState(
          const [
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewNewSale,
          ],
          startSaleEnabled: false,
        ),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
        ],
      );

      final action = tester.widget<PosHomeActionTile>(
        find.byWidgetPredicate(
          (widget) =>
              widget is PosHomeActionTile && widget.title == 'Start New Sale',
        ),
      );

      expect(action.enabled, isFalse);
      expect(action.onPressed, isNull);
    });

    testWidgets('phone width POS Home shows the shared mobile top bar', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(390, 844));

      expect(find.byType(PosMobileTopBar), findsOneWidget);
      expect(find.byType(PosDesktopTopBar), findsNothing);
      expect(find.byType(PosSidebar), findsNothing);
    });

    testWidgets('phone width New Sale shows the mobile top bar', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(390, 844),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.byType(PosMobileTopBar), findsOneWidget);
      expect(find.byType(PosDesktopTopBar), findsNothing);
      expect(find.byType(PosSidebar), findsNothing);
    });

    testWidgets(
        'tablet New Sale removes sidebar and keeps fixed bottom navigation', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: posTabletViewport,
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.viewNewSaleCustomers,
          PosPermissionCodes.createParkedSale,
          PosPermissionCodes.viewCashDrawer,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1280, 560);
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.byType(PosSidebar), findsNothing);
      expect(find.byType(PosCashierBottomNavigation), findsOneWidget);
      expect(find.text('New Sale'), findsWidgets);

      final productSize = tester.getSize(
        find.byKey(const Key('new-sale-products-panel')),
      );
      final cartSize = tester.getSize(
        find.byKey(const Key('new-sale-cart-panel')),
      );
      expect(productSize.width / cartSize.width, closeTo(1.5, 0.02));
    });

    testWidgets('New Sale scroll areas stay constrained on desktop sizes', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1280, 800),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.addCartItem,
          PosPermissionCodes.createNewSaleCustomer,
          PosPermissionCodes.checkoutSale,
          PosPermissionCodes.acceptCashPayment,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PosNewSaleScreen)),
      );
      for (final product in testPosCatalogState.products) {
        container.read(posNewSaleCartProvider.notifier).addToCart(
              toCartProduct(
                summary: product,
                variant: null,
                quantity: 1,
              ),
            );
      }
      await tester.pumpAndSettle();

      for (final size in [const Size(1280, 800), const Size(1366, 768)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();

        final productGrid = find.byType(GridView);
        final cartList = find.byType(ListView).last;
        final customItemButton = find.widgetWithText(
          FilledButton,
          'Custom Item',
        );
        final paymentButton = find.widgetWithText(
          FilledButton,
          'Proceed to Payment',
        );

        expect(productGrid, findsOneWidget);
        expect(paymentButton, findsOneWidget);
        expect(tester.getBottomLeft(productGrid).dy,
            lessThanOrEqualTo(tester.getTopLeft(customItemButton).dy));
        expect(
          tester.getBottomLeft(cartList).dy,
          lessThanOrEqualTo(tester.getTopLeft(paymentButton).dy),
        );

        await tester.drag(productGrid, const Offset(0, -220));
        await tester.drag(cartList, const Offset(0, -220));
        await tester.pumpAndSettle();

        expect(paymentButton, findsOneWidget);
      }
    });
  });
}

void _goFromCurrentRoute(WidgetTester tester, String route) {
  final context = tester.element(find.byType(PosHomeScreen));
  context.go(route);
}

void _goFromWidget<T extends Widget>(WidgetTester tester, String route) {
  final context = tester.element(find.byType(T));
  context.go(route);
}

Future<void> _pumpPosHome(
  WidgetTester tester, {
  required Size size,
  PosHomeDashboardState? dashboardState,
  List<String> permissionCodes = _defaultPermissions,
  Future<PosHomeDashboardState> Function(Ref ref)? dashboardOverride,
  bool settle = true,
  PosBarcodeLookupGateway? barcodeGateway,
  List<String>? catalogSearches,
  bool? cameraSupported,
  PosCameraScannerLauncher? cameraLauncher,
}) async {
  final dashboard = dashboardState ?? _referenceDashboardState(permissionCodes);
  final testDio = Dio(
    BaseOptions(
      baseUrl: 'https://test.local',
    ),
  );
  final testSession = AuthSession(
    accessToken: 'test-access-token',
    userId: 'test-user',
    userDisplayName: 'Cashier',
    permissionCodes: permissionCodes,
  );

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDioProvider.overrideWithValue(testDio),
        authSessionStorageProvider.overrideWithValue(
          _TestAuthSessionStorage(testSession),
        ),
        postLoginRouteProvider.overrideWithValue(PostLoginRoute.posHome),
        posSessionBootstrapProvider.overrideWith((ref) {
          final notifier = PosSessionBootstrapNotifier(ref, autoStart: false);
          notifier.state = const PosSessionBootstrapState(isReady: true);
          return notifier;
        }),
        deviceContextStorageProvider.overrideWithValue(
          _TestDeviceContextStorage(_trustedDevice),
        ),
        tillSessionStorageProvider.overrideWithValue(
          _TestTillSessionStorage(_openTillSession),
        ),
        activateDeviceProvider.overrideWithValue(
          ActivateDevice(_FakeDeviceActivationRepository(_trustedDevice)),
        ),
        openTillProvider.overrideWithValue(
          OpenTill(_FakeTillRepository(_openTillSession)),
        ),
        deviceActivationProvider.overrideWith(
          (ref) => _PresetDeviceActivationController(
            ref.watch(activateDeviceProvider),
            ref.watch(deviceContextStorageProvider),
            _trustedDevice,
          ),
        ),
        tillProvider.overrideWith(
          (ref) => _PresetTillController(
            ref.watch(openTillProvider),
            ref.watch(tillSessionStorageProvider),
            _openTillSession,
          ),
        ),
        posHomeDashboardProvider.overrideWith(
          dashboardOverride ?? (ref) async => dashboard,
        ),
        posNewSaleCategoriesProvider.overrideWith(
          (ref) async => testPosCatalogCategories,
        ),
        posNewSaleCatalogProvider.overrideWith((ref) async {
          final selectedCategoryId =
              ref.watch(posNewSaleSelectedCategoryIdProvider);
          ref.watch(posNewSaleSearchCancellationProvider);
          final query =
              ref.watch(posNewSaleSearchQueryProvider).trim().toLowerCase();
          if (query.isNotEmpty) {
            var disposed = false;
            ref.onDispose(() => disposed = true);
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (disposed) {
              return const PosNewSaleCatalogState(products: []);
            }
            catalogSearches?.add(query);
          }
          final catalog = testPosCatalogStateForCategory(selectedCategoryId);
          if (query.isEmpty) {
            return catalog;
          }

          return PosNewSaleCatalogState(
            products: catalog.products
                .where((product) => product.matches(query))
                .toList(growable: false),
          );
        }),
        if (barcodeGateway != null)
          posBarcodeLookupGatewayProvider.overrideWithValue(barcodeGateway),
        if (cameraSupported != null)
          posCameraScannerSupportedProvider.overrideWithValue(cameraSupported),
        if (cameraLauncher != null)
          posCameraScannerLauncherProvider.overrideWithValue(cameraLauncher),
        barcodeScannerConfigurationProvider.overrideWith((ref) async {
          return PosBarcodeScannerConfiguration(
            enabled: true,
            cameraEnabled: cameraSupported != null,
            mode: cameraSupported != null ? 'camera' : 'usbHid',
            minimumBarcodeLength: 4,
            maximumBarcodeLength: 128,
            scanTimeout: 120,
          );
        }),
      ],
      child: const NytrozPosApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }
}

const _defaultPermissions = [
  PosPermissionCodes.viewHome,
  PosPermissionCodes.viewNewSale,
  PosPermissionCodes.viewProducts,
  PosPermissionCodes.searchProducts,
  PosPermissionCodes.addCartItem,
  PosPermissionCodes.updateCartItem,
  PosPermissionCodes.removeCartItem,
  PosPermissionCodes.clearCart,
  PosPermissionCodes.viewNewSaleCustomers,
  PosPermissionCodes.createNewSaleCustomer,
  PosPermissionCodes.applySaleDiscount,
  PosPermissionCodes.createParkedSale,
  PosPermissionCodes.checkoutSale,
  PosPermissionCodes.acceptCashPayment,
  PosPermissionCodes.acceptCardPayment,
  PosPermissionCodes.acceptQrPayment,
  PosPermissionCodes.acceptSplitPayment,
  PosPermissionCodes.viewReturns,
  PosPermissionCodes.viewRefunds,
  PosPermissionCodes.createParkedSale,
  PosPermissionCodes.viewCashDrawer,
  PosPermissionCodes.createCashDrawerMovement,
  PosPermissionCodes.viewTillSession,
  PosPermissionCodes.viewNotifications,
];

const _permissionsWithOnlineOrders = [
  ..._defaultPermissions,
  PosPermissionCodes.viewOrders,
  PosPermissionCodes.manageOnlineOrders,
];

class _TestAuthSessionStorage extends AuthSessionStorage {
  _TestAuthSessionStorage(this.session)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final AuthSession session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _PresetDeviceActivationController extends DeviceActivationController {
  _PresetDeviceActivationController(
    super.activateDevice,
    super.storage,
    PosDeviceContext deviceContext,
  ) : super() {
    state = DeviceActivationState(deviceContext: deviceContext);
  }
}

class _PresetTillController extends TillController {
  _PresetTillController(
    super.openTill,
    super.storage,
    TillSession session,
  ) : super() {
    state = TillState(session: session);
  }
}

class _FakeDeviceActivationRepository implements DeviceActivationRepository {
  const _FakeDeviceActivationRepository(this.deviceContext);

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    return deviceContext;
  }

  @override
  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    return deviceContext;
  }
}

class _FakeTillRepository implements TillRepository {
  const _FakeTillRepository(this.session);

  final TillSession session;

  @override
  Future<TillSession> openTill(OpenTillForm form) async {
    return session;
  }

  @override
  Future<TillSession?> getCurrentSession(OpenTillForm form) async {
    return session;
  }

  @override
  Future<ClosedTillSession> closeTill(CloseTillForm form) async {
    throw UnimplementedError();
  }
}

class _WidgetBarcodeGateway implements PosBarcodeLookupGateway {
  _WidgetBarcodeGateway({this.notFoundFirst = false});

  final bool notFoundFirst;
  final List<(String, String)> calls = [];

  @override
  Future<PosBarcodeLookupResult> getProductByBarcode({
    required String deviceId,
    required String barcode,
  }) async {
    calls.add((deviceId, barcode));
    if (notFoundFirst && calls.length == 1) {
      final options = RequestOptions(path: '/barcode');
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: const {'code': 'pos_barcode.not_found'},
        ),
      );
    }
    return PosBarcodeLookupResult(
      productId: 'product-scanned',
      variantId: 'variant-scanned',
      barcode: barcode,
      barcodeType: 'EAN13',
      productName: 'Team Jersey',
      variantName: 'Blue',
      sku: 'TEAM-BLUE',
      quantityPerScan: 2,
      price: 2500,
      availableQuantity: 20,
      stockStatus: 'InStock',
    );
  }
}

LogicalKeyboardKey _widgetDigitKey(String digit) =>
    <String, LogicalKeyboardKey>{
      '0': LogicalKeyboardKey.digit0,
      '1': LogicalKeyboardKey.digit1,
      '2': LogicalKeyboardKey.digit2,
      '3': LogicalKeyboardKey.digit3,
      '4': LogicalKeyboardKey.digit4,
      '5': LogicalKeyboardKey.digit5,
      '6': LogicalKeyboardKey.digit6,
      '7': LogicalKeyboardKey.digit7,
      '8': LogicalKeyboardKey.digit8,
      '9': LogicalKeyboardKey.digit9,
    }[digit]!;

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this.deviceContext)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final PosDeviceContext deviceContext;

  @override
  Future<PosDeviceContext?> read() async => deviceContext;

  @override
  Future<String> readOrCreateDeviceFingerprint() async {
    return deviceContext.deviceFingerprint;
  }

  @override
  Future<List<String>> readDeviceFingerprintCandidates() async {
    return [deviceContext.deviceFingerprint];
  }

  @override
  Future<void> save(PosDeviceContext context) async {}

  @override
  Future<void> clear() async {}
}

class _TestTillSessionStorage extends TillSessionStorage {
  _TestTillSessionStorage(this.session)
      : super(const AppSecureStorage(FlutterSecureStorage()));

  final TillSession session;

  @override
  Future<TillSession?> read() async => session;

  @override
  Future<void> save(TillSession session) async {}

  @override
  Future<void> clear() async {}
}

final _pairedAt = DateTime.utc(2026, 6, 18, 9);

final _trustedDevice = PosDeviceContext(
  deviceId: 'device-1',
  deviceCode: 'DEV-001',
  deviceName: 'Front POS',
  deviceType: 'fixed_pos_tablet',
  platform: 'web',
  deviceFingerprint: 'test-device-fingerprint',
  isTrusted: true,
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  pairedAt: _pairedAt,
);

final _openTillSession = TillSession(
  sessionId: 'session-1',
  tenantId: 'tenant-1',
  outletId: 'outlet-1',
  outletName: 'Main Outlet',
  tillId: 'till-1',
  tillCode: 'TILL-001',
  tillName: 'Front Till',
  openedDeviceId: 'device-1',
  openingFloat: 150,
  status: 'open',
  openedAt: _pairedAt,
);

final _posHomeApiResponse = <String, dynamic>{
  'data': {
    'contextResolved': true,
    'cashier': {
      'id': 'test-user',
      'displayName': 'Cashier',
    },
    'user': {
      'fullName': 'Cashier',
    },
    'context': {
      'outletName': 'Main Outlet',
      'tillName': 'Front Till',
      'tillSessionId': 'session-1',
    },
    'till': {
      'name': 'Front Till',
      'areaName': 'Front',
      'number': 1,
      'status': 'Open',
      'sessionId': 'session-1',
    },
    'time': {
      'serverNowUtc': '2026-07-08T12:00:00Z',
      'outletTimezone': 'Asia/Colombo',
      'businessDate': '2026-07-08',
    },
    'notifications': {
      'unreadCount': 0,
    },
    'unreadNotificationCount': 0,
    'permissions': _defaultPermissions,
    'cards': {
      'startSale': {'enabled': true},
      'onlineOrders': {'enabled': true},
      'returnsRefunds': {'enabled': true, 'count': 0},
      'customers': {'enabled': true, 'count': 0},
      'parkedSales': {'enabled': true, 'count': 0},
      'cashDrawer': {'enabled': true, 'balance': 1000},
    },
  },
};

PosHomeDashboardState _referenceDashboardState(
  List<String> permissionCodes, {
  bool startSaleEnabled = true,
  bool includeOnlineOrders = false,
}) {
  final permissions = permissionCodes.toSet();

  return PosHomeDashboardState(
    fallbackUserDisplayName: 'Cashier',
    tillLabel: 'Front Till',
    tillStatusLabel: 'Open',
    isTillOpen: true,
    statusMessage: 'Ready for sales',
    startSaleButtonLabel: 'Start New Sale',
    isPosEnabled: true,
    isTrustedDevice: true,
    hasOpenTillSession: true,
    enabledFeatureKeys: const {
      PosFeatureCodes.sales,
      PosFeatureCodes.customers,
      PosFeatureCodes.returns,
      PosFeatureCodes.till,
    },
    grantedPermissionKeys: permissions,
    actions: [
      PosHomeAction(
        key: 'start-new-sale',
        label: 'Start New Sale',
        description: 'Begin a new in-store sale.',
        iconKey: 'new-sale',
        buttonLabel: 'Start New Sale',
        isEnabled: startSaleEnabled &&
            permissions.contains(PosPermissionCodes.viewNewSale),
        targetRoute: '/pos/new-sale',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.viewNewSale,
      ),
      if (includeOnlineOrders)
        PosHomeAction(
          key: 'manage-online-orders',
          label: 'Manage Online Orders',
          description: 'Review incoming online orders from one place.',
          iconKey: 'online-orders',
          buttonLabel: 'View Orders',
          isEnabled:
              permissions.contains(PosPermissionCodes.manageOnlineOrders),
          routeExists: false,
          onTapActionKey: 'manage-online-orders',
          featureKey: PosFeatureCodes.onlineOrders,
          permissionKey: PosPermissionCodes.manageOnlineOrders,
        ),
      PosHomeAction(
        key: 'returns-refunds',
        label: 'Returns & Refunds',
        description: 'Review eligible items for return or refund.',
        iconKey: 'return',
        buttonLabel: 'Start Return',
        isEnabled: permissions.contains(PosPermissionCodes.viewReturns),
        targetRoute: '/pos/returns-refunds',
        featureKey: PosFeatureCodes.returns,
        permissionKey: PosPermissionCodes.viewReturns,
        metricValue: '0',
        metricLabel: 'Pending today',
      ),
      PosHomeAction(
        key: 'add-customer',
        label: 'Add Customer',
        description: 'Create a customer profile for future visits.',
        iconKey: 'add-customer',
        buttonLabel: 'Add Customer',
        isEnabled:
            permissions.contains(PosPermissionCodes.viewNewSaleCustomers),
        targetRoute: '/pos/customers',
        featureKey: PosFeatureCodes.customers,
        permissionKey: PosPermissionCodes.viewNewSaleCustomers,
        metricValue: '0',
        metricLabel: 'Customer profiles',
      ),
      PosHomeAction(
        key: 'parked-sales',
        label: 'Parked Sales',
        description: 'View sales that were parked for later.',
        iconKey: 'parked-sales',
        buttonLabel: 'View Parked Sales',
        isEnabled: permissions.contains(PosPermissionCodes.createParkedSale),
        targetRoute: '/pos/parked-sales',
        featureKey: PosFeatureCodes.sales,
        permissionKey: PosPermissionCodes.createParkedSale,
        metricValue: '0',
        metricLabel: 'Waiting to resume',
      ),
      PosHomeAction(
        key: 'cash-drawer',
        label: 'Cash Drawer',
        description: 'View the current till cash summary.',
        iconKey: 'cash-drawer',
        buttonLabel: 'View Cash Drawer',
        isEnabled: permissions.contains(PosPermissionCodes.viewCashDrawer),
        targetRoute: '/pos/cash-drawer',
        featureKey: PosFeatureCodes.till,
        permissionKey: PosPermissionCodes.viewCashDrawer,
        metricValue: 'LKR 1000.00',
        metricLabel: 'Drawer balance',
      ),
    ],
  );
}
