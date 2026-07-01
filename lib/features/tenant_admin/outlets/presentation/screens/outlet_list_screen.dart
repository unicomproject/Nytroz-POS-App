import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_api_errors.dart';
import '../widgets/outlet_list_panel.dart';
import '../widgets/outlet_metric_cards.dart';

class OutletListScreen extends ConsumerWidget {
  const OutletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(outletListVisibilityProvider);
    final outletsState = ref.watch(outletListProvider);
    final statusFilter = ref.watch(outletStatusFilterProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlets',
          message: outletLoadErrorMessage(error),
          onRetry: () => ref.invalidate(outletListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Outlets',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view outlets.',
            ),
          );
        }

        return outletsState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Outlets' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage the places where your business sells.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Outlets',
            subtitle: 'Manage the places where your business sells.',
            child: TenantAdminErrorState(
              title: 'Unable to load outlets',
              message: outletLoadErrorMessage(error),
              onRetry: () => ref.refresh(outletListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Outlets',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view outlets.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Outlets' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage the places where your business sells.'
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSummarySection) ...[
                        OutletMetricCards(
                          summary: result.summary,
                          compact: isMobile,
                          cards: visibility.visibleSummaryCards,
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (visibility.showList)
                        OutletListPanel(
                          result: result,
                          visibility: visibility,
                          statusFilter: statusFilter,
                          isMobile: isMobile,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
