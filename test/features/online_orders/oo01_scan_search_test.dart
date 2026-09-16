import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_online_orders_screen.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';

final _outlet = StateProvider<String>((ref) => 'outlet-1');

class _Repo implements PosOnlineOrdersRepository {
  final queries = <PosOnlineOrdersQuery>[];
  final pending = <Completer<PosOnlineOrderPage>>[];
  bool delayed = false;
  @override
  Future<PosOnlineOrderPage> list(PosOnlineOrdersQuery query,
      {CancelToken? cancelToken}) {
    queries.add(query);
    if (delayed) {
      final result = Completer<PosOnlineOrderPage>();
      pending.add(result);
      return result.future; // Deliberately ignores cancellation to prove guard.
    }
    return Future.value(page(query.search));
  }

  static PosOnlineOrderPage page(String value) => PosOnlineOrderPage.fromJson({
        'items': value == 'UNKNOWN'
            ? []
            : [
                {'id': 'one', 'orderNumber': value.isEmpty ? 'ORD-1' : value}
              ],
        'totalPages': 3,
      });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> mount(
    WidgetTester tester, PosOnlineOrdersRepository repo,
    {Size size = const Size(1280, 800), Color seed = Colors.orange}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(overrides: [
    posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
    posOnlineOrdersOutletIdProvider.overrideWith((ref) => ref.watch(_outlet)),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          theme: ThemeData(colorSchemeSeed: seed),
          home: const Scaffold(body: PosOnlineOrdersScreen()))));
  await tester.pump();
  return container;
}

Future<void> hid(WidgetTester tester) async {
  for (final key in [
    LogicalKeyboardKey.keyO,
    LogicalKeyboardKey.keyR,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.digit1
  ]) {
    await tester.sendKeyEvent(key, character: key.keyLabel);
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
}

void main() {
  testWidgets('focused wedge completion selects text for replacement',
      (tester) async {
    final repo = _Repo();
    final container = await mount(tester, repo);
    await tester.tap(find.byTooltip('Scan order'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ORD-000001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 401));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 10));
    expect(container.read(posOnlineOrdersProvider).query, 'ORD-000001');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('incomplete HID frame is silent and lifecycle detaches capture',
      (tester) async {
    final repo = _Repo();
    final container = await mount(tester, repo);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'A');
    await tester.pump(const Duration(milliseconds: 121));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(container.read(posOnlineOrdersProvider).query, '');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await hid(tester);
    expect(container.read(posOnlineOrdersProvider).query, '');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await hid(tester);
    expect(container.read(posOnlineOrdersProvider).query, 'ORD1');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(1280, 800),
    const Size(1180, 820),
    const Size(1100, 700)
  ]) {
    for (final seed in [Colors.orange, Colors.pink]) {
      testWidgets('scan affordance, theme and layout $size $seed',
          (tester) async {
        await mount(tester, _Repo(), size: size, seed: seed);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.text('Search by order number, customer, phone or scan...'),
            findsOneWidget);
        expect(find.byTooltip('Scan order'), findsOneWidget);
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(tester.getCenter(find.byIcon(Icons.qr_code_scanner)).dx,
            greaterThan(tester.getCenter(find.byIcon(Icons.search)).dx));
        final semantics = tester.ensureSemantics();
        await tester.pump();
        expect(find.bySemanticsLabel('Scan order'), findsOneWidget);
        semantics.dispose();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
      'HID without tap populates query; duplicates, empty, unknown and clear',
      (tester) async {
    final repo = _Repo();
    final container = await mount(tester, repo);
    await hid(tester);
    expect(container.read(posOnlineOrdersProvider).query, 'ORD1');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ORD1');
    expect(repo.queries.length, 1);
    await tester.pump(const Duration(milliseconds: 401));
    expect(repo.queries.last.search, 'ORD1');
    await hid(tester);
    await tester.pump(const Duration(milliseconds: 401));
    expect(container.read(posOnlineOrdersProvider).items.length, 1);
    final listener = tester.widget<PosBarcodeScannerListener>(
        find.byType(PosBarcodeScannerListener));
    listener.onBarcodeScanned('  ');
    expect(container.read(posOnlineOrdersProvider).query, 'ORD1');
    listener.onBarcodeScanned('UNKNOWN');
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pump();
    expect(find.text('No orders match your search.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 401));
    expect(repo.queries.last.search, '');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('icon focuses existing input; typing retains 400ms debounce',
      (tester) async {
    final repo = _Repo();
    await mount(tester, repo);
    await tester.tap(find.byTooltip('Scan order'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
    await tester.enterText(find.byType(TextField), 'Customer 1');
    await tester.pump(const Duration(milliseconds: 399));
    expect(repo.queries.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.queries.last.search, 'Customer 1');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('stale response cannot win during debounce or outlet change',
      (tester) async {
    final repo = _Repo();
    final container = await mount(tester, repo);
    final notifier = container.read(posOnlineOrdersProvider.notifier);
    repo.delayed = true;
    final old = notifier.load();
    notifier.setQuery('NEW');
    repo.pending[0].complete(_Repo.page('OLD'));
    await old;
    expect(container.read(posOnlineOrdersProvider).items.single.orderNumber,
        'ORD-1');
    await tester.pump(const Duration(milliseconds: 401));
    container.read(_outlet.notifier).state = 'outlet-2';
    await tester.pump();
    repo.pending[1].complete(_Repo.page('WRONG-OUTLET'));
    await tester.pump();
    expect(container.read(posOnlineOrdersProvider).items, isEmpty);
    expect(repo.queries.last.outletId, 'outlet-2');
    repo.pending.last.complete(_Repo.page('NEW'));
    await tester.pump();
    expect(container.read(posOnlineOrdersProvider).items.single.orderNumber,
        'NEW');
    await tester.pumpWidget(const SizedBox());
  });
}
