import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import 'role_details_side_panel.dart';

Future<void> showRoleDetailsModal(BuildContext context, String roleId) {
  return showAppDialog<void>(
    context: context,
    builder: (context) => RoleDetailsModal(roleId: roleId),
  );
}

class RoleDetailsModal extends StatelessWidget {
  const RoleDetailsModal({super.key, required this.roleId});

  final String roleId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: RoleDetailsSidePanel(
                    roleId: roleId,
                    isModal: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
