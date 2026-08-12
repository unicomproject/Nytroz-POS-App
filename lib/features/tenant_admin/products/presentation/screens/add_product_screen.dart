import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_product_providers.dart';
import '../providers/tenant_product_visibility_provider.dart';
import '../widgets/add_product_wizard.dart';

class AddProductScreen extends ConsumerWidget {
  const AddProductScreen({
    super.key,
    this.resumeProductId,
  });

  final String? resumeProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(productAddPageAccessProvider);
    final optionsState = ref.watch(productCreateOptionsProvider);

    if (!hasAccess) {
      return const TenantAdminPageScaffold(
        title: 'Add Product',
        subtitle: 'Enter the basic information for the product.',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to add products.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: 'Add Product',
      subtitle: 'Enter the basic information for the product.',
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

          return AddProductWizard(
            options: options,
            dropdownsEnabled: true,
            canCreate: ref.watch(productAddPageAccessProvider),
            resumeProductId: resumeProductId,
          );
        },
      ),
    );
  }
}
