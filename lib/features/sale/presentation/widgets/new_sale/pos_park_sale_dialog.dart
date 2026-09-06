import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../shared/presentation/app_modal.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';

Future<void> showPosParkSaleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required PosNewSaleCartState cart,
}) {
  final permissions = ref.read(effectivePermissionSetProvider);
  if (!PosSalesPermissionVisibility.canShowParkPopup(permissions) ||
      !PosSalesPermissionVisibility.canConfirmPark(permissions)) {
    return Future.value();
  }
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _PosParkSaleDialog(cart: cart),
    ),
  );
}

class _PosParkSaleDialog extends ConsumerStatefulWidget {
  const _PosParkSaleDialog({required this.cart});
  final PosNewSaleCartState cart;

  @override
  ConsumerState<_PosParkSaleDialog> createState() => _PosParkSaleDialogState();
}

class _PosParkSaleDialogState extends ConsumerState<_PosParkSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  PosParkedSale? _successfulSale;
  String? _errorMessage;
  // Guards against a rapid double-tap on Done invoking Navigator.pop twice.
  bool _donePressed = false;

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(posParkedSaleOperationProvider);
    final submitting = operation == PosParkedSaleOperation.creating;

    return PopScope(
      canPop: !submitting,
      child: Dialog(
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.md),
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: TenantAdminColors.surface,
        elevation: TenantAdminSpacing.md,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
          child: SafeArea(
            child: _buildForm(context, submitting),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool submitting) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final showReference =
        PosSalesPermissionVisibility.canShowParkReference(permissions);
    final showNote = PosSalesPermissionVisibility.canShowParkNote(permissions);
    final showExpiry =
        PosSalesPermissionVisibility.canShowParkExpiry(permissions);
    final canConfirm =
        PosSalesPermissionVisibility.canConfirmPark(permissions);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParkDialogHeader(
          submitting: submitting,
          onClose: () => Navigator.of(context).pop(),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: TenantAdminSpacing.lg,
              right: TenantAdminSpacing.lg,
              bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                  ? TenantAdminSpacing.lg
                  : TenantAdminSpacing.md,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showReference) ...[
                    const _ParkReferenceCard(),
                    const SizedBox(height: TenantAdminSpacing.xl),
                  ],
                  if (showNote) ...[
                    Text(
                      'Short Note (Optional)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    TextFormField(
                      key: const Key('park-sale-note'),
                      controller: _noteController,
                      focusNode: _noteFocus,
                      autofocus: true,
                      enabled: !submitting,
                      maxLength: 250,
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Customer will return shortly',
                        counterText: '',
                        filled: true,
                        fillColor: TenantAdminColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                          borderSide: const BorderSide(
                            color: TenantAdminColors.border,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) > 250
                          ? 'Short note must be 250 characters or fewer.'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!submitting && canConfirm) _submit();
                      },
                    ),
                    const SizedBox(height: TenantAdminSpacing.xl),
                  ],
                  if (showExpiry) const _ExpiryInformation(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    _ParkErrorMessage(message: _errorMessage!),
                  ],
                ],
              ),
            ),
          ),
        ),
        _ParkDialogFooter(
          submitting: submitting,
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: canConfirm ? _submit : null,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, PosParkedSale sale) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Sale parked successfully',
            child: Container(
              key: const Key('park-sale-success-icon'),
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: TenantAdminColors.posHomeReturnsCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: TenantAdminColors.posNewSaleAccent,
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Sale parked successfully',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.pageTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Park Reference',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          SelectableText(
            sale.reference,
            key: const Key('park-sale-success-reference'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TenantAdminColors.posNewSaleAccent,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          FilledButton(
            key: const Key('park-sale-success-done'),
            onPressed: _handleDone,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(
                PosPrimaryActionTokens.compactHeight,
              ),
              backgroundColor: TenantAdminColors.posNewSaleAccent,
              foregroundColor: TenantAdminColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final permissions = ref.read(effectivePermissionSetProvider);
    if (!PosSalesPermissionVisibility.canConfirmPark(permissions)) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (ref.read(posParkedSaleOperationProvider) ==
        PosParkedSaleOperation.creating) {
      return;
    }
    setState(() => _errorMessage = null);
    try {
      final sale =
          await ref.read(posParkedSaleProvider.notifier).saveCurrentCart(
                widget.cart,
                referenceDetails: PosParkedSaleReference(
                  referenceName: '',
                  note: _nullableText(_noteController.text),
                ),
              );
      if (!mounted || sale == null) return;
      _noteController.clear();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _safeParkError(error));
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // Only Navigator.pop — no API call, no cart clear. The cart was already
  // cleared on successful park; this just dismisses the confirmation.
  void _handleDone() {
    if (_donePressed) return;
    _donePressed = true;
    Navigator.of(context).pop();
  }
}

class _ParkDialogHeader extends StatelessWidget {
  const _ParkDialogHeader({required this.submitting, required this.onClose});
  final bool submitting;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.xl,
        TenantAdminSpacing.xl,
        TenantAdminSpacing.md,
        TenantAdminSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('park-sale-header-icon'),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(
                color: TenantAdminColors.posNewSaleAccent,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.pause_circle_outline_rounded,
              color: TenantAdminColors.posNewSaleAccent,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Park Sale',
                    style: TenantAdminTextStyles.pageTitle(context)),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Save this sale and continue it later.',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip:
                submitting ? 'Parking sale in progress' : 'Close Park Sale',
            onPressed: submitting ? null : onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ParkReferenceCard extends StatelessWidget {
  const _ParkReferenceCard();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Park Reference',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Container(
          key: const Key('park-sale-reference-field'),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.sm,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Text(
            'Generated automatically after parking',
            style: TenantAdminTextStyles.muted(context),
          ),
        ),
      ],
    );
  }
}

class _ExpiryInformation extends StatelessWidget {
  const _ExpiryInformation();
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('park-sale-expiry-banner'),
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeReturnsCard,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.posNewSaleAccent),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: TenantAdminColors.posNewSaleAccent,
          ),
          SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text('This parked sale will be available for 24 hours.'),
          ),
        ],
      ),
    );
  }
}

class _ParkErrorMessage extends StatelessWidget {
  const _ParkErrorMessage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkDialogFooter extends StatelessWidget {
  const _ParkDialogFooter(
      {required this.submitting,
      required this.onCancel,
      required this.onSubmit});
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.xl,
        TenantAdminSpacing.lg,
        TenantAdminSpacing.xl,
        TenantAdminSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 176,
            child: OutlinedButton(
              key: const Key('park-sale-cancel'),
              onPressed: submitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  PosPrimaryActionTokens.compactHeight,
                ),
                backgroundColor: TenantAdminColors.surface,
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.bodyText),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (onSubmit != null) ...[
            const SizedBox(width: TenantAdminSpacing.md),
            SizedBox(
              width: 220,
              child: FilledButton.icon(
                key: const Key('park-sale-submit'),
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    PosPrimaryActionTokens.compactHeight,
                  ),
                  backgroundColor: TenantAdminColors.posNewSaleAccent,
                  foregroundColor: TenantAdminColors.surface,
                  disabledBackgroundColor: TenantAdminColors.border,
                  disabledForegroundColor: TenantAdminColors.mutedText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                ),
                icon: submitting
                    ? const SizedBox.square(
                        dimension: PosPrimaryActionTokens.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TenantAdminColors.surface,
                        ),
                      )
                    : const Icon(Icons.pause_circle_outline_rounded),
                label: Text(
                  submitting ? 'Parking sale' : 'Park Sale',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _safeParkError(Object error) {
  final message = error.toString().trim();
  return message.isEmpty
      ? 'Unable to park this sale. Please try again.'
      : message;
}
