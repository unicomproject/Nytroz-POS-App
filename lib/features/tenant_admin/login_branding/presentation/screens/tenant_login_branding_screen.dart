import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../auth/domain/entities/pos_login_branding.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_login_branding_settings.dart';
import '../providers/tenant_login_branding_provider.dart';
import '../widgets/tenant_login_branding_form.dart';
import '../widgets/tenant_login_branding_preview.dart';

class TenantLoginBrandingScreen extends ConsumerStatefulWidget {
  const TenantLoginBrandingScreen({super.key});

  @override
  ConsumerState<TenantLoginBrandingScreen> createState() =>
      _TenantLoginBrandingScreenState();
}

class _TenantLoginBrandingScreenState
    extends ConsumerState<TenantLoginBrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systemName = TextEditingController();
  final _description = TextEditingController();
  final _subtitle = TextEditingController();
  final _color = TextEditingController();
  final _backgroundMedia = TextEditingController();
  final _heroMedia = TextEditingController();
  PosLoginBackgroundMode _mode = PosLoginBackgroundMode.color;
  TenantLoginBrandingSettings? _settings;
  bool _saving = false;
  bool _initialized = false;
  bool _uploadingBackground = false;
  bool _uploadingHero = false;

  @override
  void dispose() {
    for (final controller in [
      _systemName,
      _description,
      _subtitle,
      _color,
      _backgroundMedia,
      _heroMedia,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantLoginBrandingProvider);
    final data = state.valueOrNull;
    if (data != null && (!_initialized || !identical(data, _settings))) {
      _initialize(data);
    }

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load POS login branding.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(tenantLoginBrandingProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (settings) {
        final content = _content(settings);
        return Material(
          color: const Color(0xFFF5F7FB),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: content,
          ),
        );
      },
    );
  }

  Widget _content(TenantLoginBrandingSettings settings) {
    final width = MediaQuery.sizeOf(context).width;
    final form = TenantLoginBrandingForm(
      formKey: _formKey,
      systemNameController: _systemName,
      descriptionController: _description,
      subtitleController: _subtitle,
      colorController: _color,
      backgroundMediaController: _backgroundMedia,
      heroMediaController: _heroMedia,
      mode: _mode,
      brandName: settings.effective.brandDisplayName,
      onModeChanged: (value) => setState(() => _mode = value),
      onChanged: () => setState(() {}),
      uploadingBackground: _uploadingBackground,
      uploadingHero: _uploadingHero,
      onUploadBackground: () => _uploadMedia(
        'POS_LOGIN_BACKGROUND',
        _backgroundMedia,
      ),
      onUploadHero: () => _uploadMedia(
        'POS_LOGIN_HERO',
        _heroMedia,
      ),
    );
    final preview = TenantLoginBrandingPreview(branding: _preview(settings));

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'POS Login Branding',
            style: TextStyle(
              color: TenantAdminColors.navy,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure the tenant-branded cashier login experience.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          if (width >= 1000)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: TenantAdminSpacing.xl),
                Expanded(child: preview),
              ],
            )
          else ...[
            form,
            const SizedBox(height: TenantAdminSpacing.xl),
            preview,
          ],
          const SizedBox(height: TenantAdminSpacing.xl),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: TenantAdminSpacing.md,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset to defaults'),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: TenantAdminColors.posHomeOrangeEnd,
                  minimumSize: const Size(160, 48),
                ),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save branding'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _initialize(TenantLoginBrandingSettings settings) {
    _initialized = true;
    _settings = settings;
    _systemName.text = settings.systemName ?? settings.effective.systemName;
    _description.text = settings.description ?? settings.effective.description;
    _subtitle.text =
        settings.subtitleTemplate ?? settings.effective.loginSubtitle;
    _color.text =
        settings.backgroundColor ?? settings.effective.backgroundColor;
    _backgroundMedia.text = settings.backgroundMediaAssetId ?? '';
    _heroMedia.text = settings.heroMediaAssetId ?? '';
    _mode = settings.backgroundMode ?? settings.effective.backgroundMode;
  }

  PosLoginBranding _preview(TenantLoginBrandingSettings settings) {
    final tenantName = settings.effective.brandDisplayName;
    return settings.effective.copyWith(
      systemName: _systemName.text.trim(),
      description: _description.text.trim(),
      loginSubtitle:
          _subtitle.text.trim().replaceAll('{tenantName}', tenantName),
      backgroundMode: _mode,
      backgroundColor: _color.text.trim().toUpperCase(),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final success = await ref.read(tenantLoginBrandingProvider.notifier).save(
          UpdateTenantLoginBrandingSettings(
            systemName: _systemName.text.trim(),
            description: _description.text.trim(),
            subtitleTemplate: _subtitle.text.trim(),
            backgroundMode: _mode,
            backgroundColor: _color.text.trim().toUpperCase(),
            backgroundMediaAssetId: _nullable(_backgroundMedia.text),
            heroMediaAssetId: _nullable(_heroMedia.text),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'POS login branding saved.'
            : 'Unable to save POS login branding. Try again.'),
      ),
    );
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    final success =
        await ref.read(tenantLoginBrandingProvider.notifier).reset();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'POS login branding reset to tenant defaults.'
            : 'Unable to reset POS login branding.'),
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _uploadMedia(
    String purpose,
    TextEditingController controller,
  ) async {
    final isBackground = purpose == 'POS_LOGIN_BACKGROUND';
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final extension = file.name.split('.').last.toLowerCase();
    final mimeType = file.mimeType ??
        (extension == 'png'
            ? 'image/png'
            : extension == 'webp'
                ? 'image/webp'
                : 'image/jpeg');
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension) ||
        bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choose a JPG, PNG or WEBP image up to 5 MB.')),
      );
      return;
    }
    setState(() {
      if (isBackground) {
        _uploadingBackground = true;
      } else {
        _uploadingHero = true;
      }
    });
    try {
      final result =
          await ref.read(tenantLoginBrandingProvider.notifier).uploadMedia(
                purpose,
                TenantLoginBrandingMediaInput(
                  bytes: bytes,
                  fileName: file.name,
                  mimeType: mimeType,
                ),
              );
      if (!mounted) return;
      controller.text = result.mediaAssetId;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('$purpose image uploaded. Save branding to apply it.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to upload branding image. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isBackground) {
            _uploadingBackground = false;
          } else {
            _uploadingHero = false;
          }
        });
      }
    }
  }
}
