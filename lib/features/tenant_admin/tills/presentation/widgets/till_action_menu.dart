import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_row_action.dart';
import '../../domain/entities/till_monitoring.dart';
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

  final TillMonitoringItem till;
  final List<TillRowActionConfig> actions;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuActions = actions
        .where((action) => action.actionId != TillRowActionId.viewDetails)
        .toList(growable: false);
    if (menuActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<TillRowActionConfig>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert, color: TenantAdminColors.mutedText),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 172),
      menuPadding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      itemBuilder: (context) {
        return menuActions
            .map(
              (action) => PopupMenuItem<TillRowActionConfig>(
                value: action,
                child: TenantAdminRowActionMenuItem(
                  icon: action.icon,
                  label: action.label,
                  destructive: action.actionId == TillRowActionId.delete,
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
