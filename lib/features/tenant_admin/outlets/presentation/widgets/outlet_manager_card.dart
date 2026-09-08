import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/outlet_detail_providers.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';

class OutletManagerCard extends ConsumerStatefulWidget {
  const OutletManagerCard({
    super.key,
    required this.outletId,
    required this.canManage,
  });

  final String outletId;
  final bool canManage;

  @override
  ConsumerState<OutletManagerCard> createState() => _OutletManagerCardState();
}

class _OutletManagerCardState extends ConsumerState<OutletManagerCard> {
  String? _selectedManagerId;
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(
      tenantAdminOutletOverviewProvider(widget.outletId),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: overviewState.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (error, stackTrace) => Row(
          children: [
            const Expanded(
              child: Text('Unable to load the outlet manager.'),
            ),
            TextButton(
              onPressed: () => ref.invalidate(
                tenantAdminOutletOverviewProvider(widget.outletId),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (overview) {
          final managerName = overview.managerName?.trim();
          final hasManager = overview.managerId != null &&
              managerName != null &&
              managerName.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Outlet Manager',
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                hasManager
                    ? '$managerName${overview.managerEmail == null ? '' : ' • ${overview.managerEmail}'}'
                    : 'No manager is currently assigned.',
                style: const TextStyle(color: TenantAdminColors.mutedText),
              ),
              if (widget.canManage) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                _buildManagerControls(overview.managerId, hasManager),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildManagerControls(String? currentManagerId, bool hasManager) {
    final managersState = ref.watch(outletManagersProvider);

    return managersState.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, stackTrace) => Row(
        children: [
          const Expanded(child: Text('Unable to load active users.')),
          TextButton(
            onPressed: () => ref.invalidate(outletManagersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (managers) {
        final selectedId = _selectedManagerId ?? currentManagerId;
        final validSelectedId =
            managers.any((item) => item.id == selectedId) ? selectedId : null;

        return Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String>(
                key: ValueKey('manager-$currentManagerId-$validSelectedId'),
                initialValue: validSelectedId,
                decoration: const InputDecoration(
                  labelText: 'Select active user',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final manager in managers)
                    DropdownMenuItem(
                      value: manager.id,
                      child: Text(
                        manager.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectedManagerId = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _saving ||
                      validSelectedId == null ||
                      validSelectedId == currentManagerId
                  ? null
                  : () => _assignManager(validSelectedId),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: Text(hasManager ? 'Change Manager' : 'Assign Manager'),
            ),
            if (hasManager)
              OutlinedButton.icon(
                onPressed: _saving ? null : _confirmRemoveManager,
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Remove Manager'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _assignManager(String tenantUserId) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(setOutletManagerProvider)
          .call(widget.outletId, tenantUserId);
      _refreshOutletData();
      if (mounted) {
        setState(() => _selectedManagerId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outlet manager updated.')),
        );
      }
    } catch (error) {
      _showError('Unable to update outlet manager: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmRemoveManager() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove outlet manager?'),
        content: const Text(
          'The user will remain active, but will no longer be the primary manager for this outlet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(removeOutletManagerProvider).call(widget.outletId);
      _refreshOutletData();
      if (mounted) {
        setState(() => _selectedManagerId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outlet manager removed.')),
        );
      }
    } catch (error) {
      _showError('Unable to remove outlet manager: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _refreshOutletData() {
    ref.invalidate(tenantAdminOutletOverviewProvider(widget.outletId));
    ref.invalidate(outletListProvider);
    ref.invalidate(outletSummaryDashboardProvider);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TenantAdminColors.danger,
      ),
    );
  }
}
