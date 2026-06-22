import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../widgets/till_list_panel.dart';
import '../widgets/till_metric_cards.dart';

class TillListScreen extends ConsumerWidget {
  const TillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(tillListVisibilityProvider);
    final tillsState = ref.watch(tillListProvider);
    final statusFilter = ref.watch(tillStatusFilterProvider);
    final page = ref.watch(tillPageProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Tills',
        subtitle: 'Manage the tills used in each outlet.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Tills',
        subtitle: 'Manage the tills used in each outlet.',
        child: TenantAdminErrorState(
          title: 'Unable to load tills',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tillListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Tills',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view tills.',
            ),
          );
        }

        return tillsState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Tills' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage the tills used in each outlet.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Tills',
            subtitle: 'Manage the tills used in each outlet.',
            child: TenantAdminErrorState(
              title: 'Unable to load tills',
              message: 'Please try again.',
              onRetry: () => ref.refresh(tillListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Tills',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view tills.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Tills' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage the tills used in each outlet.'
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSummarySection) ...[
                        TillMetricCards(
                          summary: result.summary,
                          compact: isMobile,
                          cards: visibility.visibleSummaryCards,
                        ),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (visibility.showList)
                        TillListPanel(
                          result: result,
                          visibility: visibility,
                          statusFilter: statusFilter,
                          isMobile: isMobile,
                          page: page,
                          needsAttentionCount: result.summary.needsAttentionCount,
                          onSearchChanged: (value) {
                            ref.read(tillSearchProvider.notifier).state = value;
                            ref.read(tillPageProvider.notifier).state = 1;
                          },
                          onStatusFilterChanged: (filter) {
                            ref.read(tillStatusFilterProvider.notifier).state =
                                filter;
                            ref.read(tillPageProvider.notifier).state = 1;
                          },
                          onPageChanged: (nextPage) {
                            ref.read(tillPageProvider.notifier).state =
                                nextPage;
                          },
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
