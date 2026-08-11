import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Shared Product Flow wizard action buttons.
///
/// Define each common CTA once here and reuse via [WizardActionsFooter]
/// (or individually) across Product Flow steps — do not re-implement these
/// buttons inside step screens.

const Color _cancelForeground = Color(0xFF475569);
const Color _cancelBorder = Color(0xFFCBD5E1);

ButtonStyle _outlinedStyle({
  required Color foreground,
  required Color border,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: foreground,
    side: BorderSide(color: border),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    ),
  );
}

ButtonStyle _filledStyle({required Color background}) {
  return ElevatedButton.styleFrom(
    backgroundColor: background,
    foregroundColor: Colors.white,
    disabledBackgroundColor: background.withValues(alpha: 0.45),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    ),
    elevation: 0,
  );
}

Widget _loadingIndicator({required Color color}) {
  return SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}

/// Back — outlined, navigates to the previous wizard step.
class ProductWizardBackButton extends StatelessWidget {
  const ProductWizardBackButton({
    super.key,
    required this.onPressed,
    this.label = 'Back',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: _outlinedStyle(
        foreground: TenantAdminColors.posHomeAccentOrange,
        border: TenantAdminColors.posHomeAccentOrange,
      ),
      icon: const Icon(Icons.arrow_back, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Cancel — outlined gray, exits the wizard (discard confirm handled by caller).
class ProductWizardCancelButton extends StatelessWidget {
  const ProductWizardCancelButton({
    super.key,
    required this.onPressed,
    this.label = 'Cancel',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: _outlinedStyle(
        foreground: _cancelForeground,
        border: _cancelBorder,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Save Draft — outlined accent, persists without advancing.
class ProductWizardSaveDraftButton extends StatelessWidget {
  const ProductWizardSaveDraftButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Save Draft',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = TenantAdminColors.posHomeAccentOrange;
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      style: _outlinedStyle(foreground: accent, border: accent),
      icon: loading
          ? _loadingIndicator(color: accent)
          : const Icon(Icons.save_outlined, size: 18),
      label: Text(
        loading ? 'Saving Draft...' : label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Skip — outlined, advances past an optional step when allowed.
class ProductWizardSkipButton extends StatelessWidget {
  const ProductWizardSkipButton({
    super.key,
    required this.onPressed,
    this.label = 'Skip',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: _outlinedStyle(
        foreground: TenantAdminColors.posHomeAccentOrange,
        border: TenantAdminColors.posHomeAccentOrange,
      ),
      icon: const Icon(Icons.skip_next_outlined, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// Save & Continue — filled accent primary action (Publish on final step).
class ProductWizardSaveAndContinueButton extends StatelessWidget {
  const ProductWizardSaveAndContinueButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Save & Continue',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = TenantAdminColors.posHomeAccentOrange;
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      style: _filledStyle(background: accent),
      icon: loading
          ? _loadingIndicator(color: Colors.white)
          : const Icon(Icons.arrow_forward, size: 18),
      label: Text(
        loading ? 'Saving...' : label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
