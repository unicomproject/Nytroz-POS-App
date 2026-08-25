import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';

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
  Widget build(BuildContext context) => TenantAdminSingleImageUploadCard(
        title: 'Profile Image',
        description: 'Use a clear portrait to help identify this user.',
        fileName: fileName,
        preview: fileName == null ? null : _ProfileImagePreview(fileName: fileName!),
        errorText: errorText,
        onChooseImage: () => _pickFile(context),
        onRemoveImage: fileName == null ? null : () => onChanged(null),
      );

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
            const Text('Enter a JPG or PNG file name for this user profile.'),
            const SizedBox(height: 12),
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

    if (selected == null || selected.isEmpty || !context.mounted) return;

    final extension = selected.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only JPG or PNG images are supported.')),
      );
      return;
    }

    onChanged(selected);
  }
}

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFFFF3EA),
        child: const Icon(
          Icons.person_outline,
          color: Color(0xFFFF6A00),
          size: 34,
        ),
      );
}
