import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_drawer_summary.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/entities/cash_movement_type.dart';
import 'package:nytroz_pos/features/cash_drawer/domain/repositories/cash_drawer_repository.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/cash_drop_provider.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drop_bottom_actions.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drop_form_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drop_page_header.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drop_summary_card.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/cash_drop_till_info_bar.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

void main() {
  testWidgets('Cash Drop tablet landscape is fixed, aligned, and overflow-free',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
      openedTime: DateTime.utc(2026, 8, 16, 8),
      openingCash: 10000,
      cashSales: 15000,
      cashRefunds: 0,
      cashDrops: 0,
      cashIns: 0,
      cashOuts: 0,
      currentExpectedCash: 25000,
      currencyCode: 'USD',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashDropCatalogProvider.overrideWith(
            (ref) => _ReadyDropCatalogController(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SizedBox(
                width: 1200,
                height: 620,
                child: CashDrawerSectionCard(
                  padding: const EdgeInsets.all(TenantAdminSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CashDropPageHeader(),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      CashDropTillInfoBar(summary: summary, compact: true),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: CashDropFormCard(
                                key: const Key('drop-details-card'),
                                formKey: formKey,
                                amountController: amountController,
                                noteController: noteController,
                                managerPinController: pinController,
                                availableCash: summary.currentExpectedCash,
                                currencyCode: summary.currencyCode,
                                expand: true,
                                compact: true,
                                tight: true,
                              ),
                            ),
                            const SizedBox(width: TenantAdminSpacing.md),
                            Expanded(
                              flex: 3,
                              child: CashDropSummaryCard(
                                key: const Key('drop-summary-card'),
                                currentExpectedCash:
                                    summary.currentExpectedCash,
                                currencyCode: summary.currencyCode,
                                expand: true,
                                compact: true,
                                tight: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      CashDropBottomActions(
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
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Cash Drop'), findsWidgets);
    expect(find.textContaining('not enabled'), findsOneWidget);

    final detailsRect =
        tester.getRect(find.byKey(const Key('drop-details-card')));
    final summaryRect =
        tester.getRect(find.byKey(const Key('drop-summary-card')));
    expect(detailsRect.top, summaryRect.top);
    expect(detailsRect.bottom, summaryRect.bottom);

    final cancelRect =
        tester.getRect(find.widgetWithText(OutlinedButton, 'Cancel'));
    final confirmButton = find.ancestor(
      of: find.text('Confirm Cash Drop'),
      matching: find.byType(PosPrimaryActionButton),
    );
    final confirmRect = tester.getRect(confirmButton);
    expect(cancelRect.top, confirmRect.top);
    expect(cancelRect.bottom, confirmRect.bottom);
  });

  testWidgets('Cash Drop phone-narrow has no overflow and reachable actions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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
      openedTime: DateTime.utc(2026, 8, 16, 8),
      openingCash: 10000,
      cashSales: 0,
      cashRefunds: 0,
      cashDrops: 0,
      cashIns: 0,
      cashOuts: 0,
      currentExpectedCash: 10000,
      currencyCode: 'LKR',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashDropCatalogProvider.overrideWith(
            (ref) => _ReadyDropCatalogController(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CashDrawerSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CashDropPageHeader(),
                      const SizedBox(height: 8),
                      CashDropTillInfoBar(summary: summary, compact: true),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ClipRect(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: tester.view.physicalSize.width - 24,
                              child: Column(
                                children: [
                                  CashDropSummaryCard(
                                    currentExpectedCash:
                                        summary.currentExpectedCash,
                                    currencyCode: summary.currencyCode,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 8),
                                  CashDropFormCard(
                                    formKey: formKey,
                                    amountController: amountController,
                                    noteController: noteController,
                                    managerPinController: pinController,
                                    availableCash: summary.currentExpectedCash,
                                    currencyCode: summary.currencyCode,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      CashDropBottomActions(
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
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm Cash Drop'), findsOneWidget);
  });
}

class _ReadyDropCatalogController extends CashDropCatalogController {
  _ReadyDropCatalogController() : super(_UnusedRepository()) {
    state = const CashDropCatalogState(
      status: CashDropCatalogStatus.ready,
      types: [
        CashMovementTypeOption(
          movementTypeId: 'type-drop',
          code: 'CASH_DROP',
          name: 'Safe Drop',
          direction: 'OUT',
          requiresReason: false,
          affectsExpectedCash: true,
        ),
      ],
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
