import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerDetailsActions extends StatelessWidget {
  const CustomerDetailsActions({
    super.key,
    required this.canAttach,
    required this.canViewPurchaseHistory,
    required this.canEdit,
    required this.isAttaching,
    required this.attachDisabledReason,
    required this.onAttachToSale,
    required this.onViewPurchaseHistory,
    required this.onEditCustomer,
    required this.onDeactivateCustomer,
    required this.customerIsActive,
  });

  final bool canAttach;
  final bool canViewPurchaseHistory;
  final bool canEdit;
  final bool isAttaching;
  final String? attachDisabledReason;
  final VoidCallback onAttachToSale;
  final VoidCallback onViewPurchaseHistory;
  final VoidCallback onEditCustomer;
  final VoidCallback onDeactivateCustomer;
  final bool customerIsActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: attachDisabledReason ?? 'Attach to Sale',
                child: FilledButton.icon(
                  onPressed: canAttach && !isAttaching ? onAttachToSale : null,
                  icon: isAttaching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: const Text(
                    'Attach to Sale',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFB0A3),
                    disabledForegroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canEdit ? onEditCustomer : null,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06235D),
                  side: const BorderSide(color: Color(0xFFE2E6ED)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (customerIsActive) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeactivateCustomer,
                  icon: const Icon(Icons.block_outlined, size: 16),
                  label: const Text(
                    'Deactivate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0F0),
                    foregroundColor: const Color(0xFFFF3B30),
                    side: const BorderSide(color: Color(0xFFFFD2D2)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (canViewPurchaseHistory) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onViewPurchaseHistory,
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('View Purchase History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF06235D),
              side: const BorderSide(color: Color(0xFFE2E6ED)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
