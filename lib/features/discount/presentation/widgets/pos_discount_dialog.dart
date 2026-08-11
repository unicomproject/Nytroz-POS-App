import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../shared/presentation/app_modal.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_cart_discount.dart';
import '../providers/pos_discount_provider.dart';
import 'discount_controller.dart';
import 'discount_item_picker.dart';
import 'discount_sections.dart';
import 'discount_state.dart';

typedef PosDiscountPresentationSubmit = Future<void> Function(
  PosDiscountPresentationState state,
);

Future<void> showPosDiscountDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const PosDiscountDialog(),
    ),
  );
}

class PosDiscountDialog extends ConsumerStatefulWidget {
  const PosDiscountDialog({super.key, this.onSubmit});

  /// Chunk 2 plugs validate -> apply into this boundary. Chunk 1 deliberately
  /// leaves it null in production and never mutates the cart locally.
  final PosDiscountPresentationSubmit? onSubmit;

  @override
  ConsumerState<PosDiscountDialog> createState() => _PosDiscountDialogState();
}

class _PosDiscountDialogState extends ConsumerState<PosDiscountDialog> {
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  late final String _idempotencyKey =
      createPosDiscountIdempotencyKey('discount-intent');

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posNewSaleCartProvider);
    final args = PosDiscountControllerArgs(
      currencyCode: 'LKR',
      subtotal: cart.subtotal,
      itemCount: cart.itemList.fold(0, (sum, item) => sum + item.quantity),
    );
    final state = ref.watch(posDiscountControllerProvider(args));
    final controller = ref.read(posDiscountControllerProvider(args).notifier);
    final authorityAsync = ref.watch(posDiscountCatalogProvider(
      PosDiscountCatalogQuery(
        scope: 'ORDER',
        customerId: cart.selectedCustomer?.customerId,
        quantity: state.currentItemCount.toDouble(),
        cartSubtotal: cart.subtotal.toDouble(),
      ),
    ));
    authorityAsync.whenData((catalog) {
      if (state.maxPercentage != catalog.authority.maxPercentage ||
          state.maxFixedAmount != catalog.authority.maxFixedAmount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) controller.setAuthority(catalog.authority);
        });
      }
    });
    final session = ref.watch(authSessionProvider);
    final canApply =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;

    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom - 24;
    final maxHeight = availableHeight.clamp(360.0, 820.0);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Dialog(
          key: const Key('pos-discount-dialog'),
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1000, maxHeight: maxHeight),
            child: Column(
              children: [
                _DialogHeader(
                  subtitle: state.scope == PosDiscountScope.item
                      ? 'Apply a cashier discount to a selected product'
                      : 'Apply a cashier discount to the current sale',
                  onClose: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: cart.hasDiscount
                      ? _ExistingDiscountGuard(
                          cart: cart,
                          submitting: state.isSubmitting,
                          onRemove: () => _cancel(cart, controller),
                        )
                      : !canApply
                          ? const _PermissionDeniedState()
                          : !cart.hasItems
                              ? const _EmptyCartState()
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final twoColumns =
                                        constraints.maxWidth >= 900;
                                    return SingleChildScrollView(
                                      key: const Key('discount-dialog-scroll'),
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 6, 24, 20),
                                      child: twoColumns
                                          ? Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: _FormColumn(
                                                    cart: cart,
                                                    state: state,
                                                    controller: controller,
                                                    valueController:
                                                        _valueController,
                                                    reasonController:
                                                        _reasonController,
                                                  ),
                                                ),
                                                const SizedBox(width: 18),
                                                Expanded(
                                                  flex: 2,
                                                  child: _SummaryColumn(
                                                      cart: cart, state: state),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _FormColumn(
                                                  cart: cart,
                                                  state: state,
                                                  controller: controller,
                                                  valueController:
                                                      _valueController,
                                                  reasonController:
                                                      _reasonController,
                                                ),
                                                const SizedBox(height: 18),
                                                _SummaryColumn(
                                                    cart: cart, state: state),
                                              ],
                                            ),
                                    );
                                  },
                                ),
                ),
                if (!cart.hasDiscount && canApply && cart.hasItems)
                  _ActionBar(
                    enabled: state.canApply,
                    submitting: state.isSubmitting,
                    onCancel: () => Navigator.of(context).pop(),
                    onApply: () => _submit(state, controller),
                  )
                else
                  _CloseAction(onClose: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    PosDiscountPresentationState state,
    PosDiscountController controller,
  ) async {
    if (!state.canApply) return;
    final callback = widget.onSubmit;
    controller.setSubmitting(true);
    try {
      if (callback != null) {
        await callback(state);
      } else {
        final result = await applyPosDiscount(
          ref: ref,
          valueType:
              state.calculationMethod == PosDiscountCalculationMethod.percentage
                  ? PosDiscountValueType.percentage
                  : PosDiscountValueType.fixedAmount,
          value: state.parsedRequestedValue!,
          isLineDiscount: state.scope == PosDiscountScope.item,
          targetVariantId: state.selectedVariantId,
          cartLineKey: state.selectedCartLineKey,
          reason: state.reasonText,
          idempotencyKey: _idempotencyKey,
        );
        if (!mounted) return;
        if (!result.applied || result.applicationId.isEmpty) {
          controller.setError(StateError(result.messages.isEmpty
              ? 'Discount application was rejected.'
              : result.messages.join(' ')));
          return;
        }
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) controller.setError(error);
    } finally {
      if (mounted) controller.setSubmitting(false);
    }
  }

  Future<void> _cancel(
    PosNewSaleCartState cart,
    PosDiscountController controller,
  ) async {
    final discount = cart.cartDiscount ??
        cart.items.values
            .map((item) => item.discount)
            .whereType<PosCartDiscount>()
            .firstOrNull;
    if (discount?.applicationId == null) {
      controller.setError(StateError(
          'This discount has no canonical application and cannot be removed online.'));
      return;
    }
    controller.setSubmitting(true);
    try {
      await cancelPosDiscount(ref: ref, discount: discount!);
      ref.read(posNewSaleCartProvider.notifier).clearDiscounts();
      ref.invalidate(posCheckoutSummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) controller.setError(error);
    } finally {
      if (mounted) controller.setSubmitting(false);
    }
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.subtitle, required this.onClose});
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 14, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Discount',
                    style: TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('discount-close'),
            tooltip: 'Close Add Discount',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: TenantAdminColors.bodyText),
          ),
        ]),
      );
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.cart,
    required this.state,
    required this.controller,
    required this.valueController,
    required this.reasonController,
  });
  final PosNewSaleCartState cart;
  final PosDiscountPresentationState state;
  final PosDiscountController controller;
  final TextEditingController valueController;
  final TextEditingController reasonController;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DiscountScopeSelector(
              scope: state.scope, onChanged: controller.selectScope),
          if (state.scope == PosDiscountScope.item) ...[
            const SizedBox(height: 18),
            DiscountItemPicker(
              items: cart.itemList,
              selectedItemKey: state.selectedCartLineKey,
              onChanged: (item) => controller.selectCartLine(
                item.product.cartLineKey,
                item.product.variantId,
                item.lineTotal,
              ),
            ),
          ],
          const SizedBox(height: 18),
          DiscountMethodSelector(
            method: state.calculationMethod,
            itemScope: state.scope == PosDiscountScope.item,
            onChanged: controller.selectCalculationMethod,
          ),
          const SizedBox(height: 12),
          DiscountValueField(
            controller: valueController,
            method: state.calculationMethod,
            currencyCode: state.currencyCode,
            errorText: state.valueError,
            onChanged: controller.updateValue,
          ),
          if (state.maxPercentage != null || state.maxFixedAmount != null) ...[
            const SizedBox(height: 7),
            Text(
              state.calculationMethod == PosDiscountCalculationMethod.percentage
                  ? 'Maximum cashier discount: ${state.maxPercentage?.toStringAsFixed(2)}%'
                  : 'Maximum cashier discount: ${state.currencyCode} ${state.maxFixedAmount?.toStringAsFixed(2)}',
              key: const Key('discount-authority-guidance'),
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          DiscountReasonSection(
              controller: reasonController, onChanged: controller.updateReason),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('discount-presentation-message'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(state.errorMessage!,
                  style: const TextStyle(color: Color(0xFF1D4ED8))),
            ),
          ],
        ],
      );
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({required this.cart, required this.state});
  final PosNewSaleCartState cart;
  final PosDiscountPresentationState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedItem(cart);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (state.scope == PosDiscountScope.order)
        DiscountSummaryCard(
          title: 'CURRENT SALE SUMMARY',
          rows: [
            ('Subtotal', formatLkr(cart.subtotal)),
            ('Items', '${state.currentItemCount}'),
          ],
        )
      else
        DiscountSummaryCard(
          key: const Key('discount-selected-item-summary'),
          title: 'SELECTED ITEM SUMMARY',
          rows: selected == null
              ? const [
                  ('Item', 'Select a product'),
                  ('Quantity', '—'),
                  ('Line Total', '—')
                ]
              : [
                  ('Item', selected.product.name),
                  ('Quantity', '${selected.quantity}'),
                  ('Line Total', formatLkr(selected.lineTotal)),
                ],
          icon: Icons.shopping_bag_outlined,
        ),
      const SizedBox(height: 16),
      DiscountPreviewCard(state: state),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Only one cashier discount can be applied to the current sale.',
              style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.enabled,
    required this.submitting,
    required this.onCancel,
    required this.onApply,
  });
  final bool enabled;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: TenantAdminColors.border)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final cancel = OutlinedButton(
            key: const Key('discount-cancel'),
            onPressed: submitting ? null : onCancel,
            style: OutlinedButton.styleFrom(minimumSize: const Size(150, 52)),
            child: const Text('Cancel'),
          );
          final apply = FilledButton.icon(
            key: const Key('discount-apply'),
            onPressed: enabled && !submitting ? onApply : null,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sell_outlined),
            label: const Text('Apply Discount'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(250, 52),
              backgroundColor: TenantAdminColors.posNewSaleAccent,
              disabledBackgroundColor: const Color(0xFFF1F5F9),
            ),
          );
          if (stacked) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: double.infinity, child: apply),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: cancel),
                ]);
          }
          return Row(children: [
            Expanded(child: cancel),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: apply),
          ]);
        }),
      );
}

class _ExistingDiscountGuard extends StatelessWidget {
  const _ExistingDiscountGuard({
    required this.cart,
    required this.submitting,
    required this.onRemove,
  });
  final PosNewSaleCartState cart;
  final bool submitting;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline,
                  color: TenantAdminColors.success, size: 48),
              const SizedBox(height: 14),
              const Text('Discount already applied',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Only one active cashier discount is allowed. Remove it before applying a different discount.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TenantAdminColors.mutedText),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('discount-remove'),
                onPressed: submitting ? null : onRemove,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline),
                label: const Text('Remove Discount'),
                style: FilledButton.styleFrom(
                  backgroundColor: TenantAdminColors.posNewSaleAccent,
                  minimumSize: const Size(220, 50),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _PermissionDeniedState extends StatelessWidget {
  const _PermissionDeniedState();
  @override
  Widget build(BuildContext context) => const _SafeState(
        icon: Icons.lock_outline,
        title: 'Discount permission required',
        message: 'Your account does not have sales.discount.apply permission.',
      );
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();
  @override
  Widget build(BuildContext context) => const _SafeState(
        icon: Icons.remove_shopping_cart_outlined,
        title: 'Cart is empty',
        message: 'Add a product before applying a discount.',
      );
}

class _SafeState extends StatelessWidget {
  const _SafeState(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: TenantAdminColors.mutedText, size: 44),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TenantAdminColors.mutedText)),
          ]),
        ),
      );
}

class _CloseAction extends StatelessWidget {
  const _CloseAction({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
            child: const Text('Close'),
          ),
        ),
      );
}
