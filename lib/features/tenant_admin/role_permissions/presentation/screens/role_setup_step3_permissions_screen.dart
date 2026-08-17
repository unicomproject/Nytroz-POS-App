import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';
import 'role_setup_shell.dart';
import 'role_setup_step2_modules_screen.dart';

class RoleSetupStep3PermissionsScreen extends ConsumerStatefulWidget {
  const RoleSetupStep3PermissionsScreen({super.key});

  @override
  ConsumerState<RoleSetupStep3PermissionsScreen> createState() =>
      _RoleSetupStep3PermissionsScreenState();
}

class _RoleSetupStep3PermissionsScreenState
    extends ConsumerState<RoleSetupStep3PermissionsScreen> {
  String? _selectedModuleCode;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleSetupWizardProvider);
    final controller = ref.read(roleSetupWizardProvider.notifier);
    final catalogState = ref.watch(wizardPermissionCatalogProvider);

    return RoleSetupShell(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Step Header ──
            const RoleSetupStepHeader(
              step: 3,
              title: 'Configure Permissions',
              subtitle:
                  'Configure what this role can view and do in each module.',
            ),

            // ── Two-Panel Layout ──
            Expanded(
              child: catalogState.when(
                loading: () =>
                    const TenantAdminLoadingSkeleton(rowCount: 3),
                error: (error, stackTrace) => TenantAdminErrorState(
                  title: 'Failed to load permissions',
                  message: 'Please try again.',
                  onRetry: () =>
                      ref.refresh(wizardPermissionCatalogProvider),
                ),
                data: (catalog) {
                  final selectedModules = catalog.modules
                      .where(
                          (m) => state.selectedModules.contains(m.code))
                      .toList();

                  if (selectedModules.isEmpty) {
                    return const TenantAdminEmptyState(
                      title: 'No modules selected',
                      message:
                          'Please go back and select at least one module.',
                    );
                  }

                  if (_selectedModuleCode == null &&
                      selectedModules.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedModuleCode =
                              selectedModules.first.code;
                        });
                      }
                    });
                  }

                  final activeModule = selectedModules.firstWhere(
                    (m) => m.code == _selectedModuleCode,
                    orElse: () => selectedModules.first,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Left Sidebar: Module List ──
                      Container(
                        width: 220,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                                color: TenantAdminColors.border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: TenantAdminSpacing.md),
                              child: Text(
                                'Modules',
                                style:
                                    TenantAdminTextStyles.sectionTitle(
                                        context),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: selectedModules.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(
                                        height:
                                            TenantAdminSpacing.xs),
                                itemBuilder: (context, index) {
                                  final module =
                                      selectedModules[index];
                                  final totalPerms = module.features
                                      .expand((f) => f.permissions)
                                      .length;
                                  final selectedPerms = module
                                      .features
                                      .expand((f) => f.permissions)
                                      .where((p) => state
                                          .selectedPermissionCodes
                                          .contains(p.code))
                                      .length;

                                  final isSelected = module.code ==
                                      (_selectedModuleCode ??
                                          selectedModules.first.code);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedModuleCode =
                                            module.code;
                                      });
                                    },
                                    borderRadius:
                                        BorderRadius.circular(
                                            TenantAdminRadius.sm),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            TenantAdminSpacing.md,
                                        vertical:
                                            TenantAdminSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? TenantAdminColors
                                                .primary
                                                .withValues(
                                                    alpha: 0.08)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(
                                                TenantAdminRadius.sm),
                                        border: isSelected
                                            ? Border.all(
                                                color: TenantAdminColors
                                                    .primary
                                                    .withValues(
                                                        alpha: 0.3))
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              module.name,
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight
                                                        .normal,
                                                fontSize: 14,
                                                color: isSelected
                                                    ? TenantAdminColors
                                                        .primary
                                                    : TenantAdminColors
                                                        .bodyText,
                                              ),
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                              width:
                                                  TenantAdminSpacing
                                                      .sm),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? TenantAdminColors
                                                      .primary
                                                      .withValues(
                                                          alpha: 0.12)
                                                  : TenantAdminColors
                                                      .subtleBackground,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                            ),
                                            child: Text(
                                              '$selectedPerms / $totalPerms',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: isSelected
                                                    ? TenantAdminColors
                                                        .primary
                                                    : TenantAdminColors
                                                        .mutedText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.xl),

                      // ── Right Panel: Permissions Table ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${activeModule.name} Permissions',
                                  style:
                                      TenantAdminTextStyles
                                          .sectionTitle(context),
                                ),
                                Builder(
                                  builder: (context) {
                                    final total = activeModule.features
                                        .expand((f) => f.permissions)
                                        .length;
                                    final selected = activeModule
                                        .features
                                        .expand((f) => f.permissions)
                                        .where((p) => state
                                            .selectedPermissionCodes
                                            .contains(p.code))
                                        .length;
                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            TenantAdminSpacing.md,
                                        vertical:
                                            TenantAdminSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: TenantAdminColors
                                            .subtleBackground,
                                        borderRadius:
                                            BorderRadius.circular(
                                                TenantAdminRadius.xl),
                                      ),
                                      child: Text(
                                        '$selected of $total selected',
                                        style: TenantAdminTextStyles
                                                .muted(context)
                                            .copyWith(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(
                                height: TenantAdminSpacing.md),
                            const Divider(height: 1),

                            // Table header
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: TenantAdminSpacing.md,
                                horizontal: TenantAdminSpacing.sm,
                              ),
                              color:
                                  TenantAdminColors.subtleBackground,
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Permission',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: TenantAdminColors
                                            .mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Allow',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: TenantAdminColors
                                            .mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Permission rows
                            Expanded(
                              child: ListView.builder(
                                itemCount:
                                    activeModule.features.length,
                                itemBuilder: (context, index) {
                                  final feature =
                                      activeModule.features[index];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ...feature.permissions
                                          .map((permission) {
                                        final isChecked = state
                                            .selectedPermissionCodes
                                            .contains(
                                                permission.code);
                                        return InkWell(
                                          onTap: () => controller
                                              .togglePermission(
                                                  permission.code),
                                          child: Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              vertical:
                                                  TenantAdminSpacing
                                                      .md,
                                              horizontal:
                                                  TenantAdminSpacing
                                                      .sm,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color: isChecked
                                                  ? TenantAdminColors
                                                      .primary
                                                      .withValues(
                                                          alpha:
                                                              0.04)
                                                  : null,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        permission
                                                            .name,
                                                        style:
                                                            TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                          fontSize:
                                                              14,
                                                          color: TenantAdminColors
                                                              .bodyText,
                                                        ),
                                                      ),
                                                      if (permission
                                                              .description !=
                                                          null) ...[
                                                        const SizedBox(
                                                            height:
                                                                TenantAdminSpacing
                                                                    .xs),
                                                        Text(
                                                          permission
                                                              .description!,
                                                          style: TenantAdminTextStyles
                                                                  .muted(
                                                                      context)
                                                              .copyWith(
                                                                  fontSize:
                                                                      12),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 80,
                                                  child: Center(
                                                    child: Checkbox(
                                                      value:
                                                          isChecked,
                                                      onChanged:
                                                          (_) =>
                                                              controller.togglePermission(
                                                                  permission
                                                                      .code),
                                                      activeColor:
                                                          TenantAdminColors
                                                              .primary,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    4),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      const Divider(height: 1),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Info Banner ──
            const RoleSetupInfoBanner(
              message:
                  'Removing critical permissions may restrict system access. All permissions are module and action based.',
              icon: Icons.warning_amber_rounded,
              color: TenantAdminColors.warning,
            ),

            const SizedBox(height: TenantAdminSpacing.md),

            // ── Footer ──
            RoleSetupFooterActions(
              onBack: () {
                controller.previousStep();
                context.go(
                    '/tenant-admin/roles-permissions/create/modules');
              },
              onSaveDraft: () {
                controller.saveDraft();
              },
              onContinue: () {
                controller.nextStep();
                context.go(
                    '/tenant-admin/roles-permissions/create/assignments');
              },
            ),
          ],
        ),
      ),
    );
  }
}
