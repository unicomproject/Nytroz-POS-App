import 'package:flutter/material.dart';

import '../payment_method_style.dart';

/// Shared parent surface for the Sale Summary and Payment Method panels.
///
/// The workspace owns only visual grouping. Each child panel retains its own
/// data, interaction, responsive-layout and validation responsibilities.
class PaymentMethodWorkspaceCard extends StatelessWidget {
  const PaymentMethodWorkspaceCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('payment-method-workspace-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PaymentMethodStyle.border),
          borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
        ),
        child: child,
      );
}
