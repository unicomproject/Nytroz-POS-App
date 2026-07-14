import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

/// UI-only profile image picker. No Azure Blob Storage (or other file
/// storage) exists in this codebase yet, so the selected file name is kept
/// in memory only and is never uploaded or persisted server-side.
class UserProfileImageUpload extends StatelessWidget {
  const UserProfileImageUpload({
    super.key,
    required this.fileName,
    required this.onChanged,
    this.errorText,
  });

  final String? fileName;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  static const _allowedExtensions = ['jpg', 'jpeg', 'png'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Image',
          style: TenantAdminTextStyles.muted(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        DottedBorderBox(
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              children: [
                Icon(
                  fileName == null
                      ? Icons.cloud_upload_outlined
                      : Icons.image_outlined,
                  size: 32,
                  color: TenantAdminColors.primary,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  fileName ?? 'JPG or PNG, max 2MB',
                  textAlign: TextAlign.center,
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: TenantAdminSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickFile(context),
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: Text(fileName == null ? 'Choose File' : 'Replace'),
                    ),
                    if (fileName != null)
                      TextButton.icon(
                        onPressed: () => onChanged(null),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            errorText!,
            style: const TextStyle(
              color: TenantAdminColors.danger,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final controller = TextEditingController();
    final selected = await showAppDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select profile image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File uploads are not connected to storage yet. '
              'Enter a file name to preview the picker validation.',
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'photo.jpg'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (selected == null || selected.isEmpty || !context.mounted) {
      return;
    }

    final extension = selected.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only JPG or PNG images are supported.'),
        ),
      );
      return;
    }

    onChanged(selected);
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: TenantAdminColors.border,
          width: 1.4,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        color: TenantAdminColors.background,
      ),
      child: child,
    );
  }
}
