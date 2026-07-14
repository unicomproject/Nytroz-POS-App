import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../navigation/inventory_routes.dart';
import '../providers/inventory_providers.dart';
import '../providers/inventory_visibility_provider.dart';
import '../utils/inventory_api_errors.dart';
import '../widgets/stock_in_line_items_panel.dart';
import '../widgets/stock_in_reference_section.dart';

class StockInScreen extends ConsumerWidget {
  const StockInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(stockInVisibilityProvider);
    final outlets = ref.watch(accessibleOutletOptionsProvider);
    final formNotifier = ref.watch(stockInFormProvider.notifier);
    final submitState = ref.watch(stockInSubmitControllerProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Stock In',
        subtitle: 'Receive inventory into an accessible outlet.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Stock In',
        subtitle: 'Receive inventory into an accessible outlet.',
        child: TenantAdminErrorState(
          title: 'Unable to load stock in',
          message: inventoryApiErrorMessage(error),
          onRetry: () => ref.invalidate(stockInVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Stock In',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to receive stock.',
              icon: Icons.move_to_inbox_outlined,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return Stack(
              children: [
                TenantAdminPageScaffold(
                  title: 'Stock In',
                  subtitle: 'Receive inventory into an accessible outlet.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (outlets.isEmpty)
                        const TenantAdminEmptyState(
                          title: 'No accessible outlets',
                          message:
                              'You need outlet access before receiving stock.',
                          icon: Icons.store_outlined,
                        )
                      else ...[
                        StockInReferenceSection(
                          outlets: outlets,
                          fieldErrors: formNotifier.fieldErrors,
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                        StockInLineItemsPanel(
                          fieldErrors: formNotifier.fieldErrors,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                        Align(
                          alignment: isMobile
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: TenantAdminPrimaryButton(
                            label: 'Receive Stock',
                            icon: Icons.inventory_outlined,
                            loading: submitState.isLoading,
                            onPressed: submitState.isLoading
                                ? null
                                : () => _submit(context, ref),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (submitState.isLoading)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(stockInSubmitControllerProvider.notifier).submit();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock received successfully.')),
      );
      context.go(InventoryRoutes.currentStock);
    } catch (error) {
      if (!context.mounted) return;

      if (error is StateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the highlighted fields and try again.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(inventoryApiErrorMessage(error))),
      );
    }
  }
}
