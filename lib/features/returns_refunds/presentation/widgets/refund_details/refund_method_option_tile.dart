import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_refund_method.dart';

class RefundMethodOptionTile extends StatelessWidget {
  const RefundMethodOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ReturnRefundMethodOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = option.description.trim();
    final disabledReason = option.disabledReason?.trim() ?? '';
    final subtitle = option.enabled
        ? description
        : (disabledReason.isNotEmpty ? disabledReason : description);

    return Semantics(
      button: true,
      selected: selected,
      label: option.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: option.enabled ? 1 : 0.55,
              child: Row(
                children: [
                  _SelectionIndicator(selected: selected),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Icon(
                    option.icon,
                    color: TenantAdminColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.displayName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: TenantAdminColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? TenantAdminColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? TenantAdminColors.primary : TenantAdminColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}
