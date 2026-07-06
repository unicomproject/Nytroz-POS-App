import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_reason_option.dart';
import 'return_reason_option_tile.dart';

class ReturnReasonOptionsSection extends StatelessWidget {
  const ReturnReasonOptionsSection({
    super.key,
    required this.selectedReasonCode,
    required this.onReasonSelected,
  });

  final String? selectedReasonCode;
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    final gridOptions = ReturnReasonOption.options
        .where((option) => !option.fullWidth)
        .toList(growable: false);
    final fullWidthOptions = ReturnReasonOption.options
        .where((option) => option.fullWidth)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Return Reasons',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnCount =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet ? 2 : 1;

            if (columnCount == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < gridOptions.length; index += 1) ...[
                    if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
                    ReturnReasonOptionTile(
                      option: gridOptions[index],
                      selected: selectedReasonCode == gridOptions[index].code,
                      onSelected: () =>
                          onReasonSelected(gridOptions[index].code),
                    ),
                  ],
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var row = 0; row < gridOptions.length; row += 2) ...[
                  if (row > 0) const SizedBox(height: TenantAdminSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ReturnReasonOptionTile(
                          option: gridOptions[row],
                          selected:
                              selectedReasonCode == gridOptions[row].code,
                          onSelected: () =>
                              onReasonSelected(gridOptions[row].code),
                        ),
                      ),
                      if (row + 1 < gridOptions.length) ...[
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: ReturnReasonOptionTile(
                            option: gridOptions[row + 1],
                            selected: selectedReasonCode ==
                                gridOptions[row + 1].code,
                            onSelected: () =>
                                onReasonSelected(gridOptions[row + 1].code),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        for (final option in fullWidthOptions) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          ReturnReasonOptionTile(
            option: option,
            selected: selectedReasonCode == option.code,
            onSelected: () => onReasonSelected(option.code),
          ),
        ],
      ],
    );
  }
}
