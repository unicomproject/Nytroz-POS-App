import 'package:flutter/material.dart';

import 'wizard_actions_footer.dart';

/// Product wizard footer — thin wrapper over [WizardActionsFooter].
///
/// Prefer this (or [WizardActionsFooter] directly) from the Product Flow shell.
/// Do not re-implement Save & Continue / Back / Save Draft / Skip in step UIs.
class AddProductFooter extends StatelessWidget {
  const AddProductFooter({
    super.key,
    required this.onCancel,
    required this.onSaveDraft,
    required this.onSaveAndContinue,
    this.onBack,
    this.onSkip,
    this.showSkip = false,
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.saveAndContinueLabel = 'Save & Continue',
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSaveAndContinue;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showSkip;
  final bool isSavingDraft;
  final bool isSubmitting;
  final String saveAndContinueLabel;

  @override
  Widget build(BuildContext context) {
    return WizardActionsFooter(
      onBack: onBack,
      onCancel: onCancel,
      onSaveDraft: onSaveDraft,
      onSkip: onSkip,
      onSaveAndContinue: onSaveAndContinue,
      showSkip: showSkip,
      isSavingDraft: isSavingDraft,
      isSubmitting: isSubmitting,
      saveAndContinueLabel: saveAndContinueLabel,
    );
  }
}
