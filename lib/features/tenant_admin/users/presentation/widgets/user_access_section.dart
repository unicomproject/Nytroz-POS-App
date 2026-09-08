import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_user.dart';

class UserAccessSection extends StatelessWidget {
  const UserAccessSection({
    super.key,
    required this.outlets,
    required this.tills,
    required this.outletAccessScope,
    required this.selectedOutletIds,
    required this.defaultOutletId,
    required this.tillAccessScope,
    required this.selectedTillIds,
    required this.defaultTillId,
    required this.supportedOutletAccessScopes,
    required this.supportedTillAccessScopes,
    required this.supportsDefaultOutlet,
    required this.supportsDefaultTill,
    required this.onOutletScopeChanged,
    required this.onOutletsChanged,
    required this.onDefaultOutletChanged,
    required this.onTillScopeChanged,
    required this.onTillsChanged,
    required this.onDefaultTillChanged,
    required this.enabled,
    this.outletEnabled,
    this.tillEnabled,
    this.outletErrorText,
    this.tillErrorText,
  });

  final List<UserOutletOption> outlets;
  final List<UserTillOption> tills;
  final String outletAccessScope;
  final Set<String> selectedOutletIds;
  final String? defaultOutletId;
  final String tillAccessScope;
  final Set<String> selectedTillIds;
  final String? defaultTillId;
  final List<String> supportedOutletAccessScopes;
  final List<String> supportedTillAccessScopes;
  final bool supportsDefaultOutlet;
  final bool supportsDefaultTill;
  final ValueChanged<String> onOutletScopeChanged;
  final ValueChanged<Set<String>> onOutletsChanged;
  final ValueChanged<String?> onDefaultOutletChanged;
  final ValueChanged<String> onTillScopeChanged;
  final ValueChanged<Set<String>> onTillsChanged;
  final ValueChanged<String?> onDefaultTillChanged;
  final bool enabled;
  final bool? outletEnabled;
  final bool? tillEnabled;
  final String? outletErrorText;
  final String? tillErrorText;

  @override
  Widget build(BuildContext context) {
    final outletScopes = supportedOutletAccessScopes.isEmpty
        ? const ['ALL_OUTLETS', 'SELECTED_OUTLETS', 'NO_OUTLET_ACCESS']
        : supportedOutletAccessScopes;
    final tillScopes = supportedTillAccessScopes.isEmpty
        ? const [
            'ALL_ACCESSIBLE_TILLS',
            'SELECTED_TILLS',
            'NO_TILL_ACCESS',
          ]
        : supportedTillAccessScopes;
    final selectableOutlets = outletAccessScope == 'SELECTED_OUTLETS'
        ? outlets
            .where((outlet) => selectedOutletIds.contains(outlet.id))
            .toList()
        : outletAccessScope == 'NO_OUTLET_ACCESS'
            ? <UserOutletOption>[]
            : outlets;
    final allowedOutletIds =
        selectableOutlets.map((outlet) => outlet.id).toSet();
    final selectableTills = tills
        .where((till) => allowedOutletIds.contains(till.outletId))
        .toList(growable: false);
    final defaultOutletValue =
        selectableOutlets.any((o) => o.id == defaultOutletId)
            ? defaultOutletId
            : null;
    final defaultTillCandidates = tillAccessScope == 'SELECTED_TILLS'
        ? selectableTills
            .where((till) => selectedTillIds.contains(till.id))
            .toList()
        : tillAccessScope == 'NO_TILL_ACCESS'
            ? <UserTillOption>[]
            : selectableTills;
    final defaultTillValue =
        defaultTillCandidates.any((t) => t.id == defaultTillId)
            ? defaultTillId
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 18,
                color: TenantAdminColors.primary,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outlet & Till Access',
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                  Text(
                    'Control exactly where this user can work.',
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: outletScopes.contains(outletAccessScope)
              ? outletAccessScope
              : outletScopes.first,
          decoration: const InputDecoration(
            labelText: 'Outlet access scope',
            prefixIcon: Icon(Icons.store_outlined),
          ),
          items: [
            for (final scope in outletScopes)
              DropdownMenuItem(value: scope, child: Text(_scopeLabel(scope))),
          ],
          onChanged: (outletEnabled ?? enabled)
              ? (value) {
                  if (value != null) onOutletScopeChanged(value);
                }
              : null,
        ),
        if (outletAccessScope == 'SELECTED_OUTLETS') ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _SelectionBox<UserOutletOption>(
            items: outlets,
            selectedIds: selectedOutletIds,
            idOf: (item) => item.id,
            labelOf: (item) => item.name,
            emptyMessage: 'No outlets available for this tenant.',
            enabled: outletEnabled ?? enabled,
            errorText: outletErrorText,
            onChanged: onOutletsChanged,
          ),
        ],
        if (supportsDefaultOutlet && selectableOutlets.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: defaultOutletValue,
            decoration: const InputDecoration(
              labelText: 'Default outlet (optional)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No default outlet'),
              ),
              for (final outlet in selectableOutlets)
                DropdownMenuItem<String?>(
                  value: outlet.id,
                  child: Text(outlet.name),
                ),
            ],
            onChanged:
                (outletEnabled ?? enabled) ? onDefaultOutletChanged : null,
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        DropdownButtonFormField<String>(
          initialValue: tillScopes.contains(tillAccessScope)
              ? tillAccessScope
              : tillScopes.first,
          decoration: const InputDecoration(
            labelText: 'Till access scope',
            prefixIcon: Icon(Icons.point_of_sale_outlined),
          ),
          items: [
            for (final scope in tillScopes)
              DropdownMenuItem(value: scope, child: Text(_scopeLabel(scope))),
          ],
          onChanged: (tillEnabled ?? enabled)
              ? (value) {
                  if (value != null) onTillScopeChanged(value);
                }
              : null,
        ),
        if (tillAccessScope == 'SELECTED_TILLS') ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _SelectionBox<UserTillOption>(
            items: selectableTills,
            selectedIds: selectedTillIds,
            idOf: (item) => item.id,
            labelOf: (item) => item.code.trim().isEmpty
                ? item.name
                : '${item.name} (${item.code})',
            emptyMessage: 'No tills are available for the selected outlets.',
            enabled: tillEnabled ?? enabled,
            errorText: tillErrorText,
            onChanged: onTillsChanged,
          ),
        ],
        if (supportsDefaultTill && defaultTillCandidates.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: defaultTillValue,
            decoration: const InputDecoration(
              labelText: 'Default till (optional)',
              prefixIcon: Icon(Icons.point_of_sale),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No default till'),
              ),
              for (final till in defaultTillCandidates)
                DropdownMenuItem<String?>(
                  value: till.id,
                  child: Text(till.name),
                ),
            ],
            onChanged: (tillEnabled ?? enabled) ? onDefaultTillChanged : null,
          ),
        ],
      ],
    );
  }

  String _scopeLabel(String scope) => switch (scope) {
        'ALL_OUTLETS' => 'All outlets',
        'SELECTED_OUTLETS' => 'Selected outlets only',
        'NO_OUTLET_ACCESS' => 'No outlet access',
        'ALL_ACCESSIBLE_TILLS' => 'All accessible tills',
        'SELECTED_TILLS' => 'Selected tills only',
        'NO_TILL_ACCESS' => 'No till access',
        _ => scope.replaceAll('_', ' '),
      };
}

class _SelectionBox<T> extends StatelessWidget {
  const _SelectionBox({
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.labelOf,
    required this.emptyMessage,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final List<T> items;
  final Set<String> selectedIds;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final String emptyMessage;
  final bool enabled;
  final ValueChanged<Set<String>> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: errorText == null
                    ? TenantAdminColors.border
                    : TenantAdminColors.danger,
              ),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: items.isEmpty
                ? Text(emptyMessage,
                    style: TenantAdminTextStyles.muted(context))
                : Wrap(
                    spacing: TenantAdminSpacing.sm,
                    runSpacing: TenantAdminSpacing.sm,
                    children: [
                      for (final item in items)
                        FilterChip(
                          label: Text(labelOf(item)),
                          selected: selectedIds.contains(idOf(item)),
                          onSelected: enabled
                              ? (selected) {
                                  final next = {...selectedIds};
                                  selected
                                      ? next.add(idOf(item))
                                      : next.remove(idOf(item));
                                  onChanged(next);
                                }
                              : null,
                          selectedColor:
                              TenantAdminColors.primary.withValues(alpha: 0.14),
                          checkmarkColor: TenantAdminColors.primary,
                        ),
                    ],
                  ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              errorText!,
              style: const TextStyle(
                color: TenantAdminColors.danger,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
}

class UserToggleRow extends StatelessWidget {
  const UserToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(subtitle, style: TenantAdminTextStyles.muted(context)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: TenantAdminColors.primary,
          ),
        ],
      ),
    );
  }
}
