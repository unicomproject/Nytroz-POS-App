import 'package:flutter/material.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CloseTillBottomActions extends StatelessWidget {
  const CloseTillBottomActions({
    super.key,
    required this.canCloseTill,
    required this.isLoading,
    required this.onCloseTill,
  });

  final bool canCloseTill;
  final bool isLoading;
  final VoidCallback onCloseTill;

  static const _buttonHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final closeTill = PosPrimaryActionButton(
          label: 'Close Till',
          icon: Icons.lock_outline_rounded,
          onPressed: canCloseTill && !isLoading ? onCloseTill : null,
          isLoading: isLoading,
          compact: true,
          minimumHeight: _buttonHeight,
          backgroundColor: TenantAdminColors.posHomeAccentOrange,
        );

        return SizedBox(width: constraints.maxWidth, child: closeTill);
      },
    );
  }
}
