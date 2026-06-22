import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';

class TillActionMenu extends StatelessWidget {
  const TillActionMenu({
    super.key,
    required this.till,
    required this.actions,
  });

  final Till till;
  final List<TillRowActionConfig> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<TillRowActionConfig>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert, color: TenantAdminColors.mutedText),
      itemBuilder: (context) {
        return actions
            .map(
              (action) => PopupMenuItem<TillRowActionConfig>(
                value: action,
                child: Row(
                  children: [
                    Icon(action.icon, size: 18, color: TenantAdminColors.bodyText),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Text(action.label),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      onSelected: (action) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.label} is not available yet.'),
          ),
        );
      },
    );
  }
}
