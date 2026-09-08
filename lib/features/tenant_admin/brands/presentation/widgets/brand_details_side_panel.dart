import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../providers/brand_providers.dart';

String brandApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message']?.toString().trim().isNotEmpty == true) {
      return data['message'].toString();
    }
    return error.message ?? 'Unable to complete the brand request.';
  }
  return error.toString();
}

String formatBrandUpdatedOn(DateTime? value) {
  if (value == null) return '—';
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
  Widget placeholder(IconData icon) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TenantAdminColors.border.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: Icon(icon, size: size * 0.45),
      );
  if (url == null || url.isEmpty) return placeholder(Icons.image_outlined);
  return ClipRRect(
    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_outlined),
    ),
  );
}

class BrandDetailsSidePanel extends ConsumerWidget {
  const BrandDetailsSidePanel({super.key, required this.brandId, this.onClose});

  final String brandId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(brandDetailProvider(brandId));
    return Container(
      key: const Key('brand-details-region'),
      height: double.infinity,
      color: TenantAdminColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Brand Details',
                      style: TenantAdminTextStyles.sectionTitle(context)),
                ),
                IconButton(
                  tooltip: 'Close brand details',
                  onPressed: onClose ??
                      () => ref.read(selectedBrandIdProvider.notifier).state =
                          null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: detail.when(
                loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
                error: (_, __) => TenantAdminErrorState(
                  title: 'Unable to load brand details',
                  message: 'Please try again.',
                  onRetry: () => ref.invalidate(brandDetailProvider(brandId)),
                ),
                data: (brand) => _BrandDetailsContent(brand: brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandDetailsContent extends StatelessWidget {
  const _BrandDetailsContent({required this.brand});
  final Brand brand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailValue(label: 'Brand Name', value: brand.name),
        _DetailValue(label: 'Code', value: brand.code),
        _DetailValue(label: 'Description', value: _dash(brand.description)),
        _DetailValue(label: 'Sort Order', value: '${brand.sortOrder}'),
        Text('Brand Image', style: TenantAdminTextStyles.muted(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        Semantics(
            label: 'Brand image for ${brand.name}',
            child: brandLogoAvatar(brand, size: 96)),
        const SizedBox(height: TenantAdminSpacing.lg),
        Text('Status', style: TenantAdminTextStyles.muted(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        TenantAdminStatusBadge(
          label: brand.isActive ? 'Active' : 'Inactive',
          status: brand.isActive
              ? TenantAdminStatusType.active
              : TenantAdminStatusType.inactive,
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
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TenantAdminTextStyles.muted(context)),
            const SizedBox(height: TenantAdminSpacing.xs),
            SelectableText(value,
                style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

String _dash(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : '—';
