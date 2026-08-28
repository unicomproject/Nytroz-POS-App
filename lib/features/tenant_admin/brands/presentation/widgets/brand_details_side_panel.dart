import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../providers/brand_providers.dart';

String brandApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      final code = data['code']?.toString();
      if (code == 'brand.duplicate_code') {
        return 'Brand code already exists.';
      }
    }

    return error.message ?? 'Unable to save brand.';
  }

  return error.toString();
}

String deriveBrandCode(String name) {
  final normalized = name
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return normalized.isEmpty ? 'BRAND' : normalized;
}

String formatBrandUpdatedOn(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute $period';
}

Widget brandLogoAvatar(Brand brand, {double size = 40}) {
  final url = brand.logoUrl?.trim();
  if (url == null || url.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Icon(Icons.image_outlined, size: size * 0.45),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        child: Icon(Icons.broken_image_outlined, size: size * 0.45),
      ),
    ),
  );
}

Future<void> openBrandDetailsPanel({
  required BuildContext context,
  Brand? existing,
  required bool canSave,
}) {
  final isMobile =
      MediaQuery.sizeOf(context).width < TenantAdminBreakpoints.smallTablet;

  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.95,
        child: BrandDetailsSidePanel(
          existing: existing,
          canSave: canSave,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close brand details',
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: TenantAdminColors.surface,
          elevation: 8,
          child: SizedBox(
            width: 420,
            height: double.infinity,
            child: BrandDetailsSidePanel(
              existing: existing,
              canSave: canSave,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    },
  );
}

class BrandDetailsSidePanel extends ConsumerStatefulWidget {
  const BrandDetailsSidePanel({
    super.key,
    this.existing,
    required this.canSave,
    required this.onClose,
  });

  final Brand? existing;
  final bool canSave;
  final VoidCallback onClose;

  @override
  ConsumerState<BrandDetailsSidePanel> createState() =>
      _BrandDetailsSidePanelState();
}

class _BrandDetailsSidePanelState extends ConsumerState<BrandDetailsSidePanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;
  late String _status;
  bool _codeEditedManually = false;
  bool _saving = false;
  Uint8List? _pendingLogoBytes;
  String? _pendingLogoFileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _codeController = TextEditingController(text: widget.existing?.code ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _sortOrderController = TextEditingController(
      text: '${widget.existing?.sortOrder ?? 0}',
    );
    _status = widget.existing?.status.toUpperCase() ?? 'ACTIVE';
    _codeEditedManually = widget.existing != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEdit ? 'Brand Details' : 'Add Brand',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _saving ? null : widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: widget.canSave && !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Brand Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Brand name is required.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (!_codeEditedManually) {
                        _codeController.text = deriveBrandCode(value);
                      }
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _codeController,
                    enabled: widget.canSave && !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Code *',
                      helperText: 'Unique code for the brand',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Brand code is required.';
                      }
                      return null;
                    },
                    onChanged: (_) => _codeEditedManually = true,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: widget.canSave && !_saving,
                    maxLines: 3,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _sortOrderController,
                    enabled: widget.canSave && !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      helperText: 'Lower numbers appear first',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null) {
                        return 'Enter a whole number.';
                      }
                      if (parsed < 0) {
                        return 'Sort order cannot be negative.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TenantAdminSingleImageUploadCard(
                    title: 'Brand Logo',
                    description:
                        'Use a clear brand logo that is easy to recognise.',
                    fileName: _pendingLogoFileName ??
                        ((_pendingLogoBytes != null ||
                                (widget.existing?.hasLogo ?? false))
                            ? 'Current brand logo'
                            : null),
                    preview: _pendingLogoBytes != null ||
                            (widget.existing?.hasLogo ?? false)
                        ? _buildLogoPreview()
                        : null,
                    enabled: widget.canSave && !_saving,
                    onChooseImage: _pickLogo,
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: !widget.canSave || _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: TenantAdminColors.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onClose,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: TenantAdminPrimaryButton(
                  label: _saving ? 'Saving...' : 'Save Brand',
                  onPressed: !widget.canSave || _saving ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPreview() {
    if (_pendingLogoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Image.memory(
          _pendingLogoBytes!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.existing != null) {
      return brandLogoAvatar(widget.existing!, size: 72);
    }

    return brandLogoAvatar(
      const Brand(id: '', code: '', name: '', status: 'ACTIVE'),
      size: 72,
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingLogoBytes = bytes;
      _pendingLogoFileName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final input = BrandUpsertInput(
      code: _codeController.text,
      name: _nameController.text,
      status: _status,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sortOrder: int.parse(_sortOrderController.text.trim()),
    );

    try {
      await ref.read(brandSaveControllerProvider.notifier).save(
            brandId: widget.existing?.id,
            input: input,
            logoBytes: _pendingLogoBytes,
            logoFileName: _pendingLogoFileName,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Brand created successfully.'
                : 'Brand updated successfully.',
          ),
        ),
      );
      widget.onClose();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorMessage = brandApiErrorMessage(error);
      });
    }
  }
}
