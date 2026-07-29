import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_settlement_method.dart';

class ReturnSettlementMethodTile extends StatelessWidget {
  const ReturnSettlementMethodTile({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ReturnSettlementMethodOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              border: Border.all(
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? TenantAdminShadows.card : null,
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: option.iconColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      child: Icon(
                        option.icon,
                        color: option.iconColor,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: TenantAdminSpacing.xs),
                          Text(
                            option.description,
                            style: TenantAdminTextStyles.muted(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: TenantAdminColors.primary,
                      size: 22,
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
