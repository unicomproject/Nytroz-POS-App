import '../widgets/hardware_test_all_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/hardware_scope_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

import '../providers/hardware_dashboard_provider.dart';
import '../providers/hardware_overview_query_provider.dart';
import '../widgets/hardware_setup_widgets.dart';
import '../widgets/hardware_overview_help.dart';
import '../widgets/hardware_test_history.dart';
import '../widgets/hardware_overview_components.dart';

class HardwareListScreen extends ConsumerStatefulWidget {
  const HardwareListScreen({super.key});
  @override
  ConsumerState<HardwareListScreen> createState() => _HardwareListScreenState();
}

class _HardwareListScreenState extends ConsumerState<HardwareListScreen> {
  HardwareDashboardQuery get filters => ref.read(hardwareOverviewQueryProvider);
  void update(
      {int? page,
      String? outlet,
      String? search,
      String? type,
      String? status,
      String? sort}) {
    final q = filters;
    ref.read(hardwareOverviewQueryProvider.notifier).state = (
      page: page ?? q.page,
      outletId: outlet ?? q.outletId,
      search: search ?? q.search,
      type: type ?? q.type,
      status: status ?? q.status,
      sort: sort ?? q.sort
    );
  }

  String get search => filters.search;
  set search(String value) => update(search: value);
  String? get outletId => filters.outletId;
  set outletId(String? value) => update(outlet: value);
  int get page => filters.page - 1;
  set page(int value) => update(page: value + 1);
  String get type => filters.type;
  set type(String value) => update(type: value);
  String get statusFilter => filters.status;
  set statusFilter(String value) => update(status: value);
  String get sort => filters.sort;
  set sort(String value) => update(sort: value);
  late final TextEditingController searchController;
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController(text: search);
  }

  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(hardwareOverviewQueryProvider);
    ref.listen(hardwareOverviewQueryProvider, (previous, next) {
      if (previous?.search != next.search &&
          searchController.text != next.search) {
        searchController.text = next.search;
      }
    });
    final query = (
      page: page + 1,
      outletId: outletId,
      search: search,
      type: type,
      status: statusFilter,
      sort: sort
    );
    final dashboard = ref.watch(hardwareDashboardProvider(query));
    final devices = dashboard.whenData((d) => d.items);

    final canManage = ref
            .watch(tenantAdminAccessCheckerProvider)
            .valueOrNull
            ?.canManageTillHardware() ==
        true;
    final actions = <Widget>[
      OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff182438),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: devices.valueOrNull?.isNotEmpty != true
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => SimpleDialog(
                        title: const Text('Choose device — test logs'),
                        children: [
                          for (final d in devices.valueOrNull!)
                            SimpleDialogOption(
                                child: Text(d.hardwareDeviceName),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  showDialog<void>(
                                      context: context,
                                      builder: (_) => HardwareTestHistory(
                                          hardwareId: d.hardwareDeviceId,
                                          name: d.hardwareDeviceName));
                                })
                        ],
                      )),
          icon: const Icon(Icons.history),
          label: const Text('View Logs')),
      OutlinedButton.icon(onPressed: !canManage || outletId == null ? null : () => showDialog<void>(context: context, builder: (_) => HardwareTestAllDialog(outletId: outletId!)), icon: const Icon(Icons.play_arrow), label: const Text('Test All')),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff182438),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            ref.invalidate(hardwareDashboardProvider);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh')),
      if (canManage)
        FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => context.go('/tenant-admin/hardware/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Device')),
    ];
    final outlets = ref.watch(hardwareOutletOptionsProvider);
    if (outletId == null && outlets.valueOrNull?.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && outletId == null) {
          setState(
              () => update(outlet: outlets.requireValue.single.id, page: 1));
        }
      });
    }
    return HardwareSetupPage(
      title: '',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, constraints) {
          final title =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            const Text('Hardware Overview',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff101828),
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            const Text(
                'Manage POS hardware, device status and setup readiness for this outlet.',
                style: TextStyle(color: Color(0xff536887))),
          ]);
          final toolbar = Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                    width: 260,
                    child: ref.watch(hardwareOutletOptionsProvider).when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => TextButton(
                            onPressed: () =>
                                ref.invalidate(hardwareOutletOptionsProvider),
                            child: const Text('Retry outlet access')),
                        data: (options) => DropdownButtonFormField<String>(
                              key: ValueKey(outletId),
                              initialValue: options.any((o) => o.id == outletId)
                                  ? outletId
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                  hintText: 'Select outlet',
                                  isDense: true),
                              items: [
                                for (final o in options)
                                  DropdownMenuItem(
                                      value: o.id,
                                      child: Text(o.name,
                                          overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: (value) => setState(() {
                                outletId = value;
                                page = 0;
                              }),
                            ))),
                if (canManage) actions.last,
                actions[1],
                actions[0]
              ]);
          if (constraints.maxWidth < 1400) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 18), toolbar]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: title),
            const SizedBox(width: 18),
            toolbar
          ]);
        }),
        const SizedBox(height: 24),
        devices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(
              'Unable to load hardware. Check access and retry using Refresh.'),
          data: (items) {
            final data = dashboard.requireValue;
            final statuses = data.statuses;
            final pages = (data.totalCount / 5).ceil().clamp(1, 100000);
            final current = page;
            final rows = items;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HardwareOverviewStats(dashboard: data),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    final deviceTable = HardwareSetupCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                Text('Devices (${data.totalCount})',
                                    style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(
                                    width: 240,
                                    child: TextField(
                                      controller: searchController,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.search),
                                        hintText: 'Search devices...',
                                      ),
                                      onChanged: (value) {
                                        debounce?.cancel();
                                        debounce = Timer(
                                            const Duration(milliseconds: 350),
                                            () {
                                          if (mounted) {
                                            setState(() {
                                              search = value;
                                              page = 0;
                                            });
                                          }
                                        });
                                      },
                                    ))
                              ]),
                          const SizedBox(height: 16),
                          if (items.isEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 60),
                                child: Column(children: [
                                  const Icon(Icons.devices_other,
                                      size: 48, color: Color(0xff98a7bc)),
                                  const SizedBox(height: 16),
                                  Text(outletId == null
                                      ? 'Select an outlet to view hardware'
                                      : 'No devices found'),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Add a device or adjust your filters.')
                                ]))
                          else
                            HardwareOverviewDeviceTable(
                                items: rows,
                                statuses: statuses,
                                onOpen: (id) =>
                                    context.go('/tenant-admin/hardware/$id')),
                          const SizedBox(height: 12),
                          Wrap(spacing: 12, children: [
                            DropdownButton<String>(
                                value: type,
                                items: [
                                  const DropdownMenuItem(
                                      value: '', child: Text('All types')),
                                  for (final e in hardwareTypes.entries)
                                    DropdownMenuItem(
                                        value: e.key, child: Text(e.value)),
                                ],
                                onChanged: (v) => setState(() {
                                      type = v!;
                                      page = 0;
                                    })),
                            DropdownButton<String>(
                                value: statusFilter,
                                items: [
                                  const DropdownMenuItem(
                                      value: '', child: Text('All statuses')),
                                  for (final s in [
                                    'Ready',
                                    'Not Configured',
                                    'Disconnected',
                                    'Issues',
                                    'Unknown',
                                    'Unsupported'
                                  ])
                                    DropdownMenuItem(value: s, child: Text(s)),
                                ],
                                onChanged: (v) => setState(() {
                                      statusFilter = v!;
                                      page = 0;
                                    })),
                            DropdownButton<String>(
                                value: sort,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'name', child: Text('Name A–Z')),
                                  DropdownMenuItem(
                                      value: 'name_desc',
                                      child: Text('Name Z–A')),
                                  DropdownMenuItem(
                                      value: 'last_seen',
                                      child: Text('Recently seen')),
                                ],
                                onChanged: (v) => setState(() {
                                      sort = v!;
                                      page = 0;
                                    })),
                          ]),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    onPressed: current > 0
                                        ? () =>
                                            setState(() => page = current - 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_left)),
                                Text('Page ${current + 1} of $pages'),
                                IconButton(
                                    onPressed: current + 1 < pages
                                        ? () =>
                                            setState(() => page = current + 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_right)),
                              ]),
                        ]));
                    final help = HardwareOverviewHelp(
                        dashboard: data,
                        onRefresh: () =>
                            ref.invalidate(hardwareDashboardProvider(query)));
                    if (constraints.maxWidth < 960) {
                      return Column(children: [
                        deviceTable,
                        const SizedBox(height: 16),
                        help
                      ]);
                    }
                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: deviceTable),
                          const SizedBox(width: 20),
                          Expanded(child: help),
                        ]);
                  }),
                ]);
          },
        ),
      ]),
    );
  }
}
