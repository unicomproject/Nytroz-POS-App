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
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

void main() {
  testWidgets('Cash In tablet content is fixed, aligned, and overflow-free',
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
      openedTime: DateTime.utc(2026, 8, 15, 8),
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
          cashInCatalogProvider.overrideWith(
            (ref) => _ReadyCatalogController(),
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
                  padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CashInPageHeader(),
                      const SizedBox(height: TenantAdminSpacing.md),
                      CashInTillInfoBar(summary: summary),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: CashInFormCard(
                                key: const Key('details-card'),
                                formKey: formKey,
                                amountController: amountController,
                                noteController: noteController,
                                managerPinController: pinController,
                                currencyCode: summary.currencyCode,
                                expand: true,
                                compact: true,
                              ),
                            ),
                            const SizedBox(width: TenantAdminSpacing.md),
                            Expanded(
                              flex: 3,
                              child: CashInSummaryCard(
                                key: const Key('summary-card'),
                                currentExpectedCash:
                                    summary.currentExpectedCash,
                                currencyCode: summary.currencyCode,
                                expand: true,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
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
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.textContaining('USD'), findsWidgets);

    final detailsRect = tester.getRect(find.byKey(const Key('details-card')));
    final summaryRect = tester.getRect(find.byKey(const Key('summary-card')));
    expect(detailsRect.top, summaryRect.top);
    expect(detailsRect.bottom, summaryRect.bottom);

    final cancelRect =
        tester.getRect(find.widgetWithText(OutlinedButton, 'Cancel'));
    final confirmButton = find.ancestor(
      of: find.text('Confirm Cash In'),
      matching: find.byType(PosPrimaryActionButton),
    );
    final confirmRect = tester.getRect(confirmButton);
    expect(cancelRect.top, confirmRect.top);
    expect(cancelRect.bottom, confirmRect.bottom);
    expect(detailsRect.left, closeTo(cancelRect.left, 0.01));
    expect(summaryRect.right, closeTo(confirmRect.right, 0.01));
  });
}

class _ReadyCatalogController extends CashInCatalogController {
  _ReadyCatalogController() : super(_UnusedRepository()) {
    state = const CashInCatalogState(
      status: CashInCatalogStatus.ready,
      types: [
        CashMovementTypeOption(
          movementTypeId: 'type-float',
          code: 'FLOAT_ADDED',
          name: 'Float Added',
          direction: 'IN',
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
