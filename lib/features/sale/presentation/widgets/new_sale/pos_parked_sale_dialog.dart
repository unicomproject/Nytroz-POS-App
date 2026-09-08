import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/app_modal.dart';
import '../../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_parked_sales_panel.dart';

export 'pos_parked_sales_panel.dart' show PosParkedSalesPanel;

Future<PosParkedSale?> showPosParkedSaleDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showAppDialog<PosParkedSale>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _PosParkedSalesDialog(),
    ),
  );
}

class _PosParkedSalesDialog extends StatelessWidget {
  const _PosParkedSalesDialog();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.md),
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: TenantAdminColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
          child: PosParkedSalesPanel(
            // showAppDialog pushes on the root navigator — pop the same one.
            onClose: (_) => Navigator.of(context, rootNavigator: true).pop(),
            onRecallSuccess: (_, __, sale) {
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop(sale);
            },
          ),
        ),
      ),
    );
  }
}
