import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_print_receipt_provider.dart';
import '../payment/payment_panel_card.dart';

class PrinterOptionsCard extends ConsumerWidget {
  const PrinterOptionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(posPrintReceiptOptionsProvider);
    final notifier = ref.read(posPrintReceiptOptionsProvider.notifier);

    final selectedPrinter = posPrintReceiptPrinters.firstWhere(
      (item) => item.id == options.selectedPrinterId,
      orElse: () => posPrintReceiptPrinters.first,
    );
    final selectedPaperSize = posPrintReceiptPaperSizes.firstWhere(
      (item) => item.id == options.selectedPaperSizeId,
      orElse: () => posPrintReceiptPaperSizes.first,
    );

    return PaymentPanelCard(
      title: 'PRINTER OPTIONS',
      icon: Icons.print_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OptionSelectorTile(
            label: 'Printer',
            icon: Icons.print_outlined,
            value: selectedPrinter.label,
            subtitle: selectedPrinter.subtitle,
            onTap: () => _showOptionPicker(
              context: context,
              title: 'Select Printer',
              options: posPrintReceiptPrinters
                  .map((item) => _PickerOption(id: item.id, label: item.label))
                  .toList(growable: false),
              selectedId: options.selectedPrinterId,
              onSelected: notifier.selectPrinter,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _OptionSelectorTile(
            label: 'Paper Size',
            icon: Icons.description_outlined,
            value: selectedPaperSize.label,
            subtitle: selectedPaperSize.subtitle,
            onTap: () => _showOptionPicker(
              context: context,
              title: 'Select Paper Size',
              options: posPrintReceiptPaperSizes
                  .map((item) => _PickerOption(id: item.id, label: item.label))
                  .toList(growable: false),
              selectedId: options.selectedPaperSizeId,
              onSelected: notifier.selectPaperSize,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _OptionSelectorTile(
            label: 'Copies',
            icon: Icons.copy_all_outlined,
            value: '${options.selectedCopies}',
            subtitle: 'Number of copies',
            onTap: () => _showCopiesPicker(
              context: context,
              selectedCopies: options.selectedCopies,
              onSelected: notifier.selectCopies,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: TenantAdminColors.info,
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ensure the printer is connected and loaded with receipt paper.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TenantAdminColors.bodyText,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptionPicker({
    required BuildContext context,
    required String title,
    required List<_PickerOption> options,
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showAppModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.sm,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.md,
                ),
                child: Text(
                  title,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.label),
                  trailing: option.id == selectedId
                      ? const Icon(Icons.check_rounded,
                          color: TenantAdminColors.info)
                      : null,
                  onTap: () => Navigator.of(context).pop(option.id),
                ),
              const SizedBox(height: TenantAdminSpacing.sm),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _showCopiesPicker({
    required BuildContext context,
    required int selectedCopies,
    required ValueChanged<int> onSelected,
  }) async {
    final selected = await showAppModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.sm,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.md,
                ),
                child: Text(
                  'Select Copies',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              for (final copies in posPrintReceiptCopyOptions)
                ListTile(
                  title: Text('$copies'),
                  trailing: copies == selectedCopies
                      ? const Icon(Icons.check_rounded,
                          color: TenantAdminColors.info)
                      : null,
                  onTap: () => Navigator.of(context).pop(copies),
                ),
              const SizedBox(height: TenantAdminSpacing.sm),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }
}

class _PickerOption {
  const _PickerOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _OptionSelectorTile extends StatelessWidget {
  const _OptionSelectorTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.background,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
                child: Icon(icon, color: TenantAdminColors.info, size: 20),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: TenantAdminColors.bodyText,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: TenantAdminColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
