import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_refund_method.dart';
import 'refund_method_option_tile.dart';

class RefundMethodSection extends StatelessWidget {
  const RefundMethodSection({
    super.key,
    required this.methods,
    required this.selectedMethodCode,
    required this.onMethodSelected,
    this.isLoading = false,
  });

  final List<ReturnRefundMethodOption> methods;
  final String? selectedMethodCode;
  final ValueChanged<ReturnRefundMethodOption> onMethodSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refund Method',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (methods.isEmpty)
          Text(
            'No refund methods are available for this return.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          )
        else
          for (var index = 0; index < methods.length; index++) ...[
            RefundMethodOptionTile(
              option: methods[index],
              selected: selectedMethodCode != null &&
                  methods[index].code.trim().toUpperCase() ==
                      selectedMethodCode!.trim().toUpperCase(),
              onTap: methods[index].enabled
                  ? () => onMethodSelected(methods[index])
                  : null,
            ),
            if (index < methods.length - 1)
              const SizedBox(height: TenantAdminSpacing.sm),
          ],
      ],
    );
  }
}
