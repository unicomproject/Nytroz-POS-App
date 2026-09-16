import 'package:flutter/material.dart';
import '../../domain/entities/hardware_device_list_item.dart';
import '../providers/hardware_dashboard_provider.dart';
import 'hardware_setup_widgets.dart';

class HardwareOverviewStats extends StatelessWidget {
  const HardwareOverviewStats({super.key, required this.dashboard});
  final HardwareDashboard dashboard;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 780
            ? 4
            : c.maxWidth >= 450
                ? 2
                : 1;
        final values = [
          (
            'Total Devices',
            dashboard.totalCount,
            Icons.devices_outlined,
            const Color(0xff1675ee)
          ),
          (
            'Ready',
            dashboard.summary['Ready'] ?? 0,
            Icons.check_circle,
            const Color(0xff079447)
          ),
          (
            'Needs Attention',
            dashboard.summary['Issues'] ?? 0,
            Icons.warning_rounded,
            const Color(0xffff7100)
          ),
          (
            'Not Assigned',
            dashboard.notAssignedCount ?? '?',
            Icons.settings_outlined,
            const Color(0xffd93651)
          ),
        ];
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final v in values)
            Container(
              width: (c.maxWidth - 14 * (columns - 1)) / columns,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: v.$4.withValues(alpha: .045),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: v.$4.withValues(alpha: .25))),
              child: Row(children: [
                Container(
                    width: 54,
                    height: 60,
                    decoration: BoxDecoration(
                        color: v.$4.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(v.$3, color: v.$4, size: 30)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${v.$2}',
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff101828))),
                      Text(v.$1, style: const TextStyle(fontSize: 13))
                    ]))
              ]),
            )
        ]);
      });
}

class HardwareOverviewDeviceTable extends StatelessWidget {
  const HardwareOverviewDeviceTable(
      {super.key,
      required this.items,
      required this.statuses,
      required this.onOpen});
  final List<HardwareDeviceListItem> items;
  final Map<String, String> statuses;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth < 620 ? 620.0 : c.maxWidth;
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
                width: width,
                child: Column(children: [
                  Container(
                      color: const Color(0xfff1f5f9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      child: const Row(children: [
                        Expanded(
                            flex: 4,
                            child: Text('Device',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        Expanded(
                            flex: 2,
                            child: Text('Connection',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        Expanded(
                            flex: 3,
                            child: Text('Assigned POS / Till',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        Expanded(
                            flex: 3,
                            child: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        SizedBox(width: 24)
                      ])),
                  for (final d in items)
                    InkWell(
                        onTap: () => onOpen(d.hardwareDeviceId),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 24),
                            decoration: const BoxDecoration(
                                border: Border(
                                    bottom:
                                        BorderSide(color: Color(0xffe9eef5)))),
                            child: Row(children: [
                              Expanded(
                                  flex: 4,
                                  child: Row(children: [
                                    Container(
                                        width: 44,
                                        height: 52,
                                        decoration: BoxDecoration(
                                            color: const Color(0xfff1f5fa),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Icon(
                                            hardwareTypeIcon(
                                                d.hardwareDeviceType),
                                            size: 28,
                                            color: const Color(0xff344563))),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(d.hardwareDeviceName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13)),
                                          const SizedBox(height: 5),
                                          Text(
                                              d.model ??
                                                  hardwareTypeLabel(
                                                      d.hardwareDeviceType),
                                              style: const TextStyle(
                                                  color: Color(0xff536887),
                                                  fontSize: 12))
                                        ]))
                                  ])),
                              Expanded(
                                  flex: 2,
                                  child: Row(children: [
                                    Icon(
                                        d.connectionType == 'USB'
                                            ? Icons.usb
                                            : d.connectionType == 'BLUETOOTH'
                                                ? Icons.bluetooth
                                                : Icons.lan_outlined,
                                        size: 21),
                                    const SizedBox(width: 4),
                                    Flexible(
                                        child: Text(d.connectionType,
                                            style:
                                                const TextStyle(fontSize: 12)))
                                  ])),
                              Expanded(
                                  flex: 3,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            d.isAssigned
                                                ? (d.assignedTillId != null
                                                    ? (d.assignedTillName ??
                                                        'Till assigned')
                                                    : (d.assignedPosDeviceName ??
                                                        'POS assigned'))
                                                : 'Not assigned',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 5),
                                        Text(d.outletName,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff536887)))
                                      ])),
                              Expanded(
                                  flex: 3,
                                  child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: HardwareStatusBadge(
                                          status:
                                              statuses[d.hardwareDeviceId] ??
                                                  'Unknown'))),
                              const Icon(Icons.chevron_right, size: 20),
                            ]))),
                ])));
      });
}
