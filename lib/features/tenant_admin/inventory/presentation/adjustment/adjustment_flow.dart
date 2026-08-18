import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_stepper_header.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../data/mock/inventory_frontend_mock.dart';
import '../navigation/inventory_routes.dart';
import '../widgets/inventory_shared_widgets.dart';

class AdjustmentSession {
  const AdjustmentSession({
    this.step = 0,
    this.productId,
    this.direction = 'DECREASE',
    this.reasonId,
    this.quantity = 0,
    this.notes = '',
    this.posted = false,
    this.adjustmentNumber,
    this.error,
  });

  final int step;
  final String? productId;
  final String direction;
  final String? reasonId;
  final double quantity;
  final String notes;
  final bool posted;
  final String? adjustmentNumber;
  final String? error;

  InventoryMockProduct? get product {
    if (productId == null) return null;
    for (final p in InventoryFrontendMock.products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  InventoryMockReason? get reason {
    if (reasonId == null || reasonId!.isEmpty) return null;
    for (final r in InventoryFrontendMock.adjustmentReasons) {
      if (r.id == reasonId) return r;
    }
    return null;
  }

  double get resultingOnHand {
    final onHand = product?.onHand ?? 0;
    return direction == 'INCREASE' ? onHand + quantity : onHand - quantity;
  }

  AdjustmentSession copyWith({
    int? step,
    String? productId,
    String? direction,
    String? reasonId,
    double? quantity,
    String? notes,
    bool? posted,
    String? adjustmentNumber,
    String? error,
    bool clearError = false,
  }) {
    return AdjustmentSession(
      step: step ?? this.step,
      productId: productId ?? this.productId,
      direction: direction ?? this.direction,
      reasonId: reasonId ?? this.reasonId,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      posted: posted ?? this.posted,
      adjustmentNumber: adjustmentNumber ?? this.adjustmentNumber,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdjustmentSessionNotifier extends StateNotifier<AdjustmentSession> {
  AdjustmentSessionNotifier() : super(const AdjustmentSession());

  void setStep(int step) =>
      state = state.copyWith(step: step, clearError: true);
  void back() {
    if (state.step > 0 && !state.posted) {
      state = state.copyWith(step: state.step - 1, clearError: true);
    }
  }

  void selectProduct(String id) =>
      state = state.copyWith(productId: id, clearError: true);

  void setEnter({
    required String direction,
    required String reasonId,
    required double quantity,
    String notes = '',
  }) {
    state = state.copyWith(
      direction: direction,
      reasonId: reasonId,
      quantity: quantity,
      notes: notes,
      clearError: true,
    );
  }

  bool validateSelect() {
    if (state.productId == null) {
      state = state.copyWith(error: 'Select a product.');
      return false;
    }
    return true;
  }

  bool validateEnter() {
    if (state.quantity <= 0) {
      state = state.copyWith(error: 'Quantity must be greater than 0.');
      return false;
    }
    if (state.reasonId == null || state.reasonId!.isEmpty) {
      state = state.copyWith(error: 'A catalog reason is required.');
      return false;
    }
    final floor = (state.product?.reserved ?? 0);
    if (state.direction == 'DECREASE' &&
        (state.product?.onHand ?? 0) - state.quantity < floor) {
      state = state.copyWith(
          error: 'Decrease cannot take available stock below reserved.');
      return false;
    }
    if (state.resultingOnHand < 0) {
      state = state.copyWith(error: 'Negative stock is not allowed.');
      return false;
    }
    return true;
  }

  void post() {
    if (state.posted) return;
    state = state.copyWith(
      posted: true,
      adjustmentNumber: 'ADJ-10012',
      step: 3,
      clearError: true,
    );
  }

  void reset() => state = const AdjustmentSession();
}

final adjustmentSessionProvider =
    StateNotifierProvider<AdjustmentSessionNotifier, AdjustmentSession>(
  (ref) => AdjustmentSessionNotifier(),
);

final adjustmentSearchProvider = StateProvider<String>((ref) => '');
final adjustmentPageProvider = StateProvider<int>((ref) => 1);

class AdjustmentDashboardScreen extends ConsumerWidget {
  const AdjustmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(adjustmentSearchProvider);
    final page = ref.watch(adjustmentPageProvider);
    const rows = [
      ('ADJ-10009', 'Home Jersey (Red, L)', 'POSTED', 'DECREASE'),
      ('ADJ-10008', 'OneVerz Mug', 'DRAFT', 'INCREASE'),
      ('ADJ-10007', 'OneVerz Water Bottle 750ml', 'POSTED', 'DECREASE'),
      ('ADJ-10006', 'OneVerz Display TV 55"', 'POSTED', 'INCREASE'),
      ('ADJ-10005', 'Home Jersey (Red, L)', 'POSTED', 'DECREASE'),
      ('ADJ-10004', 'OneVerz Mug', 'POSTED', 'INCREASE'),
    ];
    final filtered = rows
        .where((r) =>
            search.isEmpty ||
            r.$1.toLowerCase().contains(search.toLowerCase()) ||
            r.$2.toLowerCase().contains(search.toLowerCase()))
        .toList();
    const pageSize = TenantAdminPaginationDefaults.pageSize;
    final start = ((page - 1) * pageSize).clamp(0, filtered.length);
    final end = (start + pageSize).clamp(0, filtered.length);

    final canCreate = ref
            .watch(tenantAdminAccessCheckerProvider)
            .valueOrNull
            ?.canCreateStockAdjustment() ??
        true;

    return TenantAdminPageScaffold(
      title: 'Stock Adjustment',
      subtitle: 'View and manage stock adjustments across your outlets.',
      actions: [
        if (canCreate)
          TenantAdminPrimaryButton(
            label: 'New Stock Adjustment',
            onPressed: () {
              ref.read(adjustmentSessionProvider.notifier).reset();
              context.go(InventoryRoutes.adjustmentNew);
            },
          ),
      ],
      child: Column(
        children: [
          TenantAdminSearchField(
            value: search,
            hint: 'Search by reference, product, outlet or reason...',
            onChanged: (v) {
              ref.read(adjustmentSearchProvider.notifier).state = v;
              ref.read(adjustmentPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 14),
          InventoryMetricStrip(
            cards: const [
              TenantAdminMetricCard(
                title: 'Pending Approval',
                value: '0',
                subtitle: 'Needs review',
                icon: Icons.hourglass_top_outlined,
                status: TenantAdminStatusType.warning,
              ),
              TenantAdminMetricCard(
                title: 'Draft Adjustments',
                value: '1',
                subtitle: 'Not yet submitted',
                icon: Icons.edit_note_outlined,
                status: TenantAdminStatusType.pending,
              ),
              TenantAdminMetricCard(
                title: 'Posted Today',
                value: '2',
                subtitle: 'Across all outlets',
                icon: Icons.check_circle_outline,
                status: TenantAdminStatusType.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const TenantAdminEmptyState(
              title: 'No adjustments found',
              message: 'Create a new stock adjustment to get started.',
            )
          else
            TenantAdminDataTable(
              columns: const [
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Direction')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final row in filtered.sublist(start, end))
                  DataRow(
                    cells: [
                      DataCell(Text(row.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TenantAdminColors.info))),
                      DataCell(Text(row.$2,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DataCell(Text(row.$4 == 'DECREASE' ? '- qty' : '+ qty',
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TenantAdminStatusBadge(
                            label: row.$3,
                            status: row.$3 == 'POSTED'
                                ? TenantAdminStatusType.success
                                : TenantAdminStatusType.pending,
                          ),
                        ),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: () {},
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          TenantAdminPaginationBar(
            currentPage: page,
            pageSize: pageSize,
            totalCount: filtered.length,
            onPageChanged: (p) =>
                ref.read(adjustmentPageProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}

class AdjustmentWizardScreen extends ConsumerWidget {
  const AdjustmentWizardScreen({super.key});

  static const steps = [
    'Select Product',
    'Enter Adjustment',
    'Review',
    'Success'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adjustmentSessionProvider);
    final notifier = ref.read(adjustmentSessionProvider.notifier);
    return TenantAdminPageScaffold(
      title: 'New Stock Adjustment',
      scrollable: false,
      showBackButton: true,
      onBackButtonPressed: () {
        if (session.step == 0 || session.posted) {
          context.go(InventoryRoutes.adjustment);
        } else {
          notifier.back();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TenantAdminStepperHeader(steps: steps, currentStep: session.step),
          const SizedBox(height: 16),
          if (session.error != null)
            Text(session.error!,
                style: const TextStyle(color: Color(0xFFE42525))),
          Expanded(child: _body(context, session, notifier)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AdjustmentSession session,
    AdjustmentSessionNotifier notifier,
  ) {
    switch (session.step) {
      case 0:
        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (final p in InventoryFrontendMock.products)
                    InventoryProductPickRow(
                      name: p.name,
                      sku: p.sku,
                      selected: session.productId == p.id,
                      stockLabel:
                          'On Hand ${p.onHand.toStringAsFixed(0)} · Available ${p.available.toStringAsFixed(0)}',
                      onTap: () => notifier.selectProduct(p.id),
                    ),
                ],
              ),
            ),
            InventoryFooterBar(
              leading: const SizedBox.shrink(),
              trailing: InventoryPrimaryButton(
                label: 'Continue',
                onPressed: () {
                  if (notifier.validateSelect()) notifier.setStep(1);
                },
              ),
            ),
          ],
        );
      case 1:
        return _EnterStep(session: session, notifier: notifier);
      case 2:
        return Column(
          children: [
            InventorySectionCard(
              child: Column(
                children: [
                  _kv('Product', session.product?.name ?? ''),
                  _kv('Direction', session.direction),
                  _kv('Reason', session.reason?.name ?? ''),
                  _kv('Quantity', session.quantity.toStringAsFixed(0)),
                  _kv('On Hand',
                      (session.product?.onHand ?? 0).toStringAsFixed(0)),
                  _kv('Reserved',
                      (session.product?.reserved ?? 0).toStringAsFixed(0)),
                  _kv('Available',
                      (session.product?.available ?? 0).toStringAsFixed(0)),
                  _kv('Resulting On Hand',
                      session.resultingOnHand.toStringAsFixed(0)),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Review does not change physical stock.',
                        style: TextStyle(color: Color(0xFFA75100))),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                InventoryGhostButton(
                    label: 'Edit', onPressed: () => notifier.setStep(1)),
                const Spacer(),
                InventoryPrimaryButton(
                    label: 'Post Adjustment', onPressed: notifier.post),
              ],
            ),
          ],
        );
      default:
        return InventorySuccessState(
          title: 'Stock Adjustment Posted',
          message: 'Physical on-hand was updated at the selected location.',
          details: {
            'Adjustment': session.adjustmentNumber ?? '',
            'Direction': session.direction,
            'Quantity': session.quantity.toStringAsFixed(0),
            'Resulting On Hand': session.resultingOnHand.toStringAsFixed(0),
          },
          actions: [
            InventoryGhostButton(
              label: 'View Stock',
              onPressed: () => context.go(InventoryRoutes.currentStock),
            ),
            InventoryPrimaryButton(
              label: 'Back to Adjustments',
              onPressed: () {
                notifier.reset();
                context.go(InventoryRoutes.adjustment);
              },
            ),
          ],
        );
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(k, style: const TextStyle(color: Color(0xFF64748B)))),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _EnterStep extends StatefulWidget {
  const _EnterStep({required this.session, required this.notifier});
  final AdjustmentSession session;
  final AdjustmentSessionNotifier notifier;

  @override
  State<_EnterStep> createState() => _EnterStepState();
}

class _EnterStepState extends State<_EnterStep> {
  late String _direction = widget.session.direction;
  late String? _reasonId = widget.session.reasonId;
  late final _qty = TextEditingController(
      text: widget.session.quantity == 0
          ? ''
          : widget.session.quantity.toStringAsFixed(0));
  late final _notes = TextEditingController(text: widget.session.notes);

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reasons = InventoryFrontendMock.adjustmentReasons
        .where((r) => r.direction == _direction)
        .toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                  'On Hand ${(widget.session.product?.onHand ?? 0).toStringAsFixed(0)} · Reserved ${(widget.session.product?.reserved ?? 0).toStringAsFixed(0)} · Available ${(widget.session.product?.available ?? 0).toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'INCREASE', label: Text('INCREASE')),
                  ButtonSegment(value: 'DECREASE', label: Text('DECREASE')),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() {
                  _direction = s.first;
                  _reasonId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _reasonId,
                decoration: inventoryInputDecoration(label: 'Reason'),
                items: [
                  for (final r in reasons)
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _reasonId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: inventoryInputDecoration(label: 'Quantity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration: inventoryInputDecoration(label: 'Notes (optional)'),
              ),
            ],
          ),
        ),
        Row(
          children: [
            InventoryGhostButton(
                label: 'Back', onPressed: widget.notifier.back),
            const Spacer(),
            InventoryPrimaryButton(
              label: 'Continue to Review',
              onPressed: () {
                widget.notifier.setEnter(
                  direction: _direction,
                  reasonId: _reasonId ?? '',
                  quantity: double.tryParse(_qty.text) ?? 0,
                  notes: _notes.text,
                );
                if (widget.notifier.validateEnter()) {
                  widget.notifier.setStep(2);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
