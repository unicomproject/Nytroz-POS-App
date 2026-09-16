import 'package:flutter/material.dart';
import '../providers/hardware_dashboard_provider.dart';
import 'hardware_setup_widgets.dart';

class HardwareOverviewHelp extends StatelessWidget {
  const HardwareOverviewHelp(
      {super.key, required this.dashboard, required this.onRefresh});
  final HardwareDashboard dashboard;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HardwareSetupCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.monitor_heart_outlined),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Hardware Health',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: 'Refresh hardware health',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh)),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xfff0f6fd),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xff1675ee)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      dashboard.totalCount == 0
                          ? 'No hardware to monitor'
                          : 'Latest reported device status',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 12),
          Text(
              'Last checked: ${dashboard.checkedAt?.toLocal().toString().split('.').first ?? 'Not reported'}',
              style: const TextStyle(fontSize: 12, color: Color(0xff536887))),
          const SizedBox(height: 12),
          for (final status in [
            'Ready',
            'Issues',
            'Disconnected',
            'Unknown',
            'Unsupported'
          ])
            Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xfff6f8fb),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    '$status: ${dashboard.summary[status] ?? 'Not reported'}')),
          const SizedBox(height: 8),
          const Text(
              'Updates every 30 seconds from POS reports. Test on the assigned POS to verify readiness.',
              style: TextStyle(fontSize: 12, color: Color(0xff536887))),
        ])),
        const SizedBox(height: 20),
        HardwareSetupCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick Tips', style: Theme.of(context).textTheme.titleLarge),
          const ExpansionTile(
              leading: Icon(Icons.usb, size: 20),
              title: Text('USB device does not appear'),
              children: [
                Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Connect the powered device to the Android POS running discovery, grant USB permission, and retry. A device connected to your laptop is not automatically available inside its emulator.')),
              ]),
          const ExpansionTile(
              leading: Icon(Icons.wifi, size: 20),
              title: Text('Bluetooth or LAN connection'),
              children: [
                Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Pair Bluetooth printers in the host device settings first. For LAN, enter the actual printer address and port and check network reachability from the POS.')),
              ]),
          const ExpansionTile(
              leading: Icon(Icons.qr_code_scanner, size: 20),
              title: Text('Scanner reads but cart stays empty'),
              children: [
                Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Enable the scanner configuration on the assigned POS. Check its input mode and barcode mapping to an active, sellable product in this outlet. A registry entry alone does not enable scan-to-cart.')),
              ]),
          const ExpansionTile(
              leading: Icon(Icons.point_of_sale, size: 20),
              title: Text('Printer-attached cash drawer'),
              children: [
                Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Configure the parent printer and assign both devices to the same target. Test from the authorized POS and confirm the drawer physically opened.')),
              ]),
          TextButton(
              onPressed: () => showSupportedHardware(context),
              child: const Text('View compatibility catalog')),
        ]))
      ]);
}
