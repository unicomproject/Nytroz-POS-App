import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

import 'parked_sale_confirmation_summary.dart';
import 'parked_sales_formatters.dart';
import 'parked_sales_states.dart';

Future<void> showParkedSaleCancelDialog(
  BuildContext context,
  WidgetRef ref,
  PosParkedSale sale,
) async {
  final providerContainer = ProviderScope.containerOf(context);
  await showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: providerContainer,
      child: ParkedSaleCancelDialog(sale: sale),
    ),
  );
}

class ParkedSaleCancelDialog extends ConsumerStatefulWidget {
  const ParkedSaleCancelDialog({
    super.key,
    required this.sale,
  });

  final PosParkedSale sale;

  @override
  ConsumerState<ParkedSaleCancelDialog> createState() =>
      _ParkedSaleCancelDialogState();
}

class _ParkedSaleCancelDialogState
    extends ConsumerState<ParkedSaleCancelDialog> {
  final formKey = GlobalKey<FormState>();
  final reason = TextEditingController();
  String? error;

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(posParkedSaleOperationProvider) ==
        PosParkedSaleOperation.cancelling;

    return PopScope(
      canPop: !loading,
      child: AlertDialog(
        title: const Text('Cancel Parked Sale'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancel this parked sale? This action cannot be undone.',
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                ParkedSaleConfirmationSummary(sale: widget.sale),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  key: const Key('cancel-parked-sale-reason'),
                  controller: reason,
                  enabled: !loading,
                  maxLength: 250,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'A cancellation reason is required.';
                    }
                    if (trimmed.length > 250) {
                      return 'Reason must be 250 characters or fewer.';
                    }
                    return null;
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  ParkedSalesInlineError(message: error!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Keep Sale'),
          ),
          PosPrimaryActionButton(
            label: 'Cancel Parked Sale',
            semanticLabel:
                loading ? 'Cancelling parked sale' : 'Cancel Parked Sale',
            compact: true,
            backgroundColor: Theme.of(context).colorScheme.error,
            isLoading: loading,
            onPressed: loading ? null : _cancel,
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => error = null);
    try {
      await ref
          .read(posParkedSaleProvider.notifier)
          .delete(widget.sale.id, reason: reason.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    }
  }
}
