import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement_type.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/repositories/cash_drawer_repository.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_in_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_in_bottom_actions.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_in_form_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_in_page_header.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_in_summary_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_in_till_info_bar.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  final longReason = CashMovementTypeOption(
    movementTypeId: 'type-long',
    code: 'WEEKEND_FLOAT',
    name: 'Additional Weekend Evening Shift Change Float',
    direction: 'IN',
    requiresReason: true,
    affectsExpectedCash: true,
  );

  for (final size in <(String, Size)>[
    ('phone-narrow', const Size(390, 844)),
    ('tablet-1280x800', const Size(1280, 800)),
    ('desktop-1680x1050', const Size(1680, 1050)),
    ('hires-2560x1600', const Size(2560, 1600)),
  ]) {
    testWidgets('Cash In ${size.$1} has no overflow and reachable actions',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size.$2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpCashIn(tester, summaryCurrency: 'USD', types: [longReason]);
      expect(tester.takeException(), isNull);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Cash In'), findsOneWidget);
      expect(find.text('Cash In'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    });
  }

  testWidgets('Cash In supports increased text scale without exceptions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpCashIn(
      tester,
      summaryCurrency: 'USD',
      types: [longReason],
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Confirm Cash In'), findsOneWidget);
  });

  testWidgets('Cash In amount field is focusable for keyboard entry',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpCashIn(tester, summaryCurrency: 'USD', types: [longReason]);
    final amount = find.byType(TextFormField).first;
    await tester.ensureVisible(amount);
    await tester.tap(amount, warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cash In exposes semantics for primary actions/fields',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpCashIn(tester, summaryCurrency: 'USD', types: [longReason]);
    expect(find.bySemanticsLabel(RegExp('Cancel')), findsWidgets);
    expect(find.text('Confirm Cash In'), findsOneWidget);
    expect(find.text('Amount *'), findsOneWidget);
    expect(find.text('Reason *'), findsOneWidget);
    expect(find.text('Note (optional)'), findsOneWidget);
  });
}

Future<void> _pumpCashIn(
  WidgetTester tester, {
  required String summaryCurrency,
  required List<CashMovementTypeOption> types,
  double textScale = 1,
}) async {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final pinController = TextEditingController();
  addTearDown(amountController.dispose);
  addTearDown(noteController.dispose);
  addTearDown(pinController.dispose);

  final summary = CashDrawerSummary(
    tillSessionId: 'session-1',
    tillId: 'till-1',
    tillName: 'Front Till 01',
    status: 'OPEN',
    openedBy: 'Kavin',
    openedTime: DateTime.utc(2026, 8, 15, 8),
    openingCash: 125000.5,
    cashSales: 25000,
    cashRefunds: 0,
    cashDrops: 0,
    cashIns: 0,
    cashOuts: 0,
    currentExpectedCash: 150000.5,
    currencyCode: summaryCurrency,
  );

  final useSideBySide = tester.view.physicalSize.width >= 900;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cashInCatalogProvider.overrideWith(
          (ref) => _ReadyCatalogController(types),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: ColoredBox(
              color: TenantAdminColors.background,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CashDrawerSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CashInPageHeader(),
                      const SizedBox(height: 8),
                      CashInTillInfoBar(summary: summary, compact: true),
                      const SizedBox(height: 8),
                      Expanded(
                        child: useSideBySide
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: CashInFormCard(
                                      formKey: formKey,
                                      amountController: amountController,
                                      noteController: noteController,
                                      managerPinController: pinController,
                                      currencyCode: summary.currencyCode,
                                      expand: true,
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: CashInSummaryCard(
                                      currentExpectedCash:
                                          summary.currentExpectedCash,
                                      currencyCode: summary.currencyCode,
                                      expand: true,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRect(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: tester.view.physicalSize.width - 24,
                                    child: Column(
                                      children: [
                                        CashInSummaryCard(
                                          currentExpectedCash:
                                              summary.currentExpectedCash,
                                          currencyCode: summary.currencyCode,
                                          compact: true,
                                        ),
                                        const SizedBox(height: 8),
                                        CashInFormCard(
                                          formKey: formKey,
                                          amountController: amountController,
                                          noteController: noteController,
                                          managerPinController: pinController,
                                          currencyCode: summary.currencyCode,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      CashInBottomActions(
                        canConfirm: false,
                        isLoading: false,
                        onCancel: () {},
                        onConfirm: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _ReadyCatalogController extends CashInCatalogController {
  _ReadyCatalogController(List<CashMovementTypeOption> types)
      : super(_UnusedRepository()) {
    state = CashInCatalogState(
      status: CashInCatalogStatus.ready,
      types: types,
    );
  }
}

class _UnusedRepository implements CashDrawerRepository {
  @override
  Future<List<CashMovementTypeOption>> getCashInMovementTypes() async =>
      const [];

  @override
  Future<List<CashMovementTypeOption>> getCashDropMovementTypes() async =>
      const [];

  @override
  Future<CashMovement> createCashInMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashMovement> createCashDropMovement({
    required String requestId,
    required String deviceId,
    required String movementTypeId,
    required double amount,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CashMovement> createMovement({
    required String requestId,
    required String deviceId,
    required String tillSessionId,
    required CashMovementType type,
    required double amount,
    required String reason,
    String? referenceNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CashMovement>> getMovements(String deviceId,
      {int page = 1, int pageSize = 25}) {
    throw UnimplementedError();
  }

  @override
  Future<CashDrawerSummary> getSummary(String deviceId) {
    throw UnimplementedError();
  }
}
