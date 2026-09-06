import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

import 'parked_sale_confirmation_summary.dart';
import 'parked_sales_formatters.dart';
import 'parked_sales_states.dart';

typedef PosParkedSaleRecallHandler = void Function(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
);

Future<void> beginParkedSaleRecall(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
  PosParkedSaleRecallHandler onRecallSuccess,
) async {
  if (ref.read(posNewSaleCartProvider).hasItems) {
    await showAppDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Cannot Recall Sale'),
        content: Text(
          'Complete, clear or park the current cart before recalling another sale.',
        ),
      ),
    );
    return;
  }
  try {
    final recalled =
        await ref.read(posParkedSaleProvider.notifier).recall(sale.id);
    // null = duplicate in-flight recall; cart already restored by notifier.
    if (recalled == null) return;

    // After recall, the parked list drops this row and the Recall button's
    // context is often unmounted. Still notify the parent so Parked Sales
    // can dismiss / navigate — do not gate success on the row context.
    if (context.mounted) {
      surfaceRecallValidationMessages(context, ref);
    }
    // Parent handlers capture a stable panel/dialog/screen context and ignore
    // this row context, which is often unmounted after the hold leaves the list.
    // ignore: use_build_context_synchronously
    onRecallSuccess(context, ref, recalled);
  } catch (error) {
    // Failure: keep Parked Sales open; only surface the error if we can.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }
}

void surfaceRecallValidationMessages(BuildContext context, WidgetRef ref) {
  final messages = ref
          .read(posParkedSaleProvider.notifier)
          .lastRecall
          ?.checkoutSummary
          .validationMessages ??
      const <String>[];
  if (messages.isEmpty) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(messages.join('\n'))));
}

class ParkedSaleRecallDialog extends ConsumerStatefulWidget {
  const ParkedSaleRecallDialog({
    super.key,
    required this.sale,
  });

  final PosParkedSale sale;

  @override
  ConsumerState<ParkedSaleRecallDialog> createState() =>
      _ParkedSaleRecallDialogState();
}

class _ParkedSaleRecallDialogState
    extends ConsumerState<ParkedSaleRecallDialog> {
  String? error;

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(posParkedSaleOperationProvider) ==
        PosParkedSaleOperation.recalling;

    return PopScope(
      canPop: !loading,
      child: AlertDialog(
        key: const ValueKey('recall-sale-dialog'),
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: TenantAdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        title: Text(
          'Recall Sale',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Return this parked sale to the active cart?'),
            const SizedBox(height: TenantAdminSpacing.md),
            ParkedSaleConfirmationSummary(sale: widget.sale),
            if (error != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              ParkedSalesInlineError(message: error!),
            ],
          ],
        ),
        actions: [
          OutlinedButton(
            key: const ValueKey('recall-sale-cancel'),
            onPressed: loading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size(104, PosPrimaryActionTokens.compactHeight),
              foregroundColor: TenantAdminColors.bodyText,
              side: const BorderSide(color: TenantAdminColors.bodyText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            key: const ValueKey('recall-sale-confirm'),
            onPressed: loading ? null : _recall,
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size(136, PosPrimaryActionTokens.compactHeight),
              backgroundColor: TenantAdminColors.posNewSaleAccent,
              foregroundColor: TenantAdminColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TenantAdminColors.surface,
                    ),
                  )
                : const Icon(Icons.restore_rounded),
            label: Text(
              loading ? 'Recalling sale' : 'Recall Sale',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recall() async {
    setState(() => error = null);
    try {
      final sale =
          await ref.read(posParkedSaleProvider.notifier).recall(widget.sale.id);
      if (mounted && sale != null) Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    }
  }
}
