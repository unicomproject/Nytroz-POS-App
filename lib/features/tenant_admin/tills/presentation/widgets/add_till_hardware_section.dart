import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_create_options.dart';

class AddTillHardwareSection extends StatelessWidget {
  const AddTillHardwareSection({
    super.key,
    required this.options,
    required this.selectedOutletId,
    required this.selectedPosDeviceId,
    required this.selectedScannerId,
    required this.selectedPrinterId,
    required this.selectedCashDrawerId,
    required this.selectedCardReaderId,
    required this.posDeviceNameController,
    required this.scannerNameController,
    required this.printerNameController,
    required this.cashDrawerNameController,
    required this.cardReaderNameController,
    required this.onPosDeviceChanged,
    required this.onScannerChanged,
    required this.onPrinterChanged,
    required this.onCashDrawerChanged,
    required this.onCardReaderChanged,
    this.quickPairPanel,
    this.hardwareStatusCards,
  });

  final TillCreateOptions options;
  final String? selectedOutletId;
  final String? selectedPosDeviceId;
  final String? selectedScannerId;
  final String? selectedPrinterId;
  final String? selectedCashDrawerId;
  final String? selectedCardReaderId;

  final TextEditingController posDeviceNameController;
  final TextEditingController scannerNameController;
  final TextEditingController printerNameController;
  final TextEditingController cashDrawerNameController;
  final TextEditingController cardReaderNameController;

  final ValueChanged<String?> onPosDeviceChanged;
  final ValueChanged<String?> onScannerChanged;
  final ValueChanged<String?> onPrinterChanged;
  final ValueChanged<String?> onCashDrawerChanged;
  final ValueChanged<String?> onCardReaderChanged;

  final Widget? quickPairPanel;
  final Widget? hardwareStatusCards;

  @override
  Widget build(BuildContext context) {
    // Filter devices based on selected outlet
    final availableDevices = selectedOutletId == null
        ? <TillHardwareDeviceOption>[]
        : options.hardwareDevices
            .where((d) =>
                d.outletId == selectedOutletId &&
                (d.isAssigned == false ||
                    [
                      selectedScannerId,
                      selectedPrinterId,
                      selectedCashDrawerId,
                      selectedCardReaderId
                    ].contains(d.id)))
            .toList(growable: false);

    final posDevices = selectedOutletId == null
        ? <TillPosDeviceOption>[]
        : options.posDevices
            .where((d) =>
                d.outletId == selectedOutletId &&
                (d.isAssigned == false || d.id == selectedPosDeviceId))
            .toList(growable: false);

    final scanners = availableDevices
        .where((d) => d.type.toLowerCase() == 'barcode_scanner')
        .toList();
    final printers = availableDevices
        .where((d) => d.type.toLowerCase() == 'receipt_printer')
        .toList();
    final cashDrawers = availableDevices
        .where((d) => d.type.toLowerCase() == 'cash_drawer')
        .toList();
    final cardReaders = availableDevices
        .where((d) =>
            d.type.toLowerCase() == 'payment_terminal' ||
            d.type.toLowerCase() == 'card_reader')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6A00),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('2',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'Hardware Setup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        const Text(
          'Select or pair your hardware devices.',
          style: TextStyle(color: TenantAdminColors.mutedText),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCombo(
                    label: 'Device Name',
                    value: selectedPosDeviceId,
                    controller: posDeviceNameController,
                    items: posDevices,
                    onChanged: onPosDeviceChanged,
                    icon: Icons.computer,
                    outletId: selectedOutletId,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  const Text('A friendly name to identify this till device.',
                      style: TextStyle(
                          fontSize: 12, color: TenantAdminColors.mutedText)),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildCombo(
                    label: 'Scanner',
                    value: selectedScannerId,
                    controller: scannerNameController,
                    items: scanners,
                    onChanged: onScannerChanged,
                    icon: Icons.qr_code_scanner,
                    outletId: selectedOutletId,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildCombo(
                    label: 'Receipt Printer',
                    value: selectedPrinterId,
                    controller: printerNameController,
                    items: printers,
                    onChanged: onPrinterChanged,
                    icon: Icons.print,
                    outletId: selectedOutletId,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildCombo(
                    label: 'Cash Drawer',
                    value: selectedCashDrawerId,
                    controller: cashDrawerNameController,
                    items: cashDrawers,
                    onChanged: onCashDrawerChanged,
                    icon: Icons.point_of_sale,
                    outletId: selectedOutletId,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildCombo(
                    label: 'Card Reader',
                    value: selectedCardReaderId,
                    controller: cardReaderNameController,
                    items: cardReaders,
                    onChanged: onCardReaderChanged,
                    icon: Icons.credit_card,
                    outletId: selectedOutletId,
                  ),
                ],
              ),
            ),
            if (quickPairPanel != null || hardwareStatusCards != null) ...[
              const SizedBox(width: TenantAdminSpacing.xl),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quickPairPanel != null) quickPairPanel!,
                    if (hardwareStatusCards != null) ...[
                      const SizedBox(height: TenantAdminSpacing.md),
                      hardwareStatusCards!,
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCombo({
    required String label,
    required String? value,
    required TextEditingController controller,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required String? outletId,
  }) {
    final Map<String, dynamic> uniqueMap = {};
    for (final item in items) {
      uniqueMap[item.id as String] = item;
    }
    final uniqueItems = uniqueMap.values.toList();

    final hasValue = uniqueItems.any((item) => (item as dynamic).id == value);
    final safeValue = hasValue ? value : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownMenu<String>(
              key: ValueKey('${label}_$outletId'),
              width: constraints.maxWidth,
              controller: controller,
              initialSelection: safeValue,
              hintText: 'Select $label',
              leadingIcon: Icon(icon, color: TenantAdminColors.mutedText),
              inputDecorationTheme: InputDecorationTheme(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                ),
              ),
              dropdownMenuEntries: uniqueItems.map((e) => DropdownMenuEntry<String>(
                value: (e as dynamic).id as String,
                label: (e as dynamic).name as String,
              )).toList(),
              onSelected: (String? selectedId) {
                onChanged(selectedId);
              },
            ),
          ],
        return DropdownMenu<String>(
          key: ValueKey('${label}_$outletId'),
          width: constraints.maxWidth,
          controller: controller,
          initialSelection: safeValue,
          label: Text(label),
          leadingIcon: Icon(icon, color: TenantAdminColors.mutedText),
          dropdownMenuEntries: uniqueItems
              .map((e) => DropdownMenuEntry<String>(
                    value: (e as dynamic).id as String,
                    label: (e as dynamic).name as String,
                  ))
              .toList(),
          onSelected: (String? selectedId) {
            onChanged(selectedId);
          },
        );
      },
    );
  }
}
