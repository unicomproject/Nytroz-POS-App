import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<PosParkedSale?> showPosParkedSaleDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final container = ProviderScope.containerOf(context, listen: false);

  return showAppDialog<PosParkedSale>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const _PosParkedSaleDialog(),
    ),
  );
}

class _PosParkedSaleDialog extends ConsumerWidget {
  const _PosParkedSaleDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parkedSales = ref.watch(posParkedSaleProvider);

    return SafeArea(
      child: Dialog(
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 560,
            maxHeight: 600,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recall Parked Sale',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: TenantAdminColors.bodyText,
                                  fontWeight: FontWeight.w900,
                                ) ??
                            const TextStyle(
                              color: TenantAdminColors.bodyText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Flexible(
                  child: parkedSales.when(
                    loading: () => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const _ParkedSaleEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Parked sales could not be loaded',
                      message: 'Close this window and try again.',
                    ),
                    data: (sales) {
                      if (sales.isEmpty) {
                        return const _ParkedSaleEmptyState(
                          icon: Icons.pause_circle_outline_rounded,
                          title: 'No parked sales',
                          message: 'Saved parked sales will appear here.',
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(
                          height: TenantAdminSpacing.sm,
                        ),
                        itemBuilder: (context, index) {
                          return _ParkedSaleTile(sale: sales[index]);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParkedSaleTile extends ConsumerWidget {
  const _ParkedSaleTile({required this.sale});

  final PosParkedSale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: TenantAdminColors.bodyText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        sale.identityLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Text(
                  formatLkr(sale.total),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Items: ${sale.itemPreview}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (sale.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                sale.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.sm),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.xs,
              children: [
                _MetaChip(
                  icon: Icons.shopping_bag_outlined,
                  label: '${sale.itemCount} items',
                ),
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: _formatDateTime(sale.createdAt),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PosPrimaryActionButton(
                    onPressed: () async {
                      final recalled = await ref
                          .read(posParkedSaleProvider.notifier)
                          .recall(sale.id);
                      if (context.mounted) {
                        Navigator.of(context).pop(recalled);
                      }
                    },
                    icon: Icons.restore_rounded,
                    label: 'Recall',
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                IconButton.outlined(
                  tooltip: 'Delete parked sale',
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: TenantAdminColors.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Parked Sale?'),
          content: Text('Delete ${sale.reference}? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(posParkedSaleProvider.notifier).delete(sale.id);
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _ParkedSaleEmptyState extends StatelessWidget {
  const _ParkedSaleEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: TenantAdminColors.offline),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date = '${local.year}-${_two(local.month)}-${_two(local.day)}';
  final time = '${_two(local.hour)}:${_two(local.minute)}';
  return '$date $time';
}

String _two(int value) => value.toString().padLeft(2, '0');
