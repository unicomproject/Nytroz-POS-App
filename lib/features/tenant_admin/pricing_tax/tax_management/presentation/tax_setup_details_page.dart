import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../application/tax_management_controller.dart';
import '../domain/tax_aggregate.dart';
import 'tax_setup_form_page.dart';
import 'widgets/tax_setup_details_content.dart';

class TaxSetupDetailsPage extends ConsumerWidget {
  const TaxSetupDetailsPage({super.key, required this.taxId});

  final String taxId;

  static const _title = 'Tax Setup Details';
  static const _subtitle =
      'View tax information, rates, history and products using this setup.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(tenantAdminAccessCheckerProvider);
    final detailAsync = ref.watch(taxDetailProvider(taxId));
    final mutation = ref.watch(taxMutationControllerProvider);

    return accessAsync.when(
      loading: () => const TenantAdminPageScaffold(
        title: _title,
        subtitle: _subtitle,
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (_, __) => TenantAdminPageScaffold(
        title: _title,
        subtitle: _subtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: TenantAdminErrorState(
          title: 'Unable to load access rules',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        final visibility = TaxSetupListVisibility.resolve(access: access);
        if (!visibility.showPage) {
          return TenantAdminPageScaffold(
            title: _title,
            subtitle: _subtitle,
            actions: [
              TenantAdminSecondaryButton(
                label: 'Back to List',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            child: const TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view tax setups.',
              icon: Icons.receipt_long_outlined,
            ),
          );
        }

        return detailAsync.when(
          loading: () => TenantAdminPageScaffold(
            title: _title,
            subtitle: _subtitle,
            actions: [
              TenantAdminSecondaryButton(
                label: 'Back to List',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, _) => TenantAdminPageScaffold(
            title: _title,
            subtitle: _subtitle,
            actions: [
              TenantAdminSecondaryButton(
                label: 'Back to List',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            child: TenantAdminErrorState(
              title: 'Unable to load tax setup',
              message: taxApiErrorMessage(error),
              onRetry: () => ref.invalidate(taxDetailProvider(taxId)),
            ),
          ),
          data: (tax) => _TaxDetailsScaffold(
            tax: tax,
            visibility: visibility,
            mutationBusy: mutation.isSubmitting,
          ),
        );
      },
    );
  }
}

class _TaxDetailsScaffold extends ConsumerWidget {
  const _TaxDetailsScaffold({
    required this.tax,
    required this.visibility,
    required this.mutationBusy,
  });

  final TaxSetup tax;
  final TaxSetupListVisibility visibility;
  final bool mutationBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminPageScaffold(
      title: TaxSetupDetailsPage._title,
      subtitle: TaxSetupDetailsPage._subtitle,
      headerSpacing: TenantAdminSpacing.md,
      fillHeight: false,
      actions: [
        TenantAdminSecondaryButton(
          label: 'Back to List',
          icon: Icons.arrow_back,
          onPressed: mutationBusy ? null : () => Navigator.of(context).pop(),
        ),
        if (visibility.showEdit) ...[
          const SizedBox(width: TenantAdminSpacing.sm),
          TenantAdminPrimaryButton(
            label: 'Edit Tax Setup',
            icon: Icons.edit_outlined,
            backgroundColor: TenantAdminColors.posHomeAccentOrange,
            onPressed: mutationBusy
                ? null
                : () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => TaxSetupFormPage(taxId: tax.id),
                      ),
                    );
                    if (changed == true && context.mounted) {
                      ref.invalidate(taxDetailProvider(tax.id));
                      ref.invalidate(taxListProvider);
                    }
                  },
          ),
        ],
        if (visibility.showStatusManage) ...[
          const SizedBox(width: TenantAdminSpacing.sm),
          PopupMenuButton<String>(
            enabled: !mutationBusy,
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'activate') {
                await _activate(context, ref, tax);
              } else if (value == 'deactivate') {
                await _confirmDeactivate(context, ref, tax);
              }
            },
            itemBuilder: (context) => [
              if (tax.status.isActive)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate'),
                )
              else
                const PopupMenuItem(
                  value: 'activate',
                  child: Text('Activate'),
                ),
            ],
          ),
        ],
      ],
      child: TaxSetupDetailsContent(
        tax: tax,
        showProducts: visibility.showViewProducts,
      ),
    );
  }
}

Future<void> _activate(
  BuildContext context,
  WidgetRef ref,
  TaxSetup tax,
) async {
  try {
    await ref.read(taxMutationControllerProvider.notifier).activate(tax.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax setup activated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(taxApiErrorMessage(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _confirmDeactivate(
  BuildContext context,
  WidgetRef ref,
  TaxSetup tax,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Deactivate tax setup?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This tax setup is currently used by ${tax.productCount} products.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Existing products will retain this tax assignment, but the tax will no longer be available for new assignments.',
          ),
          const SizedBox(height: 12),
          const Text('Historical transactions remain unchanged.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Active'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TenantAdminColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );

  if (!context.mounted || confirmed != true) return;

  try {
    await ref.read(taxMutationControllerProvider.notifier).deactivate(tax.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax setup deactivated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(taxApiErrorMessage(error)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
