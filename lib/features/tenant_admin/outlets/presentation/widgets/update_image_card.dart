import 'dart:io';

void main() {
  final file = File(r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_image_upload_card.dart');
  
  final newContent = '''import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/outlet_image_upload_provider.dart';

class OutletImageUploadCard extends StatelessWidget {
  const OutletImageUploadCard({super.key, required this.state, required this.onChoose, required this.onReplace, required this.onRemove, required this.onRetry});
  final OutletImageUploadState state;
  final VoidCallback onChoose;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final busy = state.status == OutletImageUploadStatus.uploading || state.status == OutletImageUploadStatus.deleting;
    final hasImage = state.previewBytes != null || state.remoteImageUrl != null;
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(border: Border.all(color: TenantAdminColors.border), borderRadius: BorderRadius.circular(TenantAdminRadius.md), color: Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Outlet Image (optional)', style: TextStyle(fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText)),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text('Upload an image to easily identify this outlet.', style: TenantAdminTextStyles.muted(context)),
        const SizedBox(height: TenantAdminSpacing.lg),
        _buildUploadBox(context, busy),
        const SizedBox(height: TenantAdminSpacing.lg),
        const Text('Image Preview', style: TextStyle(fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText, fontSize: 13)),
        const SizedBox(height: TenantAdminSpacing.sm),
        _preview(context),
        if (state.status == OutletImageUploadStatus.uploading) ...[
          const SizedBox(height: TenantAdminSpacing.md), LinearProgressIndicator(value: state.progress, color: TenantAdminColors.posHomeOrangeEnd), const SizedBox(height: TenantAdminSpacing.xs), Text('Uploading image... \${(state.progress * 100).round()}%', style: TenantAdminTextStyles.muted(context)),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: TenantAdminSpacing.sm), Text(state.errorMessage!, style: const TextStyle(color: Colors.red)), TextButton(onPressed: busy ? null : onRetry, child: const Text('Retry')),
        ],
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: busy ? null : (hasImage ? onReplace : onChoose),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Replace'),
              style: TextButton.styleFrom(foregroundColor: TenantAdminColors.primary),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            TextButton.icon(
              onPressed: busy || !hasImage ? null : onRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            )
          ]
        ),
      ]),
    );
  }

  Widget _buildUploadBox(BuildContext context, bool busy) {
    return Semantics(
      label: 'Outlet image upload',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border, style: BorderStyle.solid), // Should ideally be dashed, but standard Border is solid
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 32, color: TenantAdminColors.mutedText),
            const SizedBox(height: 8),
            Text('Drag and drop an image here', style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text('or', style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : onChoose,
              style: OutlinedButton.styleFrom(
                foregroundColor: TenantAdminColors.posHomeOrangeEnd,
                side: const BorderSide(color: TenantAdminColors.posHomeOrangeEnd),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                minimumSize: const Size(120, 36),
              ),
              child: const Text('Choose File'),
            ),
            const SizedBox(height: 12),
            Text('Supported formats: JPG, PNG\\nMax file size: 2 MB', textAlign: TextAlign.center, style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 11)),
          ]
        )
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final hasImage = state.previewBytes != null || state.remoteImageUrl != null;
    return Semantics(
      label: 'Outlet image preview',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          color: const Color(0xFFF5F5F5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: hasImage
              ? (state.previewBytes != null 
                  ? Image.memory(state.previewBytes!, fit: BoxFit.cover) 
                  : Image.network(state.remoteImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.storefront_outlined, size: 48, color: TenantAdminColors.mutedText))))
              : const Center(child: Icon(Icons.storefront_outlined, size: 48, color: TenantAdminColors.mutedText)),
          ),
        ),
      ),
    );
  }
}
''';

  file.writeAsStringSync(newContent);
  print('Successfully updated outlet_image_upload_card.dart');
}
