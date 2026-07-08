import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/app/app.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
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
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_shell_nav_item.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/sidebar/pos_sidebar.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/screens/pos_new_sale_screen.dart';
import 'package:nytroz_pos/features/till/application/usecases/open_till.dart';
import 'package:nytroz_pos/features/till/data/datasources/till_session_storage.dart';
import 'package:nytroz_pos/features/till/domain/entities/open_till.dart';
import 'package:nytroz_pos/features/till/domain/repositories/till_repository.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

import 'support/pos_catalog_test_fixtures.dart';

void main() {
  group('POS Home', () {
    testWidgets('/pos/home renders the dashboard and Start Sale hero', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Hello, Cashier 👋'), findsOneWidget);
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Start New Sale'), findsOneWidget);
    });

    testWidgets('renders the complete reference dashboard cards', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.text('Manage Online Orders'), findsNothing);
      expect(find.text('Returns & Refunds'), findsOneWidget);
      expect(find.text('Add Customer'), findsWidgets);
      expect(find.text('Parked Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
      expect(find.text('Orders'), findsNothing);
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
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Returns & Refunds'), findsOneWidget);
      expect(find.text('Add Customer'), findsWidgets);
      expect(find.text('Parked Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
    });

    testWidgets('tablet width shows the sidebar', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      expect(find.byType(PosSidebar), findsOneWidget);
      expect(find.byType(PosDesktopTopBar), findsNothing);
      expect(find.byType(PosMobileTopBar), findsNothing);
      final homeItem = tester.widget<PosShellNavItem>(
        find.widgetWithText(PosShellNavItem, 'Home'),
      );
      expect(homeItem.selected, isTrue);
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
      expect(find.text('Hello, Cashier 👋'), findsOneWidget);
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Dashboard metrics are loading.'), findsOneWidget);

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
      expect(find.text('Hello, Cashier 👋'), findsOneWidget);
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Dashboard failed'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
    });

    testWidgets('Home remains on /pos/home when tapped', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      await tester.tap(_sidebarDestination('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('sidebar hides destinations without permission', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [PosPermissionCodes.viewHome],
      );

      expect(_sidebarDestination('Home'), findsOneWidget);
      expect(_sidebarDestination('New Sale'), findsNothing);
      expect(_sidebarDestination('Orders'), findsNothing);
      expect(_sidebarDestination('Customers'), findsNothing);
      expect(_sidebarDestination('Return & Refund'), findsNothing);
      expect(_sidebarDestination('Cash Drawer'), findsNothing);
    });

    testWidgets(
        'sidebar renders destinations from backend New Sale permissions', (
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
        ],
      );

      expect(_sidebarDestination('Home'), findsOneWidget);
      expect(_sidebarDestination('New Sale'), findsOneWidget);
      expect(_sidebarDestination('Orders'), findsOneWidget);
      expect(_sidebarDestination('Customers'), findsOneWidget);
      expect(_sidebarDestination('Return & Refund'), findsOneWidget);
      expect(_sidebarDestination('Cash Drawer'), findsOneWidget);
    });

    testWidgets('New Sale sidebar destination opens placeholder screen', (
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

      await tester.tap(_sidebarDestination('New Sale'));
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.text('All Products (12)'), findsOneWidget);
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

    testWidgets('user with start sale permission can open New Sale shell', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.byType(PosDesktopTopBar), findsOneWidget);
      expect(find.text('New Sale'), findsWidgets);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('product taps add to cart and update New Sale totals', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
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

      await tester.tap(find.text('General Admission'));
      await tester.pumpAndSettle();

      expect(find.text('No items added'), findsNothing);
      expect(find.text('Qty 1'), findsOneWidget);
      // Product grid no longer renders price on tiles; cart shows unit price,
      // line total, subtotal, and total.
      expect(find.text('LKR 1,500.00'), findsNWidgets(4));
      expect(tester.widget<FilledButton>(paymentButton).onPressed, isNotNull);

      await tester.tap(find.text('General Admission').first);
      await tester.pumpAndSettle();

      expect(find.text('Qty 2'), findsOneWidget);
      expect(find.text('LKR 3,000.00'), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Qty 1'), findsOneWidget);
      expect(find.text('LKR 1,500.00'), findsNWidgets(4));

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No items added'), findsOneWidget);
      expect(tester.widget<FilledButton>(paymentButton).onPressed, isNull);
    });

    testWidgets('New Sale shared search filters product grid while typing', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
        permissionCodes: const [
          PosPermissionCodes.viewHome,
          PosPermissionCodes.viewNewSale,
          PosPermissionCodes.viewProducts,
          PosPermissionCodes.searchProducts,
        ],
      );

      _goFromCurrentRoute(tester, '/pos/new-sale');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pumpAndSettle();

      expect(find.text('Coffee Voucher'), findsOneWidget);
      expect(find.text('General Admission'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('All Products (12)'), findsOneWidget);
      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('Snack Combo'), findsOneWidget);
    });

    testWidgets('New Sale reopens with empty search while preserving cart', (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
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
      expect(find.text('All Products (12)'), findsOneWidget);
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
        size: const Size(1024, 768),
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

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tickets'));
      await tester.pumpAndSettle();

      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('VIP Entry'), findsOneWidget);
      expect(find.text('Snack Combo'), findsNothing);
      expect(find.text('Tickets Products'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('General Admission'), findsOneWidget);
      expect(find.text('Snack Combo'), findsOneWidget);
      expect(find.text('All Products (12)'), findsOneWidget);
    });

    test('posNewSaleProductMatchesCategory maps chip labels to products', () {
      expect(posNewSaleProductMatchesCategory('Tickets', 'Tickets'), isTrue);
      expect(posNewSaleProductMatchesCategory('Food', 'Tickets'), isFalse);
      expect(posNewSaleProductMatchesCategory('Memberships', 'All'), isTrue);
      expect(posNewSaleProductMatchesCategory('Services', 'Services'), isTrue);
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

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start New Sale'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('phone width POS Home does not show the shared top bar', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(390, 844));

      expect(find.byType(PosMobileTopBar), findsNothing);
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

    testWidgets('short desktop New Sale keeps sidebar destinations scrollable',
        (
      tester,
    ) async {
      await _pumpPosHome(
        tester,
        size: const Size(1024, 768),
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
      tester.view.physicalSize = const Size(1024, 560);
      await tester.pumpAndSettle();

      expect(find.byType(PosNewSaleScreen), findsOneWidget);
      expect(find.byType(PosSidebar), findsOneWidget);
      expect(_sidebarDestination('New Sale'), findsOneWidget);
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
        final addCustomerButton = find.widgetWithText(
          OutlinedButton,
          'Add Customer',
        );
        final paymentButton = find.widgetWithText(
          FilledButton,
          'Proceed to Payment',
        );

        expect(productGrid, findsOneWidget);
        expect(paymentButton, findsOneWidget);
        expect(tester.getBottomLeft(productGrid).dy,
            lessThanOrEqualTo(tester.getTopLeft(addCustomerButton).dy));
        expect(
          tester.getBottomLeft(cartList).dy,
          lessThanOrEqualTo(tester.getTopLeft(paymentButton).dy),
        );

        await tester.drag(productGrid, const Offset(0, -220));
        await tester.drag(cartList, const Offset(0, -220));
        await tester.pumpAndSettle();

        expect(paymentButton, findsOneWidget);
        expect(addCustomerButton, findsOneWidget);
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

Finder _sidebarDestination(String label) {
  return find.widgetWithText(PosShellNavItem, label);
}

Future<void> _pumpPosHome(
  WidgetTester tester, {
  required Size size,
  PosHomeDashboardState? dashboardState,
  List<String> permissionCodes = _defaultPermissions,
  Future<PosHomeDashboardState> Function(Ref ref)? dashboardOverride,
  bool settle = true,
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
        posHomeDashboardProvider.overrideWith(
          dashboardOverride ?? (ref) async => dashboard,
        ),
        posNewSaleCatalogProvider.overrideWith(
          (ref) async => testPosCatalogState,
        ),
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
  _TestAuthSessionStorage(this.session) : super(const FlutterSecureStorage());

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
}

class _TestDeviceContextStorage extends DeviceContextStorage {
  _TestDeviceContextStorage(this.deviceContext)
      : super(const FlutterSecureStorage());

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
  _TestTillSessionStorage(this.session) : super(const FlutterSecureStorage());

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
