import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../presentation/layout/tenant_admin_breadcrumb.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/brand.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../providers/brand_providers.dart';

class SelectedBrandLogo {
  const SelectedBrandLogo(this.bytes, this.fileName);
  final Uint8List bytes;
  final String fileName;
}

final brandLogoPickerProvider =
    Provider<Future<SelectedBrandLogo?> Function()>((ref) {
  return () async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return SelectedBrandLogo(await file.readAsBytes(), file.name);
  };
});

class BrandFormScreen extends ConsumerStatefulWidget {
  const BrandFormScreen({super.key, this.brandId});

  final String? brandId;

  bool get isEdit => brandId != null;

  @override
  ConsumerState<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends ConsumerState<BrandFormScreen> {
  static const _maxLogoBytes = 2 * 1024 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  final _description = TextEditingController();
  final Map<String, String> _serverErrors = {};

  String _status = 'ACTIVE';
  int? _rowVersion;
  String? _existingLogoUrl;
  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _loading = false;
  bool _submitting = false;
  bool _dirty = false;
  String? _globalError;
  String? _loadError;
  String? _persistedBrandId;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _code, _sortOrder, _description]) {
      controller.addListener(_markDirty);
    }
    if (widget.isEdit) {
      _loading = true;
      Future<void>.microtask(_loadBrand);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _sortOrder.dispose();
    _description.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_loading && !_dirty && mounted) setState(() => _dirty = true);
  }

  Future<void> _loadBrand() async {
    try {
      final brand =
          await ref.read(brandRepositoryProvider).getBrandById(widget.brandId!);
      if (!mounted) return;
      _loading = true;
      _name.text = brand.name;
      _code.text = brand.code;
      _sortOrder.text = '${brand.sortOrder}';
      _description.text = brand.description ?? '';
      setState(() {
        _status = brand.isActive ? 'ACTIVE' : 'INACTIVE';
        _rowVersion = brand.rowVersion;
        _existingLogoUrl = brand.logoUrl;
        _loading = false;
        _dirty = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Unable to load the Brand. Please try again.';
        });
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _submitting) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your unsaved Brand changes will be lost.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _leave() async {
    if (await _confirmLeave() && mounted) {
      context.go(ProductsSidebarRoutes.brands);
    }
  }

  Future<void> _pickLogo() async {
    final file = await ref.read(brandLogoPickerProvider)();
    if (file == null) return;
    final extension = file.fileName.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
      setState(
          () => _serverErrors['logo'] = 'Choose a JPG, JPEG, or PNG image.');
      return;
    }
    final bytes = file.bytes;
    if (bytes.length > _maxLogoBytes) {
      setState(() => _serverErrors['logo'] = 'Logo must be 2 MB or less.');
      return;
    }
    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.fileName;
      _serverErrors.remove('logo');
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_submitting || _persistedBrandId != null) return;
    setState(() {
      _serverErrors.clear();
      _globalError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    Brand? saved;
    try {
      final input = BrandUpsertInput(
        name: _name.text.trim(),
        code: _code.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        sortOrder: int.parse(_sortOrder.text),
        status: _status,
        expectedRowVersion: widget.isEdit ? _rowVersion : null,
      );
      final repository = ref.read(brandRepositoryProvider);
      saved = widget.isEdit
          ? await repository.updateBrand(widget.brandId!, input)
          : await repository.createBrand(input);
      _rowVersion = saved.rowVersion;
      _persistedBrandId = saved.id;

      if (_logoBytes != null) {
        try {
          await repository.uploadBrandLogo(
              saved.id, _logoBytes!, _logoFileName!);
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _globalError = widget.isEdit
                ? 'Brand updated. Logo replacement failed. You can retry the logo only.'
                : 'Brand created successfully. Logo upload failed. You can retry the logo only.';
            _submitting = false;
            _dirty = false;
          });
          return;
        }
      }
      _completeSuccess();
    } catch (error) {
      if (!mounted) return;
      _applyApiError(error);
      setState(() => _submitting = false);
    }
  }

  Future<void> _retryLogo() async {
    if (_submitting || _persistedBrandId == null || _logoBytes == null) return;
    setState(() {
      _submitting = true;
      _globalError = null;
    });
    try {
      await ref.read(brandRepositoryProvider).uploadBrandLogo(
            _persistedBrandId!,
            _logoBytes!,
            _logoFileName!,
          );
      _completeSuccess();
    } catch (error) {
      if (mounted) {
        setState(() {
          _globalError = _mediaMessage(error);
          _submitting = false;
        });
      }
    }
  }

  void _completeSuccess() {
    ref.invalidate(brandListProvider);
    if (widget.brandId != null) {
      ref.invalidate(brandDetailProvider(widget.brandId!));
    }
    if (!mounted) return;
    setState(() {
      _dirty = false;
      _submitting = false;
    });
    context.go(ProductsSidebarRoutes.brands);
  }

  void _applyApiError(Object error) {
    final body = error is DioException ? error.response?.data : null;
    final root = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final code = root['code']?.toString();
    final details = root['details'];
    if (details is List) {
      for (final detail in details.whereType<Map>()) {
        final field = detail['field']?.toString();
        final message = detail['message']?.toString();
        if (field != null && message != null) _serverErrors[field] = message;
      }
    }
    if (code == 'brand.code_conflict') {
      _serverErrors['brandCode'] = 'This Brand code is already in use.';
    } else if (code == 'brand.slug_conflict') {
      _serverErrors['brandCode'] = 'This code conflicts with another Brand.';
    } else if (code == 'brand.concurrency_conflict' ||
        _serverErrors.containsKey('expectedRowVersion')) {
      _globalError =
          'This Brand was updated by another user. Reload the latest data before saving again.';
    } else {
      _globalError = root['message']?.toString() ??
          'Unable to save the Brand. Please try again.';
    }
    _formKey.currentState?.validate();
  }

  String _mediaMessage(Object error) {
    final body = error is DioException ? error.response?.data : null;
    final code = body is Map ? body['code']?.toString() : null;
    return switch (code) {
      'media.file_size_exceeded' => 'Logo must be 2 MB or less.',
      'media.unsupported_media_type' => 'Choose a JPG, JPEG, or PNG image.',
      'media.validation_failed' => 'The selected image is invalid or corrupt.',
      'media.storage_unavailable' => 'Logo storage is temporarily unavailable.',
      'media.save_failed' => 'The server could not save the logo metadata.',
      'media.permission_denied' ||
      'media.initial_brand_logo_not_authorized' =>
        'You do not have permission to upload this logo.',
      'media.brand_not_found' => 'The Brand is no longer available.',
      _ => 'Logo upload failed. Please try again.',
    };
  }

  String? _required(String? value, String field, int max, String label) {
    if (_serverErrors[field] case final error?) return error;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required.';
    if (text.length > max) return '$label cannot exceed $max characters.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit Brand' : 'Add Brand';
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmLeave() && context.mounted) context.pop();
      },
      child: TenantAdminPageScaffold(
        title: '',
        child: _loading
            ? const TenantAdminLoadingSkeleton(
                key: Key('brand-edit-loading'), rowCount: 6)
            : _loadError != null
                ? TenantAdminErrorState(
                    title: 'Unable to load Brand',
                    message: _loadError!,
                    onRetry: () {
                      setState(() {
                        _loading = true;
                        _loadError = null;
                      });
                      _loadBrand();
                    },
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TenantAdminBreadcrumb(items: [
                          const TenantAdminBreadcrumbItem(label: 'Product'),
                          const TenantAdminBreadcrumbItem(label: 'Brand'),
                          const TenantAdminBreadcrumbItem(
                              label: 'Brand Management'),
                          TenantAdminBreadcrumbItem(label: title),
                        ]),
                        const SizedBox(height: TenantAdminSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TenantAdminTextStyles.pageTitle(context),
                              ),
                            ),
                            TenantAdminSecondaryButton(
                              label: 'Back to List',
                              icon: Icons.arrow_back,
                              onPressed: _submitting ? null : _leave,
                            ),
                          ],
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                        if (_globalError != null)
                          _ErrorBanner(
                              message: _globalError!,
                              onRetry: _persistedBrandId == null
                                  ? null
                                  : _retryLogo),
                        if (_globalError != null)
                          const SizedBox(height: TenantAdminSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                          decoration: BoxDecoration(
                            color: TenantAdminColors.surface,
                            border: Border.all(color: TenantAdminColors.border),
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.lg),
                            boxShadow: TenantAdminShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _field(
                                _name,
                                'Brand Name *',
                                150,
                                (v) => _required(v, 'name', 150, 'Brand Name'),
                                hint: 'Enter brand name',
                                key: const Key('brand-name-field'),
                              ),
                              const SizedBox(height: TenantAdminSpacing.lg),
                              LayoutBuilder(builder: (context, constraints) {
                                final sideBySide = constraints.maxWidth >= 720;
                                final left = Column(
                                  children: [
                                    _field(
                                      _code,
                                      'Code *',
                                      80,
                                      (v) =>
                                          _required(v, 'brandCode', 80, 'Code'),
                                      hint: 'Enter unique code',
                                      helper: 'Unique code for the brand',
                                      key: const Key('brand-code-field'),
                                    ),
                                    const SizedBox(
                                        height: TenantAdminSpacing.lg),
                                    _field(
                                      _sortOrder,
                                      'Sort Order',
                                      null,
                                      (value) {
                                        if (_serverErrors['sortOrder']
                                            case final error?) {
                                          return error;
                                        }
                                        final parsed =
                                            int.tryParse(value?.trim() ?? '');
                                        return parsed == null || parsed < 0
                                            ? 'Enter a whole number of 0 or greater.'
                                            : null;
                                      },
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^-?\d*$'),
                                        ),
                                      ],
                                      helper: 'Lower numbers appear first',
                                      key: const Key('brand-sort-order-field'),
                                    ),
                                  ],
                                );
                                final logo = _LogoPicker(
                                  existingUrl: _existingLogoUrl,
                                  bytes: _logoBytes,
                                  error: _serverErrors['logo'],
                                  onPick: _submitting ? null : _pickLogo,
                                );
                                return sideBySide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: left),
                                          const SizedBox(
                                              width: TenantAdminSpacing.xl),
                                          Expanded(child: logo),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          left,
                                          const SizedBox(
                                              height: TenantAdminSpacing.lg),
                                          logo,
                                        ],
                                      );
                              }),
                              const SizedBox(height: TenantAdminSpacing.lg),
                              _field(
                                _description,
                                'Description',
                                255,
                                (value) {
                                  if (_serverErrors['description']
                                      case final error?) {
                                    return error;
                                  }
                                  return (value?.trim().length ?? 0) > 255
                                      ? 'Description cannot exceed 255 characters.'
                                      : null;
                                },
                                maxLines: 4,
                                hint: 'Enter brand description (optional)',
                                key: const Key('brand-description-field'),
                              ),
                              const SizedBox(height: TenantAdminSpacing.lg),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: _statusDropdown(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: TenantAdminSpacing.md,
                          runSpacing: TenantAdminSpacing.sm,
                          children: [
                            TenantAdminSecondaryButton(
                                label: 'Cancel',
                                icon: Icons.close,
                                onPressed: _submitting ? null : _leave),
                            TenantAdminPrimaryButton(
                                key: const Key('save-brand-button'),
                                label: 'Save Brand',
                                icon: Icons.save_outlined,
                                loading: _submitting,
                                onPressed:
                                    _persistedBrandId != null ? null : _save),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, int? maxLength,
      String? Function(String?) validator,
      {int maxLines = 1,
      TextInputType? keyboardType,
      String? hint,
      String? helper,
      List<TextInputFormatter>? inputFormatters,
      Key? key}) {
    final multiline = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          key: key,
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: !_submitting && _persistedBrandId == null,
          buildCounter: maxLength == null
              ? null
              : (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) =>
                  Text(
                    '$currentLength / $maxLength',
                    style: TenantAdminTextStyles.muted(context)
                        .copyWith(fontSize: 11),
                  ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            helperText: helper,
            helperStyle: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
            ),
            filled: true,
            fillColor: TenantAdminColors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: multiline ? TenantAdminSpacing.lg : 13,
            ),
            border: _inputBorder(TenantAdminColors.border),
            enabledBorder: _inputBorder(TenantAdminColors.border),
            focusedBorder: _inputBorder(TenantAdminColors.primary, width: 1.5),
            errorBorder: _inputBorder(TenantAdminColors.danger),
            focusedErrorBorder:
                _inputBorder(TenantAdminColors.danger, width: 1.5),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    Widget option(String label, Color color) => Row(
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(label),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status *',
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        DropdownButtonFormField<String>(
          key: const Key('brand-status-field'),
          initialValue: _status,
          decoration: InputDecoration(
            filled: true,
            fillColor: TenantAdminColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: 13,
            ),
            border: _inputBorder(TenantAdminColors.border),
            enabledBorder: _inputBorder(TenantAdminColors.border),
            focusedBorder: _inputBorder(TenantAdminColors.primary, width: 1.5),
            errorBorder: _inputBorder(TenantAdminColors.danger),
            errorText: _serverErrors['status'],
          ),
          items: [
            DropdownMenuItem(
              value: 'ACTIVE',
              child: option('Active', TenantAdminColors.success),
            ),
            DropdownMenuItem(
              value: 'INACTIVE',
              child: option('Inactive', TenantAdminColors.mutedText),
            ),
          ],
          onChanged: _submitting
              ? null
              : (value) => setState(() {
                    _status = value!;
                    _dirty = true;
                  }),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker(
      {required this.existingUrl,
      required this.bytes,
      required this.error,
      required this.onPick});
  final String? existingUrl;
  final Uint8List? bytes;
  final String? error;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    Widget preview = const Icon(Icons.image_outlined,
        size: 42, color: TenantAdminColors.mutedText);
    if (bytes != null) {
      preview = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      );
    } else if (existingUrl?.trim().isNotEmpty == true) {
      preview = Image.network(existingUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand Logo',
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Semantics(
          label: 'Brand Logo. Optional. JPG, JPEG, or PNG, maximum 2 MB.',
          button: true,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Container(
              width: double.infinity,
              height: 232,
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: BoxDecoration(
                color: TenantAdminColors.subtleBackground,
                border: Border.all(
                  width: 1.5,
                  color: error == null
                      ? TenantAdminColors.border
                      : TenantAdminColors.danger,
                ),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    key: const Key('brand-logo-preview'),
                    width: 72,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                      child: preview,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Text(
                    bytes == null && existingUrl == null
                        ? 'Upload Logo'
                        : 'Change Logo',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  const Text(
                    'JPG, JPEG, or PNG · Maximum 2 MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TenantAdminColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Material(
        color: TenantAdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          child: Row(children: [
            const Icon(Icons.info_outline, color: TenantAdminColors.danger),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry Logo')),
          ]),
        ),
      );
}
