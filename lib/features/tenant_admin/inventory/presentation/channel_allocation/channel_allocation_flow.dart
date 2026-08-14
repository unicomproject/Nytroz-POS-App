import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
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
          'Set channel promise limits. Allocation does not move physical on-hand stock.',
      actions: [
        if (canManage)
          InventoryPrimaryButton(
            label: 'New Allocation',
            onPressed: () {
              ref.read(channelSessionProvider.notifier).reset();
              context.go(InventoryRoutes.channelNew);
            },
          ),
      ],
      child: Column(
        children: [
          InventorySearchField(
            value: search,
            onChanged: (v) {
              ref.read(channelSearchProvider.notifier).state = v;
              ref.read(channelPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const TenantAdminEmptyState(
              title: 'No allocations found',
              message: 'Create a channel allocation to publish promise limits.',
            )
          else
            InventorySectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final row in filtered.sublist(start, end))
                    ListTile(
                      title: Text(row.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${row.$2} · ${row.$3}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                        InventoryRoutes.channelDetailPath(row.$1),
                      ),
                    ),
                ],
              ),
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
          InventoryStepper(steps: steps, currentIndex: session.step),
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
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final loc in InventoryFrontendMock.locations)
                ChoiceChip(
                  label: Text(loc.name),
                  selected: session.locationId == loc.id,
                  onSelected: (_) => notifier.selectLocation(loc.id),
                ),
            ],
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
                  : Material(
                      color: Colors.transparent,
                      child: RadioGroup<String>(
                        groupValue: session.productId,
                        onChanged: (v) {
                          if (v != null) notifier.selectProduct(v);
                        },
                        child: ListView(
                          children: [
                            for (final p in products)
                              RadioListTile<String>(
                                value: p.id,
                                title: Text(p.name),
                                subtitle: Text(p.sku),
                              ),
                          ],
                        ),
                      ),
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
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final ch in InventoryFrontendMock.channels)
                FilterChip(
                  label: Text('${ch.name}\n${ch.subtitle}'),
                  selected: session.selectedChannelIds.contains(ch.id),
                  onSelected: (_) => notifier.toggleChannel(ch.id),
                ),
            ],
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
                decoration: const InputDecoration(labelText: 'Safety buffer'),
              ),
              for (final id in widget.session.selectedChannelIds)
                TextField(
                  controller: _limitControllers[id],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        '${InventoryFrontendMock.channels.firstWhere((c) => c.id == id).name} allocation limit',
                  ),
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
            Text(id,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Selected channels use sales channel names, not outlet names.',
            ),
            const SizedBox(height: 16),
            for (final ch in InventoryFrontendMock.channels.take(3))
              ListTile(
                title: Text(ch.name),
                subtitle: Text(ch.subtitle),
                trailing: const Text('40',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            const Divider(),
            const Text(
              'Physical on-hand was not changed by this allocation (Model B).',
              style: TextStyle(color: Color(0xFFA75100)),
            ),
          ],
        ),
      ),
    );
  }
}
