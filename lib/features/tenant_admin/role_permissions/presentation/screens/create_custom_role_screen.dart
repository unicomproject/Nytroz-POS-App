import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/permission_catalog.dart';
import '../providers/role_mutation_controller.dart';
import '../providers/role_permissions_providers.dart';

final customRolePermissionCatalogProvider =
    FutureProvider.autoDispose<PermissionCatalog>((ref) async {
  ref.watch(authHeaderSyncProvider);
  return ref.watch(getPermissionCatalogProvider)();
});

class CreateCustomRoleScreen extends ConsumerStatefulWidget {
  const CreateCustomRoleScreen({super.key});

  @override
  ConsumerState<CreateCustomRoleScreen> createState() =>
      _CreateCustomRoleScreenState();
}

class _CreateCustomRoleScreenState
    extends ConsumerState<CreateCustomRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _permissionCodes = {};
  String? _validationMessage;

  @override
  void dispose() {
    _roleNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRole() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_permissionCodes.isEmpty) {
      setState(() {
        _validationMessage = 'Select at least one permission for this role.';
      });
      return;
    }

    setState(() => _validationMessage = null);
    final roleId = await ref
        .read(roleMutationControllerProvider.notifier)
        .createRole(
          _roleNameController.text.trim(),
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          _permissionCodes.toList(growable: false)..sort(),
        );

    if (roleId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom role created successfully.')),
      );
      context.go('/tenant-admin/roles');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(customRolePermissionCatalogProvider);
    final mutationState = ref.watch(roleMutationControllerProvider);

    return TenantAdminPageScaffold(
      title: 'Create Custom Role',
      subtitle: 'Create a tenant-specific role and assign its permissions.',
      actions: [
        TenantAdminSecondaryButton(
          label: 'Cancel',
          onPressed: mutationState.isLoading
              ? null
              : () => context.go('/tenant-admin/roles'),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        TenantAdminPrimaryButton(
          label: 'Create Role',
          icon: Icons.add,
          loading: mutationState.isLoading,
          onPressed: mutationState.isLoading ? null : _createRole,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mutationState.error != null || _validationMessage != null) ...[
              _ErrorBanner(
                message: _validationMessage ?? mutationState.error!,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            _RoleDetailsCard(
              roleNameController: _roleNameController,
              descriptionController: _descriptionController,
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            Text(
              'Permissions',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'Select only permissions this role needs. The server validates your access ceiling before saving.',
              style: TenantAdminTextStyles.muted(context),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Chip(label: Text('${_permissionCodes.length} selected')),
            const SizedBox(height: TenantAdminSpacing.md),
            catalogState.when(
              loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
              error: (error, stackTrace) => TenantAdminErrorState(
                title: 'Unable to load permissions',
                message: 'Please try again.',
                onRetry: () => ref.invalidate(customRolePermissionCatalogProvider),
              ),
              data: (catalog) {
                final modules = catalog.modules
                    .where(
                      (module) => module.features
                          .expand((feature) => feature.permissions)
                          .any((permission) => permission.assignable),
                    )
                    .toList(growable: false);

                if (modules.isEmpty) {
                  return const TenantAdminEmptyState(
                    title: 'No permissions available',
                    message: 'No assignable permissions are available for this tenant.',
                  );
                }

                return Column(
                  children: [
                    for (final module in modules) ...[
                      _PermissionModuleCard(
                        module: module,
                        selectedCodes: _permissionCodes,
                        onChanged: (code, selected) {
                          setState(() {
                            if (selected) {
                              _permissionCodes.add(code);
                            } else {
                              _permissionCodes.remove(code);
                            }
                            _validationMessage = null;
                          });
                        },
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDetailsCard extends StatelessWidget {
  const _RoleDetailsCard({
    required this.roleNameController,
    required this.descriptionController,
  });

  final TextEditingController roleNameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role details',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TextFormField(
            controller: roleNameController,
            decoration: const InputDecoration(
              labelText: 'Role name *',
              hintText: 'Example: Store Supervisor',
              border: OutlineInputBorder(),
            ),
            maxLength: 120,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Role name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the responsibility of this role.',
              border: OutlineInputBorder(),
            ),
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _PermissionModuleCard extends StatelessWidget {
  const _PermissionModuleCard({
    required this.module,
    required this.selectedCodes,
    required this.onChanged,
  });

  final PermissionCatalogModule module;
  final Set<String> selectedCodes;
  final void Function(String code, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final features = module.features
        .where(
          (feature) => feature.permissions.any(
            (permission) => permission.assignable,
          ),
        )
        .toList(growable: false);

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(module.name),
        subtitle: Text(module.description ?? module.code),
        children: [
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TenantAdminSpacing.lg,
                TenantAdminSpacing.sm,
                TenantAdminSpacing.lg,
                TenantAdminSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  for (final permission in feature.permissions.where(
                    (permission) => permission.assignable,
                  ))
                    CheckboxListTile(
                      value: selectedCodes.contains(permission.code),
                      onChanged: (selected) =>
                          onChanged(permission.code, selected ?? false),
                      title: Text(permission.name),
                      subtitle: Text(permission.code),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.dangerSurface,
        border: Border.all(color: TenantAdminColors.dangerBorder),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TenantAdminColors.danger),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
