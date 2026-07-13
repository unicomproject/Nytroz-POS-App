import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../utils/till_api_errors.dart';
import '../widgets/till_delete_dialog.dart';
import '../widgets/till_operational_status_badge.dart';

class TillDetailsScreen extends ConsumerWidget {
  const TillDetailsScreen({
    super.key,
    required this.tillId,
  });

  final String tillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(tillListVisibilityProvider).maybeWhen(
          data: (visibility) => visibility.showPage,
          orElse: () => false,
        );
    final detailState = ref.watch(tillDetailProvider(tillId));
    final canUpdate = ref.watch(tillUpdateAccessProvider);
    final canDelete = ref.watch(tillDeleteAccessProvider);

    if (!canView) {
      return const TenantAdminPageScaffold(
        title: 'Till details',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to view till details.',
        ),
      );
    }

    return detailState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Till details',
        subtitle: 'View till configuration and status.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Till details',
        subtitle: 'View till configuration and status.',
        child: TenantAdminErrorState(
          title: 'Unable to load till',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tillDetailProvider(tillId)),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return const TenantAdminPageScaffold(
            title: 'Till details',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view this till.',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: detail.name,
          subtitle: detail.code,
          actions: [
            if (canUpdate)
              TenantAdminSecondaryButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: () => context.go('/tenant-admin/tills/$tillId/edit'),
              ),
            if (canDelete) ...[
              if (canUpdate) const SizedBox(width: TenantAdminSpacing.sm),
              TenantAdminSecondaryButton(
                label: 'Deactivate',
                icon: Icons.delete_outline,
                onPressed: () => TillDeleteDialog.show(
                  context: context,
                  ref: ref,
                  till: _tillFromDetail(detail),
                ),
              ),
            ],
          ],
          child: _TillDetailsBody(detail: detail),
        );
      },
    );
  }

  Till _tillFromDetail(TillDetail detail) {
    return Till(
      id: detail.id,
      outletId: detail.outletId,
      outletName: detail.outletName,
      name: detail.name,
      code: detail.code,
      status: detail.status,
      operationalStatus: detail.deviceStatus.toLowerCase(),
      attentionLabel: detail.needsAttention ? 'Needs attention' : null,
      lastActiveAt: detail.lastActiveAt,
    );
  }
}

class _TillDetailsBody extends StatelessWidget {
  const _TillDetailsBody({required this.detail});

  final TillDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        final overview = _DetailsCard(
          title: 'Overview',
          children: [
            _DetailRow(label: 'Till name', value: detail.name),
            _DetailRow(label: 'Till code', value: detail.code),
            _DetailRow(label: 'Outlet', value: detail.outletName),
            _DetailRow(label: 'Outlet code', value: detail.outletCode),
            _DetailRow(label: 'Status', value: detail.status),
            _DetailRow(
              label: 'Device status',
              value: detail.deviceStatus,
              trailing: TillOperationalStatusBadge(
                operationalStatus: detail.deviceStatus.toLowerCase(),
                attentionLabel:
                    detail.needsAttention ? 'Needs attention' : null,
              ),
            ),
            _DetailRow(
              label: 'Last active',
              value: formatTillLastSync(detail.lastActiveAt),
            ),
            if (detail.createdAt != null)
              _DetailRow(
                label: 'Created',
                value: _formatDate(detail.createdAt!),
              ),
            if (detail.updatedAt != null)
              _DetailRow(
                label: 'Updated',
                value: _formatDate(detail.updatedAt!),
              ),
          ],
        );

        final hardware = _DetailsCard(
          title: 'Hardware',
          children: [
            _DetailRow(label: 'Device', value: detail.deviceName ?? '—'),
            _DetailRow(label: 'Printer', value: detail.printerName ?? '—'),
            _DetailRow(label: 'Scanner', value: detail.scannerName ?? '—'),
            _DetailRow(
              label: 'Cash drawer',
              value: detail.cashDrawerName ?? '—',
            ),
            _DetailRow(
              label: 'Card reader',
              value: detail.cardReaderName ?? '—',
            ),
            _DetailRow(
              label: 'Internal note',
              value: detail.internalNote ?? '—',
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            children: [
              overview,
              const SizedBox(height: TenantAdminSpacing.lg),
              hardware,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: overview),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: hardware),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: trailing ??
                Text(
                  value,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
