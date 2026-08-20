import 'package:flutter/material.dart';

import 'wizard_actions_footer.dart';

/// Thin legacy alias over [WizardActionsFooter].
///
/// Prefer [WizardActionsFooter] from the Product Wizard shell.
/// Kept so older imports keep compiling until a cleanup chunk removes them.
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
