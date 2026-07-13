import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class CashPaymentBottomActions extends StatelessWidget {
  const CashPaymentBottomActions({
    super.key,
    required this.canConfirm,
    required this.isLoading,
    required this.onBack,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PosBottomOutlinedButton(
            label: 'Back',
            onPressed: isLoading ? null : onBack,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: PosBottomActionSizes.minHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: canConfirm
                    ? TenantAdminColors.info
                    : TenantAdminColors.background,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  onTap: canConfirm && !isLoading ? onConfirm : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: canConfirm
                              ? Colors.white
                              : TenantAdminColors.mutedText,
                        ),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLoading
                                    ? 'Processing...'
                                    : 'Confirm Cash Payment',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: canConfirm
                                          ? Colors.white
                                          : TenantAdminColors.mutedText,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (!canConfirm && !isLoading)
                                Text(
                                  'Enter exact amount to enable',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: TenantAdminColors.mutedText,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
