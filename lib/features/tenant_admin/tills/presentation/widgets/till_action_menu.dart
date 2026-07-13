import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import '../utils/till_api_errors.dart';
import 'till_delete_dialog.dart';

class TillActionMenu extends ConsumerWidget {
  const TillActionMenu({
    super.key,
    required this.till,
    required this.actions,
    this.onDeleted,
  });

  final Till till;
  final List<TillRowActionConfig> actions;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      onSelected: (action) => _handleAction(context, ref, action),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    TillRowActionConfig action,
  ) async {
    switch (action.actionId) {
      case TillRowActionId.delete:
        await TillDeleteDialog.show(
          context: context,
          ref: ref,
          till: till,
          onDeleted: onDeleted,
        );
      case TillRowActionId.generateActivationCode:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activation code generation is not available yet.'),
            ),
          );
        }
      case TillRowActionId.viewDetails:
        context.go('/tenant-admin/tills/${till.id}');
      case TillRowActionId.edit:
        context.go('/tenant-admin/tills/${till.id}/edit');
    }
  }
}

String tillDeleteErrorMessage(Object error) {
  if (error is DioException) {
    return tillSubmitErrorMessage(
      error,
      const {},
      fallback: 'Unable to deactivate till.',
    );
  }

  return 'Unable to deactivate till.';
}
