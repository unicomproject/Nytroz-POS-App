import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/product_wizard_capabilities.dart';
import '../providers/tenant_product_providers.dart';
import '../providers/tenant_product_visibility_provider.dart';
import '../widgets/add_product_wizard.dart';

class AddProductScreen extends ConsumerWidget {
  const AddProductScreen({
    super.key,
    this.resumeProductId,
    this.resumeLocalDraftId,
    this.duplicateFromProductId,
  });

  final String? resumeProductId;
  final String? resumeLocalDraftId;
  final String? duplicateFromProductId;

  bool get _isDuplicate =>
      duplicateFromProductId != null && duplicateFromProductId!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(productAddPageAccessProvider);
    final optionsState = ref.watch(productCreateOptionsProvider);
    final pageTitle = _isDuplicate ? 'Duplicate Product' : 'Add Product';
    final pageSubtitle = _isDuplicate
        ? 'Create a new product based on an existing one.'
        : 'Enter the basic information for the product.';

    if (!hasAccess) {
      final access = ref.watch(tenantAdminAccessCheckerProvider).asData?.value;
      final missing = access?.missingProductWizardStartCapabilities() ?? const [];
      return TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        child: TenantAdminEmptyState(
          title: 'No access',
          message: missing.isEmpty
              ? 'You do not have permission to add products.'
              : 'You do not have permission to add products. Missing: ${missing.join(', ')}.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: pageTitle,
      subtitle: pageSubtitle,
      scrollable: false,
      headerSpacing: TenantAdminSpacing.sm,
      child: optionsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load product options',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(productCreateOptionsProvider),
        ),
        data: (options) {
          if (options == null) {
            return const TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to add products.',
              icon: Icons.inventory_2_outlined,
            );
          }

          final access = ref.watch(tenantAdminAccessCheckerProvider).asData?.value;
          return AddProductWizard(
            options: options,
            dropdownsEnabled: true,
            canCreate: ref.watch(productAddPageAccessProvider),
            capabilities: access == null
                ? null
                : ProductWizardCapabilities.fromAccess(access),
            resumeProductId: resumeProductId,
            resumeLocalDraftId: resumeLocalDraftId,
            duplicateFromProductId: duplicateFromProductId,
          );
        },
      ),
    );
  }
}
