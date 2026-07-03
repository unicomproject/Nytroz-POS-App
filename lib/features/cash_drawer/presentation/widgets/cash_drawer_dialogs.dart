import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_provider.dart';

Future<bool?> showCashOutDialog({
  required BuildContext context,
  required WidgetRef ref,
  required double maxAmount,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _CashMovementDialog(
        title: 'Cash Out / Drop',
        submitLabel: 'Record Drop',
        isCashOut: true,
        maxAmount: maxAmount,
      ),
    ),
  );
}

Future<bool?> showCloseTillDialog({
  required BuildContext context,
  required WidgetRef ref,
  required double expectedCash,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _CloseTillDialog(expectedCash: expectedCash),
    ),
  );
}

class _CashMovementDialog extends ConsumerStatefulWidget {
  const _CashMovementDialog({
    required this.title,
    required this.submitLabel,
    required this.isCashOut,
    this.maxAmount,
  });

  final String title;
  final String submitLabel;
  final bool isCashOut;
  final double? maxAmount;

  @override
  ConsumerState<_CashMovementDialog> createState() =>
      _CashMovementDialogState();
}

class _CashMovementDialogState extends ConsumerState<_CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final note = _noteController.text.trim();
    final controller = ref.read(cashDrawerProvider.notifier);

    final success = widget.isCashOut
        ? await controller.recordCashOut(amount: amount, note: note)
        : await controller.recordCashIn(amount: amount, note: note);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = ref.read(cashDrawerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(cashDrawerProvider).isSubmitting;

    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
                if (widget.isCashOut && widget.maxAmount != null) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  Text(
                    'Available: ${formatCashDrawerAmount(widget.maxAmount!)}',
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.lg),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '${formatLkrInputPrefix()} ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    if (raw.isEmpty) {
                      return 'Amount is required';
                    }

                    final amount = double.tryParse(raw);
                    if (amount == null || amount <= 0) {
                      return 'Amount must be greater than zero';
                    }

                    if (widget.isCashOut &&
                        widget.maxAmount != null &&
                        amount > widget.maxAmount!) {
                      return 'Amount cannot exceed available cash';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason / note (optional)',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.submitLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseTillDialog extends ConsumerStatefulWidget {
  const _CloseTillDialog({required this.expectedCash});

  final double expectedCash;

  @override
  ConsumerState<_CloseTillDialog> createState() => _CloseTillDialogState();
}

class _CloseTillDialogState extends ConsumerState<_CloseTillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countedController = TextEditingController();

  @override
  void dispose() {
    _countedController.dispose();
    super.dispose();
  }

  double? get _countedCash {
    final raw = _countedController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  double? get _difference {
    final counted = _countedCash;
    if (counted == null) {
      return null;
    }
    return counted - widget.expectedCash;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final counted = double.parse(_countedController.text.trim());
    final success = await ref
        .read(cashDrawerProvider.notifier)
        .submitCloseTill(countedCash: counted);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      final message = ref.read(cashDrawerProvider).closeTillMessage;
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    final error = ref.read(cashDrawerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(cashDrawerProvider).isSubmitting;
    final difference = _difference;

    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Close Till',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  'Expected cash: ${formatCashDrawerAmount(widget.expectedCash)}',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                TextFormField(
                  controller: _countedController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Counted cash *',
                    prefixText: '${formatLkrInputPrefix()} ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    if (raw.isEmpty) {
                      return 'Counted cash is required';
                    }

                    final amount = double.tryParse(raw);
                    if (amount == null || amount < 0) {
                      return 'Enter a valid counted amount';
                    }

                    return null;
                  },
                ),
                if (difference != null) ...[
                  const SizedBox(height: TenantAdminSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TenantAdminSpacing.md),
                    decoration: BoxDecoration(
                      color: difference == 0
                          ? const Color(0xFFEFFAF3)
                          : difference > 0
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFEF2F2),
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                      border: Border.all(color: TenantAdminColors.border),
                    ),
                    child: Text(
                      difference == 0
                          ? 'Difference: balanced'
                          : difference > 0
                              ? 'Over: ${formatCashDrawerAmount(difference)}'
                              : 'Short: ${formatCashDrawerAmount(difference.abs())}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: difference == 0
                                ? TenantAdminColors.success
                                : difference > 0
                                    ? TenantAdminColors.info
                                    : TenantAdminColors.danger,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
