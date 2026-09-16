import 'package:flutter/material.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hardware_providers.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';

class HardwareSetupPage extends StatelessWidget {
  const HardwareSetupPage(
      {super.key,
      required this.title,
      required this.child,
      this.subtitle,
      this.actions = const []});
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: TenantAdminColors.primary,
                onPrimary: TenantAdminColors.surface,
                surface: TenantAdminColors.surface,
                onSurface: TenantAdminColors.bodyText,
              ),
          textTheme: Theme.of(context).textTheme.apply(
              bodyColor: TenantAdminColors.bodyText,
              displayColor: TenantAdminColors.bodyText),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48))),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: TenantAdminColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TenantAdminColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: TenantAdminColors.border)),
          ),
        ),
        child: DefaultTextStyle.merge(
            style: const TextStyle(color: TenantAdminColors.bodyText),
            child: TenantAdminPageScaffold(
                title: title,
                subtitle: subtitle,
                actions: actions,
                backgroundColor: TenantAdminColors.surface,
                child: child)),
      );
}

const hardwareTypes = {
  'RECEIPT_PRINTER': 'Receipt Printer',
  'BARCODE_SCANNER': 'Barcode Scanner',
  'CASH_DRAWER': 'Cash Drawer',
  'CARD_READER': 'Payment Terminal',
  'CUSTOMER_DISPLAY': 'Customer Display',
  'SCALE': 'Scale',
};
String hardwareTypeLabel(String type) => hardwareTypes[type] ?? type;
IconData hardwareTypeIcon(String type) => switch (type) {
      'RECEIPT_PRINTER' => Icons.receipt_long,
      'BARCODE_SCANNER' => Icons.qr_code_scanner,
      'CASH_DRAWER' => Icons.point_of_sale,
      'CARD_READER' => Icons.credit_card,
      'CUSTOMER_DISPLAY' => Icons.desktop_windows_outlined,
      'SCALE' => Icons.scale_outlined,
      _ => Icons.devices_other,
    };

class HardwareSetupCard extends StatelessWidget {
  const HardwareSetupCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
        color: TenantAdminColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: TenantAdminColors.border)),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}

class HardwareSetupColumns extends StatelessWidget {
  const HardwareSetupColumns(
      {super.key, required this.child, required this.summary});
  final Widget child, summary;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < TenantAdminBreakpoints.tablet) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HardwareSetupCard(child: summary),
                const SizedBox(height: 16),
                HardwareSetupCard(child: child)
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: HardwareSetupCard(child: child)),
          const SizedBox(width: 20),
          Expanded(child: HardwareSetupCard(child: summary)),
        ]);
      });
}

void showSupportedHardware(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware compatibility'),
        content: SizedBox(
            width: 520,
            child: Consumer(
                builder: (context, ref, _) => ref
                    .watch(hardwareCompatibilityProvider)
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) =>
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(
                            'Cannot load hardware compatibility. Please try again.'),
                        TextButton(
                            onPressed: () =>
                                ref.invalidate(hardwareCompatibilityProvider),
                            child: const Text('Retry')),
                      ]),
                      data: (profiles) => SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            const Text(
                                'Software adapter availability is not physical model certification. Test each device on the assigned POS.'),
                            for (final profile in profiles)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                    '${hardwareTypeLabel(profile.deviceType)} · ${profile.connectionType}'),
                                subtitle: Text(
                                    '${profile.protocol} · ${profile.supportLevel}\n${profile.notes}'),
                              ),
                          ])),
                    ))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );

class HardwareSetupStepper extends StatelessWidget {
  const HardwareSetupStepper({super.key, required this.step});
  final int step;
  static const labels = [
    'Choose Device Type',
    'Discover & Connect',
    'Configure Device',
    'Assign Device',
    'Test Devices'
  ];
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        return Wrap(
            spacing: TenantAdminSpacing.md,
            runSpacing: TenantAdminSpacing.md,
            children: [
              for (var index = 0; index < labels.length; index++)
                SizedBox(
                    width: narrow
                        ? (constraints.maxWidth - TenantAdminSpacing.md) / 2
                        : (constraints.maxWidth - 4 * TenantAdminSpacing.md) /
                            5,
                    child: Semantics(
                        label: 'Step ${index + 1}: ${labels[index]}',
                        selected: step == index,
                        child: Row(children: [
                          CircleAvatar(
                              radius: 18,
                              backgroundColor: step > index
                                  ? const Color(0xff008b45)
                                  : step == index
                                      ? TenantAdminColors.primary
                                      : TenantAdminColors.subtleBackground,
                              foregroundColor: step >= index
                                  ? TenantAdminColors.surface
                                  : TenantAdminColors.bodyText,
                              child: step > index
                                  ? const Icon(Icons.check, size: 20)
                                  : Text('${index + 1}')),
                          const SizedBox(width: TenantAdminSpacing.sm),
                          Expanded(
                              child: Text(labels[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: step == index
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: step == index
                                              ? TenantAdminColors.primary
                                              : TenantAdminColors.bodyText))),
                        ]))),
            ]);
      });
}

class HardwareStatusBadge extends StatelessWidget {
  const HardwareStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Ready' => const Color(0xff008b45),
      'Issues' || 'Needs Attention' => const Color(0xffb45309),
      'Disconnected' || 'Offline' => const Color(0xffd92d20),
      _ => const Color(0xff64748b),
    };
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              status == 'Ready'
                  ? Icons.check_circle
                  : status == 'Issues'
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
              size: 18,
              color: color),
          const SizedBox(width: 6),
          Text(status,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]));
  }
}
