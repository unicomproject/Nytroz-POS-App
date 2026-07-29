import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_resolution_type.dart';
import 'return_resolution_option_card.dart';

class ReturnResolutionOptions extends StatelessWidget {
  const ReturnResolutionOptions({
    super.key,
    required this.selectedResolution,
    required this.onResolutionSelected,
    this.refundEnabled = true,
    this.exchangeEnabled = true,
  });

  final ReturnResolutionType? selectedResolution;
  final ValueChanged<ReturnResolutionType> onResolutionSelected;
  final bool refundEnabled;
  final bool exchangeEnabled;

  static const _options = [
    _ResolutionOptionData(
      type: ReturnResolutionType.refund,
      title: 'Refund',
      description: 'Refund the amount back to the original payment method.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _ResolutionOptionData(
      type: ReturnResolutionType.exchange,
      title: 'Exchange',
      description: 'Exchange the item for a different product or variation.',
      icon: Icons.sync_alt_rounded,
    ),
  ];

  bool _isEnabled(ReturnResolutionType type) {
    return switch (type) {
      ReturnResolutionType.refund => refundEnabled,
      ReturnResolutionType.exchange => exchangeEnabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < TenantAdminBreakpoints.mobile;

        Widget buildCard(_ResolutionOptionData option) {
          return ReturnResolutionOptionCard(
            type: option.type,
            title: option.title,
            description: option.description,
            icon: option.icon,
            selected: selectedResolution == option.type,
            enabled: _isEnabled(option.type),
            onTap: () => onResolutionSelected(option.type),
          );
        }

        if (stackVertically) {
          return Column(
            children: [
              for (var index = 0; index < _options.length; index++) ...[
                buildCard(_options[index]),
                if (index < _options.length - 1)
                  const SizedBox(height: TenantAdminSpacing.lg),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < _options.length; index++) ...[
              Expanded(child: buildCard(_options[index])),
              if (index < _options.length - 1)
                const SizedBox(width: TenantAdminSpacing.xl),
            ],
          ],
        );
      },
    );
  }
}

class _ResolutionOptionData {
  const _ResolutionOptionData({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final ReturnResolutionType type;
  final String title;
  final String description;
  final IconData icon;
}
