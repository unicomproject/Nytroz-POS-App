import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_desktop_top_bar.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_summary.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/navigation/returns_route_guard.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_search_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_continue_footer.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_recent_search_chips.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_sale_result_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_sale_summary_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_search_bar.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_search_filters_panel.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_search_pagination.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';

void main() {
  test('Step 1 route requires exact returns.view', () {
    expect(
      ReturnsRouteGuard.canAccessPath(
        _session([PosPermissionCodes.viewReturns]),
        '/pos/returns-refunds',
      ),
      isTrue,
    );
    expect(
      ReturnsRouteGuard.canAccessPath(
        _session([PosPermissionCodes.viewRefunds]),
        '/pos/returns-refunds',
      ),
      isFalse,
    );
    expect(
      ReturnsRouteGuard.canAccessPath(
        _session([PosPermissionCodes.viewExchanges]),
        '/pos/returns-refunds',
      ),
      isFalse,
    );
  });

  test('Step 2 route requires returns.view and returns.create', () {
    expect(
      ReturnsRouteGuard.canAccessPath(
        _session([PosPermissionCodes.viewReturns]),
        '/pos/returns-refunds/summary',
      ),
      isFalse,
    );
    expect(
      ReturnsRouteGuard.canAccessPath(
        _session([
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        ]),
        '/pos/returns-refunds/summary',
      ),
      isTrue,
    );
  });

  test('Continue requires view, create, selection, and idle search', () {
    expect(
      ReturnsRouteGuard.canContinueFromSearch(
        granted: {
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        },
        hasValidSelection: true,
        isLoading: false,
      ),
      isTrue,
    );
    expect(
      ReturnsRouteGuard.canContinueFromSearch(
        granted: {PosPermissionCodes.viewReturns},
        hasValidSelection: true,
        isLoading: false,
      ),
      isFalse,
    );
    expect(
      ReturnsRouteGuard.canContinueFromSearch(
        granted: {
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        },
        hasValidSelection: false,
        isLoading: false,
      ),
      isFalse,
    );
    expect(
      ReturnsRouteGuard.canContinueFromSearch(
        granted: {
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        },
        hasValidSelection: true,
        isLoading: true,
      ),
      isFalse,
    );
  });

  test('missing currency uses neutral display fallback', () {
    expect(
      formatReturnSaleAmount(
        const ReturnSaleSummary(
          saleId: 'sale-1',
          invoiceNo: 'RCP-1',
          customerName: 'A',
          phone: '',
          paymentMethod: 'Cash',
          maskedCard: '',
          total: 10,
          itemCount: 1,
          currency: '',
        ),
      ),
      '— 10.00',
    );
  });

  testWidgets('global shell search can be hidden while page search remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PosDesktopTopBar(
                  title: 'Returns & Exchanges',
                  subtitle: 'Find and select the original sale.',
                  showSearch: false,
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ReturnSearchBar(
                    query: '',
                    onQueryChanged: _noopString,
                    onSearch: _noop,
                    onToggleFilters: _noop,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Returns & Exchanges'), findsOneWidget);
    expect(
        find.text('Search products, scan barcode or enter SKU'), findsNothing);
    expect(
      find.text('Search by invoice no, mobile number, customer name'),
      findsOneWidget,
    );
  });

  testWidgets('result card shows supplied masked card and never invents one', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const ReturnSaleResultCard(
        sale: _cardSale,
        selected: true,
        onSelected: _noop,
      ),
      const Size(1440, 900),
    );

    expect(find.text('Visa **** 1234'), findsOneWidget);

    await _pumpAtSize(
      tester,
      const ReturnSaleResultCard(
        sale: _cashSale,
        selected: false,
        onSelected: _noop,
      ),
      const Size(390, 844),
    );

    expect(find.text('Cash'), findsOneWidget);
    expect(find.textContaining('****'), findsNothing);
  });

  testWidgets('result card supports desktop, tablet, and mobile widths', (
    tester,
  ) async {
    for (final size in const [
      Size(1280, 800),
      Size(900, 720),
      Size(390, 844),
    ]) {
      await _pumpAtSize(
        tester,
        const ReturnSaleResultCard(
          sale: _cardSale,
          selected: true,
          onSelected: _noop,
        ),
        size,
      );

      expect(find.text('RCP-0002456'), findsOneWidget);
      expect(find.text('Dilini Fernando'), findsOneWidget);
      expect(find.text('LKR 1245.30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('summary handles missing customer and missing card mask', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const ReturnSaleSummaryCard(sale: _cashSale),
      const Size(1024, 768),
    );

    expect(find.text('Walk-in customer'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.textContaining('****'), findsNothing);
  });

  testWidgets('summary card supports compact mobile presentation', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      const ReturnSaleSummaryCard(sale: _cardSale, compact: true),
      const Size(390, 844),
    );

    expect(find.text('Original Sale Summary'), findsOneWidget);
    expect(find.text('Invoice No.'), findsOneWidget);
    expect(find.text('RCP-0002456'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('footer disables and enables Continue from sale selection state',
      (
    tester,
  ) async {
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReturnContinueFooter(
            canContinue: false,
            onCancel: _noop,
            onContinue: () => continued++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    expect(continued, 0);
    expect(find.textContaining('valid original sale'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReturnContinueFooter(
            canContinue: true,
            onCancel: _noop,
            onContinue: () => continued++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('recent-search chips support remove and clear all',
      (tester) async {
    final removed = <String>[];
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReturnRecentSearchChips(
            items: const ['INV-001', 'Nimal Wijesinghe'],
            onSelected: _noopString,
            onRemoved: removed.add,
            onClearAll: () => cleared = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close).first);
    expect(removed, ['INV-001']);

    await tester.tap(find.text('Clear All'));
    expect(cleared, isTrue);
  });

  testWidgets('filters panel exposes apply and clear actions', (tester) async {
    var applied = false;
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReturnSearchFiltersPanel(
            filters: const ReturnSearchFilters(),
            paymentMethods: const [
              ReturnPaymentMethodFilterOption(code: 'CASH', label: 'Cash'),
              ReturnPaymentMethodFilterOption(code: 'CARD', label: 'Visa'),
            ],
            isLoading: false,
            onApply: (_) async => applied = true,
            onClear: () async => cleared = true,
          ),
        ),
      ),
    );

    expect(find.text('Date From'), findsOneWidget);
    expect(find.text('Date To'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Minimum Amount'), findsOneWidget);
    expect(find.text('Maximum Amount'), findsOneWidget);

    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(applied, isTrue);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(cleared, isTrue);
  });

  testWidgets('pagination requests next and previous pages', (tester) async {
    final pages = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReturnSearchPagination(
            page: 2,
            totalPages: 3,
            rangeStart: 21,
            rangeEnd: 40,
            totalCount: 55,
            isLoading: false,
            onPageChanged: pages.add,
          ),
        ),
      ),
    );

    expect(find.text('Showing 21–40 of 55 sales'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous page'));
    await tester.tap(find.byTooltip('Next page'));
    expect(pages, [1, 3]);
  });

  test('selecting a recent search infers a usable search mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(returnSearchProvider.notifier);
    notifier.applyRecentSearch('077 123 4567');
    expect(container.read(returnSearchProvider).tab, ReturnSearchTab.mobile);
    expect(container.read(returnSearchProvider).page, 1);

    notifier.applyRecentSearch('INV-0002456');
    expect(container.read(returnSearchProvider).tab, ReturnSearchTab.invoice);

    notifier.applyRecentSearch('John Perera');
    expect(container.read(returnSearchProvider).tab, ReturnSearchTab.customer);
  });

  test('selected-sale context is required for Step 2 deep links', () {
    expect(
      ReturnsRouteGuard.hasSelectedSaleContext(const ReturnFlowState()),
      isFalse,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(returnFlowProvider.notifier).selectSale(_cardSale);
    expect(
      ReturnsRouteGuard.hasSelectedSaleContext(
        container.read(returnFlowProvider),
      ),
      isTrue,
    );
  });

  test('canViewReturns is strict for Step 1 screen access helpers', () {
    expect(
      PosPermissionAccess.canViewReturns({PosPermissionCodes.viewReturns}),
      isTrue,
    );
    expect(
      PosPermissionAccess.canViewReturns({PosPermissionCodes.viewRefunds}),
      isFalse,
    );
    expect(
      PosPermissionAccess.canViewReturns({PosPermissionCodes.viewExchanges}),
      isFalse,
    );
  });
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void _noop() {}

void _noopString(String value) {}

AuthSession _session(List<String> permissions) {
  return AuthSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    userId: 'user',
    userDisplayName: 'Cashier',
    permissionCodes: [
      PosPermissionCodes.viewHome,
      ...permissions,
    ],
  );
}

const _cardSale = ReturnSaleSummary(
  saleId: 'sale-card',
  invoiceNo: 'RCP-0002456',
  customerName: 'Dilini Fernando',
  phone: '0771234567',
  paymentMethod: 'Visa',
  maskedCard: '**** 1234',
  saleDate: null,
  total: 1245.30,
  itemCount: 3,
  currency: 'LKR',
);

const _cashSale = ReturnSaleSummary(
  saleId: 'sale-cash',
  invoiceNo: 'RCP-0002457',
  customerName: '',
  phone: '',
  paymentMethod: 'Cash',
  maskedCard: '',
  saleDate: null,
  total: 900,
  itemCount: 1,
  currency: 'LKR',
);
