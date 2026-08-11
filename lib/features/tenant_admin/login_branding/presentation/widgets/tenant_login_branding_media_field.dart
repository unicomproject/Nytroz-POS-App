import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class TenantLoginBrandingMediaField extends StatelessWidget {
  const TenantLoginBrandingMediaField({
    super.key,
    required this.label,
    required this.helper,
    required this.controller,
    required this.uploading,
    required this.onUpload,
  });

  final String label;
  final String helper;
  final TextEditingController controller;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: label,
                helperText: helper,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Choose and upload image',
                  onPressed: uploading ? null : onUpload,
                  icon: uploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                ),
              ),
            ),
          ],
        ),
      );
}
