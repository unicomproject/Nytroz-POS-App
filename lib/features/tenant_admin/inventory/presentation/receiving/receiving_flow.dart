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

class ReceivingSession {
  const ReceivingSession({
    this.step = 0,
    this.locationId,
    this.productId,
    this.quantity = 0,
    this.unitCost = 0,
    this.supplierName = '',
    this.invoiceNumber = '',
    this.po = '',
    this.notes = '',
    this.serials = const [],
    this.posted = false,
    this.receiptNumber,
    this.error,
  });

  final int step;
  final String? locationId;
  final String? productId;
  final double quantity;
  final double unitCost;
  final String supplierName;
  final String invoiceNumber;
  final String po;
  final String notes;
  final List<String> serials;
  final bool posted;
  final String? receiptNumber;
  final String? error;

  InventoryMockProduct? get product {
    if (productId == null) return null;
    return InventoryFrontendMock.products
        .where((p) => p.id == productId)
        .firstOrElse();
  }

  String get locationName => InventoryFrontendMock.locations
      .firstWhere(
        (l) => l.id == locationId,
        orElse: () => const InventoryMockLocation(id: '', name: ''),
      )
      .name;

  ReceivingSession copyWith({
    int? step,
    String? locationId,
    String? productId,
    double? quantity,
    double? unitCost,
    String? supplierName,
    String? invoiceNumber,
    String? po,
    String? notes,
    List<String>? serials,
    bool? posted,
    String? receiptNumber,
    String? error,
    bool clearError = false,
  }) {
    return ReceivingSession(
      step: step ?? this.step,
      locationId: locationId ?? this.locationId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      po: po ?? this.po,
      notes: notes ?? this.notes,
      serials: serials ?? this.serials,
      posted: posted ?? this.posted,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

extension _FirstWhereOrElse<T> on Iterable<T> {
  T? firstOrElse() => isEmpty ? null : first;
}

class ReceivingSessionNotifier extends StateNotifier<ReceivingSession> {
  ReceivingSessionNotifier() : super(const ReceivingSession());

  void setStep(int step) =>
      state = state.copyWith(step: step, clearError: true);

  void back() {
    if (state.step > 0 && !state.posted) {
      state = state.copyWith(step: state.step - 1, clearError: true);
    }
  }

  void selectLocation(String id) =>
      state = state.copyWith(locationId: id, clearError: true);

  void selectProduct(String id) =>
      state = state.copyWith(productId: id, clearError: true);

  void setDetails({
    required double quantity,
    required double unitCost,
    required String supplierName,
    required String invoiceNumber,
    String po = '',
    String notes = '',
    List<String> serials = const [],
  }) {
    state = state.copyWith(
      quantity: quantity,
      unitCost: unitCost,
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      po: po,
      notes: notes,
      serials: serials,
      clearError: true,
    );
  }

  bool validateSelect() {
    if (state.locationId == null || state.productId == null) {
      state = state.copyWith(error: 'Select a location and product.');
      return false;
    }
    return true;
  }

  bool validateDetails() {
    if (state.quantity <= 0) {
      state = state.copyWith(error: 'Quantity must be greater than 0.');
      return false;
    }
    if (state.supplierName.trim().isEmpty ||
        state.invoiceNumber.trim().isEmpty) {
      state = state.copyWith(
          error: 'Supplier name and invoice number are required.');
      return false;
    }
    final product = state.product;
    if (product?.serialTracked == true &&
        state.serials.length != state.quantity.round()) {
      state =
          state.copyWith(error: 'Serial count must equal received quantity.');
      return false;
    }
    final unique = state.serials.map((e) => e.trim().toLowerCase()).toSet();
    if (unique.length != state.serials.length) {
      state =
          state.copyWith(error: 'Duplicate serial numbers are not allowed.');
      return false;
    }
    return true;
  }

  void confirm() {
    if (state.posted) return;
    state = state.copyWith(
      posted: true,
      receiptNumber: 'RCV-10021',
      step: 4,
      clearError: true,
    );
  }

  void reset() => state = const ReceivingSession();
}

final receivingSessionProvider =
    StateNotifierProvider<ReceivingSessionNotifier, ReceivingSession>(
  (ref) => ReceivingSessionNotifier(),
);

final receivingSearchProvider = StateProvider<String>((ref) => '');
final receivingPageProvider = StateProvider<int>((ref) => 1);

class ReceivingDashboardScreen extends ConsumerWidget {
  const ReceivingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(receivingSearchProvider);
    final page = ref.watch(receivingPageProvider);
    const receipts = [
      ('RCV-10018', 'OneVerz Water Bottle 750ml', 'POSTED', 'Warehouse'),
      ('RCV-10017', 'Home Jersey (Red, L)', 'DRAFT', 'Main Outlet'),
      ('RCV-10016', 'OneVerz Display TV 55"', 'POSTED', 'Warehouse'),
      ('RCV-10015', 'OneVerz Mug', 'POSTED', 'Outlet 02'),
      ('RCV-10014', 'Home Jersey (Red, L)', 'POSTED', 'Main Outlet'),
      ('RCV-10013', 'OneVerz Water Bottle 750ml', 'DRAFT', 'Outlet 03'),
    ];
    final filtered = receipts
        .where((r) =>
            search.isEmpty ||
            r.$1.toLowerCase().contains(search.toLowerCase()) ||
            r.$2.toLowerCase().contains(search.toLowerCase()))
        .toList();
    const pageSize = TenantAdminPaginationDefaults.pageSize;
    final start = ((page - 1) * pageSize).clamp(0, filtered.length);
    final end = (start + pageSize).clamp(0, filtered.length);

    final canManage = ref
            .watch(tenantAdminAccessCheckerProvider)
            .valueOrNull
            ?.canManageReceiving() ??
        true;

    return TenantAdminPageScaffold(
      title: 'Stock Receiving',
      subtitle: 'Receive and track incoming stock from suppliers.',
      actions: [
        if (canManage)
          TenantAdminPrimaryButton(
            label: 'New Stock Receipt',
            onPressed: () {
              ref.read(receivingSessionProvider.notifier).reset();
              context.go(InventoryRoutes.receivingNew);
            },
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryMetricStrip(
            cards: const [
              TenantAdminMetricCard(
                title: "Today's Receipts",
                value: '8',
                subtitle: '24 units',
                icon: Icons.receipt_long_outlined,
                status: TenantAdminStatusType.online,
              ),
              TenantAdminMetricCard(
                title: 'Pending Review',
                value: '3',
                subtitle: '1,250 units',
                icon: Icons.hourglass_top_outlined,
                status: TenantAdminStatusType.warning,
              ),
              TenantAdminMetricCard(
                title: 'Received Qty',
                value: '5,842',
                subtitle: 'This month',
                icon: Icons.inventory_2_outlined,
                status: TenantAdminStatusType.success,
              ),
              TenantAdminMetricCard(
                title: 'Recent Suppliers',
                value: '12',
                subtitle: 'Active suppliers',
                icon: Icons.local_shipping_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TenantAdminSearchField(
            value: search,
            hint: 'Search by receipt, product or outlet',
            onChanged: (v) {
              ref.read(receivingSearchProvider.notifier).state = v;
              ref.read(receivingPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const TenantAdminEmptyState(
              title: 'No receipts found',
              message: 'Try another search or create a new stock receipt.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final table = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Recent Receipts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TenantAdminDataTable(
                      columns: const [
                        DataColumn(label: Text('Receipt No.')),
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Outlet')),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(row.$4)),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TenantAdminStatusBadge(
                                    label: row.$3 == 'POSTED'
                                        ? 'Received'
                                        : 'Draft',
                                    status: row.$3 == 'POSTED'
                                        ? TenantAdminStatusType.success
                                        : TenantAdminStatusType.pending,
                                  ),
                                ),
                              ),
                              DataCell(
                                TextButton(
                                  onPressed: () =>
                                      context.go(InventoryRoutes.receivingNew),
                                  child: const Text('View'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
                if (constraints.maxWidth < 980) {
                  return table;
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: table),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 260,
                      child: Column(
                        children: [
                          InventorySectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quick Actions',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                if (canManage)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const CircleAvatar(
                                      backgroundColor:
                                          InventoryWorkspaceTokens.orangeFill,
                                      child: Icon(Icons.add,
                                          color: InventoryWorkspaceTokens
                                              .iconOrange),
                                    ),
                                    title: const Text('Start New Receipt',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                    subtitle:
                                        const Text('Create a stock receipt'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      ref
                                          .read(
                                              receivingSessionProvider.notifier)
                                          .reset();
                                      context.go(InventoryRoutes.receivingNew);
                                    },
                                  ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    backgroundColor:
                                        InventoryWorkspaceTokens.redFill,
                                    child: Icon(Icons.warning_amber_outlined,
                                        color:
                                            InventoryWorkspaceTokens.iconRed),
                                  ),
                                  title: const Text('Low Stock Alerts',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  subtitle:
                                      const Text('Items that need attention'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.go(InventoryRoutes.dashboard),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const InventorySectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Today's Summary",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                InventorySummaryRow(
                                    label: 'Total Receipts', value: '8'),
                                InventorySummaryRow(
                                    label: 'Total Quantity',
                                    value: '3,256 units'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          TenantAdminPaginationBar(
            currentPage: page,
            pageSize: pageSize,
            totalCount: filtered.length,
            onPageChanged: (p) =>
                ref.read(receivingPageProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}

class ReceivingWizardScreen extends ConsumerWidget {
  const ReceivingWizardScreen({super.key});

  static const steps = [
    'Select Product',
    'Enter Details',
    'Review',
    'Confirm',
    'Success',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(receivingSessionProvider);
    final notifier = ref.read(receivingSessionProvider.notifier);

    return TenantAdminPageScaffold(
      title: 'New Stock Receipt',
      subtitle: 'Stock increases only when Confirm Receive succeeds.',
      scrollable: false,
      showBackButton: true,
      onBackButtonPressed: () {
        if (session.step == 0 || session.posted) {
          context.go(InventoryRoutes.receiving);
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(session.error!,
                  style: const TextStyle(color: Color(0xFFE42525))),
            ),
          Expanded(child: _stepBody(context, session, notifier)),
        ],
      ),
    );
  }

  Widget _stepBody(
    BuildContext context,
    ReceivingSession session,
    ReceivingSessionNotifier notifier,
  ) {
    switch (session.step) {
      case 0:
        return _SelectStep(session: session, notifier: notifier);
      case 1:
        return _DetailsStep(session: session, notifier: notifier);
      case 2:
        return _ReviewStep(
            session: session, notifier: notifier, confirm: false);
      case 3:
        return _ReviewStep(session: session, notifier: notifier, confirm: true);
      default:
        return InventorySuccessState(
          title: 'Stock Received Successfully',
          message: 'On-hand increased at ${session.locationName}.',
          details: {
            'Receipt': session.receiptNumber ?? '',
            'Product': session.product?.name ?? '',
            'Quantity': session.quantity.toStringAsFixed(0),
            'Previous On Hand':
                (session.product?.onHand ?? 0).toStringAsFixed(0),
            'New On Hand': ((session.product?.onHand ?? 0) + session.quantity)
                .toStringAsFixed(0),
          },
          actions: [
            InventoryGhostButton(
              label: 'View Stock',
              onPressed: () => context.go(InventoryRoutes.currentStock),
            ),
            InventoryPrimaryButton(
              label: 'Serial Registry',
              onPressed: () => context.go(InventoryRoutes.serials),
            ),
            InventoryPrimaryButton(
              label: 'Back to Receiving',
              onPressed: () {
                notifier.reset();
                context.go(InventoryRoutes.receiving);
              },
            ),
          ],
        );
    }
  }
}

class _SelectStep extends StatelessWidget {
  const _SelectStep({required this.session, required this.notifier});
  final ReceivingSession session;
  final ReceivingSessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 720
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final loc in InventoryFrontendMock.locations)
                  SizedBox(
                    width: cardWidth.clamp(140, 220),
                    child: InventoryLocationCard(
                      name: loc.name,
                      selected: session.locationId == loc.id,
                      onTap: () => notifier.selectLocation(loc.id),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              for (final p in InventoryFrontendMock.products)
                InventoryProductPickRow(
                  name: p.name,
                  sku: p.sku,
                  selected: session.productId == p.id,
                  stockLabel: 'On Hand ${p.onHand.toStringAsFixed(0)}',
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
  }
}

class _DetailsStep extends StatefulWidget {
  const _DetailsStep({required this.session, required this.notifier});
  final ReceivingSession session;
  final ReceivingSessionNotifier notifier;

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  late final _qty = TextEditingController(
      text: widget.session.quantity == 0
          ? ''
          : widget.session.quantity.toStringAsFixed(0));
  late final _cost = TextEditingController(
      text: widget.session.unitCost == 0
          ? ''
          : widget.session.unitCost.toStringAsFixed(2));
  late final _supplier =
      TextEditingController(text: widget.session.supplierName);
  late final _invoice =
      TextEditingController(text: widget.session.invoiceNumber);
  late final _po = TextEditingController(text: widget.session.po);
  late final _notes = TextEditingController(text: widget.session.notes);
  late final _serials =
      TextEditingController(text: widget.session.serials.join('\n'));

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _supplier.dispose();
    _invoice.dispose();
    _po.dispose();
    _notes.dispose();
    _serials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serial = widget.session.product?.serialTracked == true;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text('Product: ${widget.session.product?.name ?? ''}'),
              const SizedBox(height: 12),
              InventoryNoteBanner(
                message:
                    'Stock increases only when Confirm Receive succeeds. Review does not change physical stock.',
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: inventoryInputDecoration(label: 'Quantity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: inventoryInputDecoration(label: 'Unit cost'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supplier,
                decoration: inventoryInputDecoration(label: 'Supplier name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _invoice,
                decoration: inventoryInputDecoration(label: 'Invoice number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _po,
                decoration: inventoryInputDecoration(label: 'PO / reference'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                decoration: inventoryInputDecoration(label: 'Notes'),
              ),
              if (serial) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _serials,
                  minLines: 3,
                  maxLines: 6,
                  decoration: inventoryInputDecoration(
                    label: 'Serial numbers (one per unit)',
                  ),
                ),
              ],
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
                widget.notifier.setDetails(
                  quantity: double.tryParse(_qty.text) ?? 0,
                  unitCost: double.tryParse(_cost.text) ?? 0,
                  supplierName: _supplier.text,
                  invoiceNumber: _invoice.text,
                  po: _po.text,
                  notes: _notes.text,
                  serials: _serials.text
                      .split('\n')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                );
                if (widget.notifier.validateDetails()) {
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

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.session,
    required this.notifier,
    required this.confirm,
  });
  final ReceivingSession session;
  final ReceivingSessionNotifier notifier;
  final bool confirm;

  @override
  Widget build(BuildContext context) {
    final after = (session.product?.onHand ?? 0) + session.quantity;
    return Column(
      children: [
        InventorySectionCard(
          child: Column(
            children: [
              _kv('Location', session.locationName),
              _kv('Product', session.product?.name ?? ''),
              _kv('Quantity', session.quantity.toStringAsFixed(0)),
              _kv('Supplier', session.supplierName),
              _kv('Invoice', session.invoiceNumber),
              _kv('Current On Hand',
                  (session.product?.onHand ?? 0).toStringAsFixed(0)),
              _kv('Stock after posting', after.toStringAsFixed(0)),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Review does not change physical stock.',
                  style: TextStyle(color: Color(0xFFA75100)),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            InventoryGhostButton(
              label: confirm ? 'Back to Review' : 'Edit Details',
              onPressed: () => notifier.setStep(confirm ? 2 : 1),
            ),
            const Spacer(),
            InventoryPrimaryButton(
              label: confirm ? 'Confirm Receive' : 'Continue to Confirm',
              onPressed: () {
                if (confirm) {
                  notifier.confirm();
                } else {
                  notifier.setStep(3);
                }
              },
            ),
          ],
        ),
      ],
    );
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
