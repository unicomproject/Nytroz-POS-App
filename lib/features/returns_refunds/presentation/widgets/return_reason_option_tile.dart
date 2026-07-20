import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_reason_option.dart';

class ReturnReasonOptionTile extends StatelessWidget {
  const ReturnReasonOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final ReturnReasonOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
        child: Row(
          children: [
            RadioGroup<String>(
              groupValue: selected ? option.code : null,
              onChanged: (_) => onSelected(),
              child: Radio<String>(
                value: option.code,
                activeColor: TenantAdminColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (option.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!.trim(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TenantAdminColors.mutedText,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
