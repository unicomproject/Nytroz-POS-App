import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import 'product_wizard_action_buttons.dart';

/// Sticky Product Flow wizard footer — single place that composes shared CTAs.
///
/// Pass a callback to show an action; leave it null to hide that button.
/// Set [showSkip] on steps 2–6. Step 1 and Step 7 never show Skip.
class WizardActionsFooter extends StatelessWidget {
  const WizardActionsFooter({
    super.key,
    this.onBack,
    this.onCancel,
    this.onSaveDraft,
    this.onSkip,
    this.onContinue,
    this.showSkip = false,
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.continueLabel = 'Continue',
    this.backLabel = 'Back',
  });

  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final bool showSkip;
  final bool isSavingDraft;
  final bool isSubmitting;
  final String continueLabel;
  final String backLabel;

  bool get _busy => isSavingDraft || isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.xl,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;
          final leftActions = <Widget>[
            if (onBack != null)
              ProductWizardBackButton(
                onPressed: _busy ? null : onBack,
                label: backLabel,
              ),
            if (onCancel != null)
              ProductWizardCancelButton(onPressed: _busy ? null : onCancel),
          ];
          final rightActions = <Widget>[
            if (onSaveDraft != null)
              ProductWizardSaveDraftButton(
                onPressed: _busy ? null : onSaveDraft,
                loading: isSavingDraft,
              ),
            if (showSkip && onSkip != null)
              ProductWizardSkipButton(onPressed: _busy ? null : onSkip),
            if (onContinue != null)
              ProductWizardContinueButton(
                onPressed: _busy ? null : onContinue,
                loading: isSubmitting,
                label: continueLabel,
              ),
          ];

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._withGaps(rightActions.reversed.toList(), vertical: true),
                if (leftActions.isNotEmpty) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  ..._withGaps(leftActions, vertical: true),
                ],
              ],
            );
          }

          return Row(
            children: [
              ..._withGaps(leftActions),
              const Spacer(),
              ..._withGaps(rightActions),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> children, {bool vertical = false}) {
    if (children.isEmpty) return const [];
    final spaced = <Widget>[children.first];
    for (var i = 1; i < children.length; i++) {
      spaced
        ..add(
          vertical
              ? const SizedBox(height: TenantAdminSpacing.sm)
              : const SizedBox(width: TenantAdminSpacing.md),
        )
        ..add(children[i]);
    }
    return spaced;
  }
}
