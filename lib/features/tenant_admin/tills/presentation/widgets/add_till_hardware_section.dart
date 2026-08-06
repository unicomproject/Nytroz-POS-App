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
                      selectedPosDeviceId,
                      selectedScannerId,
                      selectedPrinterId,
                      selectedCashDrawerId,
                      selectedCardReaderId
                    ].contains(d.id)))
            .toList(growable: false);

    final posDevices = availableDevices
        .where((d) => d.type.toLowerCase() == 'pos_terminal')
        .toList();
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
                color: TenantAdminColors.secondary,
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
                  _buildDropdown(
                    label: 'Device Name',
                    value: selectedPosDeviceId,
                    items: posDevices,
                    onChanged: onPosDeviceChanged,
                    icon: Icons.computer,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  const Text('A friendly name to identify this till device.',
                      style: TextStyle(
                          fontSize: 12, color: TenantAdminColors.mutedText)),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _buildDropdown(
                    label: 'Scanner',
                    value: selectedScannerId,
                    items: scanners,
                    onChanged: onScannerChanged,
                    icon: Icons.qr_code_scanner,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDropdown(
                    label: 'Receipt Printer',
                    value: selectedPrinterId,
                    items: printers,
                    onChanged: onPrinterChanged,
                    icon: Icons.print,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDropdown(
                    label: 'Cash Drawer',
                    value: selectedCashDrawerId,
                    items: cashDrawers,
                    onChanged: onCashDrawerChanged,
                    icon: Icons.point_of_sale,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDropdown(
                    label: 'Card Reader',
                    value: selectedCardReaderId,
                    items: cardReaders,
                    onChanged: onCardReaderChanged,
                    icon: Icons.credit_card,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<TillHardwareDeviceOption> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final hasValue = items.any((item) => item.id == value);
    final safeValue = hasValue ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TenantAdminColors.mutedText),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('None (Optional)',
              style: TextStyle(color: TenantAdminColors.mutedText)),
        ),
        ...items.map((e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
