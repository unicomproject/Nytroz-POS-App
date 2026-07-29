import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_settlement_method.dart';
import 'return_settlement_method_tile.dart';

class ReturnSettlementMethodsSection extends StatelessWidget {
  const ReturnSettlementMethodsSection({
    super.key,
    required this.preview,
    required this.selectedMethodCode,
    required this.onMethodSelected,
  });

  final ReturnCreditPreview preview;
  final String? selectedMethodCode;
  final ValueChanged<String> onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settlement Methods',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnCount =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet ? 2 : 1;

            if (columnCount == 1) {
              return Column(
                children: [
                  for (var index = 0;
                      index < ReturnSettlementMethodOption.options.length;
                      index += 1) ...[
                    if (index > 0)
                      const SizedBox(height: TenantAdminSpacing.md),
                    ReturnSettlementMethodTile(
                      option: ReturnSettlementMethodOption.options[index],
                      selected: selectedMethodCode ==
                          ReturnSettlementMethodOption.options[index].code,
                      enabled: ReturnSettlementMethodOption.options[index]
                          .isAvailableFor(preview),
                      onSelected: () => onMethodSelected(
                        ReturnSettlementMethodOption.options[index].code,
                      ),
                    ),
                  ],
                ],
              );
            }

            return Column(
              children: [
                for (var row = 0;
                    row < ReturnSettlementMethodOption.options.length;
                    row += 2) ...[
                  if (row > 0) const SizedBox(height: TenantAdminSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ReturnSettlementMethodTile(
                          option: ReturnSettlementMethodOption.options[row],
                          selected: selectedMethodCode ==
                              ReturnSettlementMethodOption.options[row].code,
                          enabled: ReturnSettlementMethodOption.options[row]
                              .isAvailableFor(preview),
                          onSelected: () => onMethodSelected(
                            ReturnSettlementMethodOption.options[row].code,
                          ),
                        ),
                      ),
                      if (row + 1 <
                          ReturnSettlementMethodOption.options.length) ...[
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: ReturnSettlementMethodTile(
                            option:
                                ReturnSettlementMethodOption.options[row + 1],
                            selected: selectedMethodCode ==
                                ReturnSettlementMethodOption
                                    .options[row + 1].code,
                            enabled: ReturnSettlementMethodOption
                                .options[row + 1]
                                .isAvailableFor(preview),
                            onSelected: () => onMethodSelected(
                              ReturnSettlementMethodOption
                                  .options[row + 1].code,
                            ),
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
      ],
    );
  }
}
