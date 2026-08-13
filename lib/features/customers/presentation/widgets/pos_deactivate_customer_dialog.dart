import 'package:flutter/material.dart';

import '../../../../shared/presentation/app_modal.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<bool> showPosDeactivateCustomerDialog({
  required BuildContext context,
  required String customerName,
}) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (_) => PosDeactivateCustomerDialog(
      customerName: customerName,
    ),
  );

  return confirmed ?? false;
}

class PosDeactivateCustomerDialog extends StatelessWidget {
  const PosDeactivateCustomerDialog({
    super.key,
    required this.customerName,
  });

  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TenantAdminColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        side: const BorderSide(color: TenantAdminColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DialogHeading(),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                '$customerName will no longer be eligible for new sales.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cancel = OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: TenantAdminColors.bodyText,
                      side: const BorderSide(color: TenantAdminColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                  final deactivate = PosPrimaryActionButton(
                    label: 'Deactivate',
                    leadingIcon: Icons.person_off_outlined,
                    onPressed: () => Navigator.of(context).pop(true),
                    fullWidth: true,
                    compact: true,
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        deactivate,
                        const SizedBox(height: TenantAdminSpacing.sm),
                        cancel,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: deactivate),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeading extends StatelessWidget {
  const _DialogHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TenantAdminColors.warningSurface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: const Icon(
            Icons.person_off_outlined,
            color: TenantAdminColors.posHomeAccentOrange,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Text(
            'Deactivate customer?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded),
          color: TenantAdminColors.mutedText,
        ),
      ],
    );
  }
}
