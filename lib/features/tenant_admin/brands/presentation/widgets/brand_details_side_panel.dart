import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
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
