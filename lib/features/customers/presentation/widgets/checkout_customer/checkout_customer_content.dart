import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/checkout_customer_provider.dart';
import 'add_customer_form.dart';
import 'checkout_customer_header.dart';
import 'checkout_customer_keyboards.dart';
import 'customer_mobile_input.dart';

class CheckoutCustomerContent extends StatelessWidget {
  const CheckoutCustomerContent({
    super.key,
    required this.state,
    required this.canCreate,
    required this.canAttach,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onDialCodeChanged,
    required this.onRetrySearch,
    required this.onConfirmFound,
    required this.onBeginCreate,
    required this.onNameChanged,
    required this.onChangeNumber,
    required this.onCreate,
    this.onBack,
    this.onSkip,
  });

  final CheckoutCustomerState state;
  final bool canCreate;
  final bool canAttach;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ValueChanged<String> onDialCodeChanged;
  final VoidCallback onRetrySearch;
  final VoidCallback onConfirmFound;
  final VoidCallback onBeginCreate;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onChangeNumber;
  final VoidCallback onCreate;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final createMode = {
      CheckoutCustomerStage.addCustomer,
      CheckoutCustomerStage.createReady,
      CheckoutCustomerStage.creating,
      CheckoutCustomerStage.createError,
    }.contains(state.stage);

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final isTablet = viewportConstraints.maxWidth >= 768 &&
            viewportConstraints.maxHeight.isFinite &&
            viewportConstraints.maxHeight >= 500;

        Widget buildCardContent(bool isStacked) {
          final leftPanel = Container(
            key: const ValueKey('checkout-customer-left-panel'),
            padding: EdgeInsets.all(
              createMode ? TenantAdminSpacing.lg : TenantAdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              border: Border.all(color: TenantAdminColors.border),
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            ),
            child: createMode
                ? AddCustomerForm(
                    state: state,
                    onChangeNumber: onChangeNumber,
                    onNameChanged: onNameChanged,
                  )
                : CustomerMobileInput(
                    state: state,
                    canCreate: canCreate,
                    canAttach: canAttach,
                    onDialCodeChanged: onDialCodeChanged,
                    onRetrySearch: onRetrySearch,
                    onConfirmFound: onConfirmFound,
                    onBeginCreate: onBeginCreate,
                    isStacked: isStacked,
                  ),
          );

          final rightPanel = Container(
            key: const ValueKey('checkout-customer-right-panel'),
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              border: Border.all(color: TenantAdminColors.border),
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            ),
            child: createMode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomerNameKeyboard(
                        enabled: !state.isBusy,
                        value: state.customerName,
                        onChanged: onNameChanged,
                      ),
                      if (!isStacked)
                        const Spacer()
                      else
                        const SizedBox(height: TenantAdminSpacing.lg),
                      FilledButton(
                        key: const ValueKey('checkout-customer-create'),
                        style: FilledButton.styleFrom(
                          backgroundColor: TenantAdminColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: canCreate &&
                                canAttach &&
                                state.isNameValid &&
                                !state.isBusy
                            ? onCreate
                            : null,
                        child: const Text(
                          'ADD CUSTOMER & CONTINUE',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  )
                : CustomerNumericKeypad(
                    enabled: !state.isBusy,
                    onDigit: onDigit,
                    onBackspace: onBackspace,
                    onClear: onClear,
                    onDialCode: onDialCodeChanged,
                  ),
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckoutCustomerHeader(
                  isCreateMode: createMode,
                  onBack: onBack ?? () => Navigator.of(context).maybePop(),
                  onSkip: onSkip,
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                leftPanel,
                const SizedBox(height: TenantAdminSpacing.lg),
                rightPanel,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckoutCustomerHeader(
                isCreateMode: createMode,
                onBack: onBack ?? () => Navigator.of(context).maybePop(),
                onSkip: onSkip,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: leftPanel),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(
                      flex: 2,
                      child: rightPanel,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (isTablet) {
          final targetHeight = viewportConstraints.maxHeight - 24;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1260,
                  maxHeight: targetHeight,
                  minHeight: targetHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                  padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                  child: buildCardContent(false),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1260),
              child: Container(
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
                  border: Border.all(color: TenantAdminColors.border),
                ),
                padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                child: buildCardContent(true),
              ),
            ),
          ),
        );
      },
    );
  }
}
