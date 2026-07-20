import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnReferenceDetailsCard extends StatelessWidget {
  const ReturnReferenceDetailsCard({
    super.key,
    required this.returnReference,
    required this.customerName,
    required this.processedBy,
  });

  final String returnReference;
  final String customerName;
  final String processedBy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          final fields = [
            _MetaField(
              label: 'Return Reference',
              value: returnReference,
              valueColor: TenantAdminColors.primary,
            ),
            _MetaField(
              label: 'Customer',
              value: customerName.isEmpty ? '-' : customerName,
            ),
            _MetaField(
              label: 'Processed By',
              value: processedBy.isEmpty ? '-' : processedBy,
            ),
          ];

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  fields[i],
                  if (i < fields.length - 1)
                    const SizedBox(height: TenantAdminSpacing.md),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i < fields.length - 1)
                  const SizedBox(width: TenantAdminSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}
