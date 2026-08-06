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
import '../config/outlet_summary_card_configs.dart';
import '../widgets/outlet_detail_panel.dart';

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
                final isDesktop = constraints.maxWidth >= 1000;

                // ── Summary metrics (always above the split) ──────────
                Widget? summarySection;
                if (visibility.showSummarySection) {
                  summarySection = Consumer(
                    builder: (context, ref, _) {
                      final summaryState =
                          ref.watch(outletSummaryDashboardProvider);
                      return summaryState.when(
                        data: (summary) => OutletMetricCards(
                          summary: summary,
                          compact: isMobile,
                          cards: outletSummaryCardConfigs,
                        ),
                        loading: () => const SizedBox(height: 116),
                        error: (_, __) => const SizedBox(height: 116),
                      );
                    },
                  );
                }

                if (!visibility.showList) {
                  return TenantAdminPageScaffold(
                    title: '',
                    child: summarySection ?? const SizedBox.shrink(),
                  );
                }

                // ── Build the list panel ──────────────────────────────
                final listPanel = OutletListPanel(
                  result: result,
                  visibility: visibility,
                  statusFilter: statusFilter,
                  isMobile: isMobile,
                  showPanelTitle: true,
                  showAddButton: true,
                );

                if (isDesktop) {
                  // Desktop: 65/35 split, both panels independently scroll.
                  // We use TenantAdminPageScaffold with title: '' so the outer
                  // rounded container is still rendered, but we handle the
                  // inner layout ourselves.
                  return _DesktopLayout(
                    summarySection: summarySection,
                    listPanel: listPanel,
                  );
                }

                // Mobile / tablet: stacked column, wrapped in the page scaffold.
                return TenantAdminPageScaffold(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summarySection != null) ...[
                        summarySection,
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      listPanel,
                      const SizedBox(height: TenantAdminSpacing.xl),
                      const OutletDetailPanel(),
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

// ─── Desktop split layout ─────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.listPanel,
    this.summarySection,
  });

  final Widget listPanel;
  final Widget? summarySection;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ColoredBox(
      color: TenantAdminColors.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad > 0 ? bottomPad : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional summary section on top
            if (summarySection != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  0,
                ),
                child: summarySection!,
              ),
            if (summarySection != null)
              const SizedBox(height: TenantAdminSpacing.lg),

            // 65/35 horizontal split — fills remaining height
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: TenantAdminShadows.card,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: list panel (65 %) ─────────────────
                    Expanded(
                      flex: 65,
                      child: SingleChildScrollView(
                        child: listPanel,
                      ),
                    ),

                    // ── Divider ─────────────────────────────────
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: TenantAdminColors.border,
                    ),

                    // ── Right: detail panel (35 %) ──────────────
                    const Expanded(
                      flex: 35,
                      child: SingleChildScrollView(
                        child: OutletDetailPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
