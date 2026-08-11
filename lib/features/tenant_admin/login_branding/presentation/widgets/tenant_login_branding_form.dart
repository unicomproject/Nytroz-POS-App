import 'package:flutter/material.dart';

import '../../../../auth/domain/entities/pos_login_branding.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import 'tenant_login_branding_media_field.dart';

class TenantLoginBrandingForm extends StatelessWidget {
  const TenantLoginBrandingForm({
    super.key,
    required this.formKey,
    required this.systemNameController,
    required this.descriptionController,
    required this.subtitleController,
    required this.colorController,
    required this.backgroundMediaController,
    required this.heroMediaController,
    required this.mode,
    required this.brandName,
    required this.onModeChanged,
    required this.onChanged,
    required this.uploadingBackground,
    required this.uploadingHero,
    required this.onUploadBackground,
    required this.onUploadHero,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController systemNameController;
  final TextEditingController descriptionController;
  final TextEditingController subtitleController;
  final TextEditingController colorController;
  final TextEditingController backgroundMediaController;
  final TextEditingController heroMediaController;
  final PosLoginBackgroundMode mode;
  final String brandName;
  final ValueChanged<PosLoginBackgroundMode> onModeChanged;
  final VoidCallback onChanged;
  final bool uploadingBackground;
  final bool uploadingHero;
  final VoidCallback onUploadBackground;
  final VoidCallback onUploadHero;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Brand identity',
              style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            '$brandName\nLogo and trading name are managed from the tenant profile.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _field(
            controller: systemNameController,
            label: 'System name',
            maxLength: 80,
            validator: (value) => _max(value, 80, 'System name'),
          ),
          _field(
            controller: descriptionController,
            label: 'Description',
            maxLength: 300,
            maxLines: 3,
            validator: (value) => _max(value, 300, 'Description'),
          ),
          _field(
            controller: subtitleController,
            label: 'Login subtitle template',
            helper: 'Supported placeholder: {tenantName}',
            maxLength: 160,
            validator: _subtitle,
          ),
          Text('Background',
              style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          SegmentedButton<PosLoginBackgroundMode>(
            segments: const [
              ButtonSegment(
                value: PosLoginBackgroundMode.color,
                label: Text('COLOR'),
                icon: Icon(Icons.palette_outlined),
              ),
              ButtonSegment(
                value: PosLoginBackgroundMode.image,
                label: Text('IMAGE'),
                icon: Icon(Icons.image_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (value) => onModeChanged(value.first),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _field(
            controller: colorController,
            label: 'Fallback background color',
            helper: 'Use canonical #RRGGBB format.',
            maxLength: 7,
            validator: (value) =>
                RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a color in #RRGGBB format.',
          ),
          if (mode == PosLoginBackgroundMode.image)
            TenantLoginBrandingMediaField(
              controller: backgroundMediaController,
              label: 'Login background image',
              helper: 'Must be tenant-owned POS_LOGIN_BACKGROUND media.',
              uploading: uploadingBackground,
              onUpload: onUploadBackground,
            ),
          TenantLoginBrandingMediaField(
            controller: heroMediaController,
            label: 'Hero image',
            helper: 'Must be tenant-owned POS_LOGIN_HERO media.',
            uploading: uploadingHero,
            onUpload: onUploadHero,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? helper,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static String? _max(String? value, int max, String label) {
    final text = value?.trim() ?? '';
    if (text.length > max) return '$label must be $max characters or fewer.';
    return null;
  }

  static String? _subtitle(String? value) {
    final basic = _max(value, 160, 'Subtitle');
    if (basic != null) return basic;
    if (value == null || value.trim().isEmpty) return null;
    final unsupported = RegExp(r'\{(?!tenantName\})[^}]+\}').hasMatch(value);
    return unsupported ? 'Only {tenantName} is supported.' : null;
  }
}
