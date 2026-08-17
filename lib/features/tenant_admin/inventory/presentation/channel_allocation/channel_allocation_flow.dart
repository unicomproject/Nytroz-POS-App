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

class ChannelSession {
  const ChannelSession({
    this.step = 0,
    this.locationId,
    this.productId,
    this.selectedChannelIds = const {},
    this.limits = const {},
    this.safetyBuffer = 0,
    this.posted = false,
    this.reference,
    this.error,
  });

  final int step;
  final String? locationId;
  final String? productId;
  final Set<String> selectedChannelIds;
  final Map<String, double> limits;
  final double safetyBuffer;
  final bool posted;
  final String? reference;
  final String? error;

  InventoryMockProduct? get product {
    if (productId == null) return null;
    for (final p in InventoryFrontendMock.products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  String get locationName {
    for (final l in InventoryFrontendMock.locations) {
      if (l.id == locationId) return l.name;
    }
    return '';
  }

  double get allocatedTotal =>
      selectedChannelIds.fold(0, (sum, id) => sum + (limits[id] ?? 0));

  ChannelSession copyWith({
    int? step,
    String? locationId,
    String? productId,
    Set<String>? selectedChannelIds,
    Map<String, double>? limits,
    double? safetyBuffer,
    bool? posted,
    String? reference,
    String? error,
    bool clearError = false,
  }) {
    return ChannelSession(
      step: step ?? this.step,
      locationId: locationId ?? this.locationId,
      productId: productId ?? this.productId,
      selectedChannelIds: selectedChannelIds ?? this.selectedChannelIds,
      limits: limits ?? this.limits,
      safetyBuffer: safetyBuffer ?? this.safetyBuffer,
      posted: posted ?? this.posted,
      reference: reference ?? this.reference,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChannelSessionNotifier extends StateNotifier<ChannelSession> {
  ChannelSessionNotifier() : super(const ChannelSession());

  void setStep(int step) => state = state.copyWith(step: step, clearError: true);
  void back() {
    if (state.step > 0 && !state.posted) {
      state = state.copyWith(step: state.step - 1, clearError: true);
    }
  }

  void selectLocation(String id) =>
      state = state.copyWith(locationId: id, clearError: true);
  void selectProduct(String id) =>
      state = state.copyWith(productId: id, clearError: true);

  void toggleChannel(String id) {
    final next = {...state.selectedChannelIds};
    if (!next.add(id)) next.remove(id);
    state = state.copyWith(selectedChannelIds: next, clearError: true);
  }

  void setLimit(String id, double qty) {
    state = state.copyWith(
      limits: {...state.limits, id: qty},
      clearError: true,
    );
  }

  void setSafety(double qty) =>
      state = state.copyWith(safetyBuffer: qty, clearError: true);

  bool validate(int fromStep) {
    switch (fromStep) {
      case 0:
        if (state.locationId == null) {
          state = state.copyWith(error: 'Select a source location.');
          return false;
        }
        return true;
      case 1:
        if (state.productId == null) {
          state = state.copyWith(error: 'Select a product.');
          return false;
        }
        return true;
      case 3:
        if (state.selectedChannelIds.isEmpty) {
          state = state.copyWith(error: 'Select at least one sales channel.');
          return false;
        }
        return true;
      case 4:
        if (state.allocatedTotal + state.safetyBuffer >
            (state.product?.available ?? 0)) {
          state = state.copyWith(
              error: 'Channel limits plus safety buffer cannot exceed Available.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void confirm() {
    if (state.posted) return;
    state = state.copyWith(
      posted: true,
      reference: 'ALLOC-10004',
      step: 7,
      clearError: true,
    );
  }

  void reset() => state = const ChannelSession();
}

final channelSessionProvider =
    StateNotifierProvider<ChannelSessionNotifier, ChannelSession>(
  (ref) => ChannelSessionNotifier(),
);

final channelSearchProvider = StateProvider<String>((ref) => '');
final channelPageProvider = StateProvider<int>((ref) => 1);
final channelProductQueryProvider = StateProvider<String>((ref) => '');

class ChannelAllocationDashboardScreen extends ConsumerWidget {
  const ChannelAllocationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(channelSearchProvider);
    final page = ref.watch(channelPageProvider);
    const rows = [
      ('ALLOC-10003', 'Home Jersey (Red, L)', 'POS, Online Store'),
      ('ALLOC-10002', 'OneVerz Water Bottle 750ml', 'Click & Collect'),
      ('ALLOC-10001', 'OneVerz Display TV 55"', 'POS, Delivery'),
      ('ALLOC-10000', 'OneVerz Mug', 'POS'),
      ('ALLOC-09999', 'Home Jersey (Red, L)', 'Online Store'),
      ('ALLOC-09998', 'OneVerz Water Bottle 750ml', 'Delivery, POS'),
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

    final canManage = ref
            .watch(tenantAdminAccessCheckerProvider)
            .valueOrNull
            ?.canManageChannelAllocation() ??
        true;

    return TenantAdminPageScaffold(
      title: 'Channel Stock Allocation',
      subtitle:
          'Allocate available stock from outlets or warehouse to sales channels.',
      actions: [
        if (canManage)
          TenantAdminPrimaryButton(
            label: 'New Allocation',
            onPressed: () {
              ref.read(channelSessionProvider.notifier).reset();
              context.go(InventoryRoutes.channelNew);
            },
          ),
      ],
      child: Column(
        children: [
          InventoryMetricStrip(
            cards: const [
              TenantAdminMetricCard(
                title: 'Total Allocated Today',
                value: '1,248',
                subtitle: 'Units',
                icon: Icons.layers_outlined,
                status: TenantAdminStatusType.online,
              ),
              TenantAdminMetricCard(
                title: 'Pending Review',
                value: '7',
                subtitle: 'Allocations',
                icon: Icons.hourglass_top_outlined,
                status: TenantAdminStatusType.warning,
              ),
              TenantAdminMetricCard(
                title: 'Active Channels',
                value: '6',
                subtitle: 'Channels',
                icon: Icons.hub_outlined,
                status: TenantAdminStatusType.success,
              ),
              TenantAdminMetricCard(
                title: 'Low Buffer Alerts',
                value: '3',
                subtitle: 'Alerts',
                icon: Icons.warning_amber_outlined,
                status: TenantAdminStatusType.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TenantAdminSearchField(
            value: search,
            hint: 'Search products, allocation ref...',
            onChanged: (v) {
              ref.read(channelSearchProvider.notifier).state = v;
              ref.read(channelPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const TenantAdminEmptyState(
              title: 'No allocations found',
              message: 'Create a channel allocation to publish promise limits.',
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
                        'Recent Allocations',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TenantAdminDataTable(
                      columns: const [
                        DataColumn(label: Text('Allocation Ref')),
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Channels')),
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
                              DataCell(Text(row.$3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TenantAdminStatusBadge(
                                    label: 'Completed',
                                    status: TenantAdminStatusType.success,
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  onPressed: () => context.go(
                                    InventoryRoutes.channelDetailPath(row.$1),
                                  ),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                );
                if (constraints.maxWidth < 980) return table;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: table),
                    const SizedBox(width: 15),
                    const SizedBox(
                      width: 230,
                      child: Column(
                        children: [
                          InventorySectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Allocation Summary',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                InventorySummaryRow(
                                    label: 'Completed', value: '12'),
                                InventorySummaryRow(
                                    label: 'Pending', value: '3'),
                                InventorySummaryRow(
                                    label: 'Draft', value: '2'),
                                InventorySummaryRow(
                                    label: 'Total Allocations', value: '20'),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          InventoryNoteBanner(
                            message:
                                'Channel allocation does not move physical on-hand stock. It publishes promise limits for each sales channel (Model B).',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          TenantAdminPaginationBar(
            currentPage: page,
            pageSize: pageSize,
            totalCount: filtered.length,
            onPageChanged: (p) =>
                ref.read(channelPageProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}

class ChannelAllocationWizardScreen extends ConsumerWidget {
  const ChannelAllocationWizardScreen({super.key});

  static const steps = [
    'Select Source',
    'Search Product',
    'Product Details',
    'Select Channels',
    'Enter Quantity',
    'Review',
    'Confirm',
    'Success',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(channelSessionProvider);
    final notifier = ref.read(channelSessionProvider.notifier);
    return TenantAdminPageScaffold(
      title: 'New Channel Allocation',
      subtitle: 'Model B — availability control, not a physical transfer.',
      scrollable: false,
      showBackButton: true,
      onBackButtonPressed: () {
        if (session.step == 0 || session.posted) {
          context.go(InventoryRoutes.channel);
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
          Expanded(child: _body(context, ref, session, notifier)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ChannelSession session,
    ChannelSessionNotifier notifier,
  ) {
    switch (session.step) {
      case 0:
        return _footer(
          notifier: notifier,
          onContinue: () {
            if (notifier.validate(0)) notifier.setStep(1);
          },
          child: LayoutBuilder(
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
        );
      case 1:
        final q = ref.watch(channelProductQueryProvider).toLowerCase();
        final products = InventoryFrontendMock.products
            .where((p) =>
                q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q))
            .toList();
        return Column(
          children: [
            InventorySearchField(
              value: ref.watch(channelProductQueryProvider),
              onChanged: (v) =>
                  ref.read(channelProductQueryProvider.notifier).state = v,
            ),
            Expanded(
              child: products.isEmpty
                  ? const TenantAdminEmptyState(
                      title: 'No products found',
                      message: 'Try another name or SKU.',
                    )
                  : ListView(
                      children: [
                        for (final p in products)
                          InventoryProductPickRow(
                            name: p.name,
                            sku: p.sku,
                            selected: session.productId == p.id,
                            stockLabel:
                                'Available ${p.available.toStringAsFixed(0)}',
                            onTap: () => notifier.selectProduct(p.id),
                          ),
                      ],
                    ),
            ),
            Row(
              children: [
                InventoryGhostButton(label: 'Back', onPressed: notifier.back),
                const Spacer(),
                InventoryPrimaryButton(
                  label: 'Continue',
                  onPressed: () {
                    if (notifier.validate(1)) notifier.setStep(2);
                  },
                ),
              ],
            ),
          ],
        );
      case 2:
        final p = session.product;
        return _footer(
          notifier: notifier,
          onContinue: () => notifier.setStep(3),
          child: InventorySectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.name ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(p?.sku ?? ''),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _metric('On Hand', p?.onHand ?? 0),
                    _metric('Reserved', p?.reserved ?? 0),
                    _metric('Available', p?.available ?? 0),
                    _metric('Already Allocated', p?.alreadyAllocated ?? 0),
                    _metric('Safety Buffer', p?.safetyBuffer ?? 0),
                  ],
                ),
              ],
            ),
          ),
        );
      case 3:
        return _footer(
          notifier: notifier,
          onContinue: () {
            if (notifier.validate(3)) notifier.setStep(4);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final ch in InventoryFrontendMock.channels)
                    SizedBox(
                      width: cardWidth.clamp(150, 220),
                      child: InventoryChannelPickCard(
                        name: ch.name,
                        subtitle: ch.subtitle,
                        selected: session.selectedChannelIds.contains(ch.id),
                        onTap: () => notifier.toggleChannel(ch.id),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      case 4:
        return _QuantityStep(session: session, notifier: notifier);
      case 5:
      case 6:
        final confirm = session.step == 6;
        return Column(
          children: [
            InventorySectionCard(
              child: Column(
                children: [
                  _kv('Source', session.locationName),
                  _kv('Product', session.product?.name ?? ''),
                  _kv('Available',
                      (session.product?.available ?? 0).toStringAsFixed(0)),
                  _kv('Safety Buffer', session.safetyBuffer.toStringAsFixed(0)),
                  for (final id in session.selectedChannelIds)
                    _kv(
                      InventoryFrontendMock.channels
                          .firstWhere((c) => c.id == id)
                          .name,
                      (session.limits[id] ?? 0).toStringAsFixed(0),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Channel allocation does not reduce On Hand. It publishes the quantity that may be promised to each sales channel.',
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
                  label: confirm ? 'Back to Review' : 'Edit Quantity',
                  onPressed: () => notifier.setStep(confirm ? 5 : 4),
                ),
                const Spacer(),
                InventoryPrimaryButton(
                  label: confirm ? 'Confirm Allocation' : 'Continue to Confirm',
                  onPressed: () {
                    if (confirm) {
                      notifier.confirm();
                    } else {
                      notifier.setStep(6);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      default:
        return InventorySuccessState(
          title: 'Allocation Completed Successfully',
          message:
              'Channel promise limits were saved. Physical on-hand did not change.',
          details: {
            'Reference': session.reference ?? '',
            'On Hand (unchanged)':
                (session.product?.onHand ?? 0).toStringAsFixed(0),
            'Allocated Total': session.allocatedTotal.toStringAsFixed(0),
          },
          actions: [
            InventoryGhostButton(
              label: 'View Detail',
              onPressed: () => context.go(
                InventoryRoutes.channelDetailPath(
                    session.reference ?? 'ALLOC-10004'),
              ),
            ),
            InventoryPrimaryButton(
              label: 'Back to Allocations',
              onPressed: () {
                notifier.reset();
                context.go(InventoryRoutes.channel);
              },
            ),
          ],
        );
    }
  }

  Widget _footer({
    required ChannelSessionNotifier notifier,
    required VoidCallback onContinue,
    required Widget child,
  }) {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: child)),
        Row(
          children: [
            InventoryGhostButton(label: 'Back', onPressed: notifier.back),
            const Spacer(),
            InventoryPrimaryButton(label: 'Continue', onPressed: onContinue),
          ],
        ),
      ],
    );
  }

  Widget _metric(String label, double value) => SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            Text(value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(k, style: const TextStyle(color: Color(0xFF64748B)))),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _QuantityStep extends StatefulWidget {
  const _QuantityStep({required this.session, required this.notifier});
  final ChannelSession session;
  final ChannelSessionNotifier notifier;

  @override
  State<_QuantityStep> createState() => _QuantityStepState();
}

class _QuantityStepState extends State<_QuantityStep> {
  late final _buffer = TextEditingController(
      text: widget.session.safetyBuffer.toStringAsFixed(0));
  final _limitControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final id in widget.session.selectedChannelIds) {
      _limitControllers[id] = TextEditingController(
        text: (widget.session.limits[id] ?? 0).toStringAsFixed(0),
      );
    }
  }

  @override
  void dispose() {
    _buffer.dispose();
    for (final c in _limitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              TextField(
                controller: _buffer,
                keyboardType: TextInputType.number,
                decoration:
                    inventoryInputDecoration(label: 'Safety buffer'),
              ),
              for (final id in widget.session.selectedChannelIds) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _limitControllers[id],
                  keyboardType: TextInputType.number,
                  decoration: inventoryInputDecoration(
                    label:
                        '${InventoryFrontendMock.channels.firstWhere((c) => c.id == id).name} allocation limit',
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
                widget.notifier.setSafety(double.tryParse(_buffer.text) ?? 0);
                for (final e in _limitControllers.entries) {
                  widget.notifier
                      .setLimit(e.key, double.tryParse(e.value.text) ?? 0);
                }
                if (widget.notifier.validate(4)) {
                  widget.notifier.setStep(5);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ChannelAllocationDetailScreen extends StatelessWidget {
  const ChannelAllocationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return TenantAdminPageScaffold(
      title: 'Allocation Details',
      showBackButton: true,
      onBackButtonPressed: () => context.go(InventoryRoutes.channel),
      child: InventorySectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              id,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selected channels use sales channel names, not outlet names.',
              style: TextStyle(fontSize: 12, color: Color(0xFF65758D)),
            ),
            const SizedBox(height: 12),
            for (final ch in InventoryFrontendMock.channels.take(3))
              InventorySummaryRow(label: ch.name, value: '40'),
            const Divider(height: 20),
            const InventoryNoteBanner(
              message:
                  'Physical on-hand was not changed by this allocation (Model B).',
            ),
          ],
        ),
      ),
    );
  }
}
