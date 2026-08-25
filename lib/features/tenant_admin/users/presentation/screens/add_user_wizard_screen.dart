import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../outlets/presentation/providers/outlet_image_upload_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/add_user_wizard_provider.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';

class AddUserWizardScreen extends ConsumerWidget {
  const AddUserWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authHeaderSyncProvider);
    final canCreate = ref.watch(userCreateAccessProvider);
    final canInvite = ref.watch(userInviteAccessProvider);
    final canOverride = ref.watch(userPermissionOverrideAccessProvider);
    final optionsState = ref.watch(userCreateOptionsProvider);

    if (!canCreate && !canInvite) {
      return const TenantAdminPageScaffold(
        title: 'Add New User',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to add users.',
        ),
      );
    }

    ref.listen(outletImageUploadControllerProvider, (previous, next) {
      if (previous?.mediaAssetId == next.mediaAssetId &&
          previous?.fileName == next.fileName) {
        return;
      }

      ref.read(addUserWizardControllerProvider.notifier).setProfileMedia(
            mediaAssetId: next.mediaAssetId,
            fileName: next.fileName,
          );
    });

    return TenantAdminPageScaffold(
      title: 'Add New User',
      subtitle: 'Complete the steps below to add a user and assign access.',
      child: optionsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load create options',
          message: 'Roles, outlets and permission options could not load.',
          onRetry: () => ref.invalidate(userCreateOptionsProvider),
        ),
        data: (options) => _AddUserWizardBody(
          options: options,
          canInvite: canInvite,
          canOverride: canOverride,
        ),
      ),
    );
  }
}

class _AddUserWizardBody extends ConsumerWidget {
  const _AddUserWizardBody({
    required this.options,
    required this.canInvite,
    required this.canOverride,
  });

  final TenantUserCreateOptions options;
  final bool canInvite;
  final bool canOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addUserWizardControllerProvider);
    final controller = ref.read(addUserWizardControllerProvider.notifier);

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && state.isDirty) {
          await _confirmDiscard(context, ref);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WizardStepper(currentStep: state.currentStep),
          const SizedBox(height: TenantAdminSpacing.xl),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.lg),
          _StepContent(
            state: state,
            options: options,
            canInvite: canInvite,
            canOverride: canOverride,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.lg),
          _WizardActions(
            state: state,
            onCancel: () => _handleCancel(context, ref),
            onBack: state.currentStep == AddUserWizardStep.basicInformation
                ? null
                : controller.back,
            onNext: state.currentStep == AddUserWizardStep.securityReview
                ? null
                : controller.next,
            onCreate: state.currentStep == AddUserWizardStep.securityReview
                ? () => _submit(context, ref)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final state = ref.read(addUserWizardControllerProvider);
    if (!state.isDirty) {
      context.go('/tenant-admin/staff');
      return;
    }

    await _confirmDiscard(context, ref);
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard user setup?'),
        content: const Text('Your entered information will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard and return to Users'),
          ),
        ],
      ),
    );

    if (discard != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(outletImageUploadControllerProvider.notifier)
          .removeImage();
    } catch (_) {
      // Navigation must not be permanently blocked by staged-media cleanup.
    }

    if (!context.mounted) {
      return;
    }

    ref.read(addUserWizardControllerProvider.notifier).reset();
    context.go('/tenant-admin/staff');
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final created =
        await ref.read(addUserWizardControllerProvider.notifier).submit();

    if (!context.mounted) {
      return;
    }

    if (created == null) {
      final error = ref.read(addUserWizardControllerProvider).generalError;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    ref.invalidate(userListProvider);
    ref.read(selectedUserIdProvider.notifier).state = created.id;
    ref.read(outletImageUploadControllerProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created.status.toUpperCase() == 'INVITED'
              ? 'User created and invitation queued.'
              : 'User created successfully.',
        ),
      ),
    );
    context.go('/tenant-admin/staff');
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.state,
    required this.options,
    required this.canInvite,
    required this.canOverride,
  });

  final AddUserWizardState state;
  final TenantUserCreateOptions options;
  final bool canInvite;
  final bool canOverride;

  @override
  Widget build(BuildContext context) {
    return switch (state.currentStep) {
      AddUserWizardStep.basicInformation => _BasicInformationStep(
          state: state,
          options: options,
          canInvite: canInvite,
        ),
      AddUserWizardStep.accessSetup => _AccessSetupStep(
          state: state,
          options: options,
          canOverride: canOverride,
        ),
      AddUserWizardStep.securityReview => _SecurityReviewStep(
          state: state,
          options: options,
        ),
    };
  }
}

class _BasicInformationStep extends ConsumerWidget {
  const _BasicInformationStep({
    required this.state,
    required this.options,
    required this.canInvite,
  });

  final AddUserWizardState state;
  final TenantUserCreateOptions options;
  final bool canInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addUserWizardControllerProvider.notifier);

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Basic Information',
          subtitle: "Enter the user's personal details and assign a role.",
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 760;
            final children = [
              _TextField(
                label: 'Full Name *',
                initialValue: state.fullName,
                errorText: state.fieldErrors['fullName'],
                onChanged: controller.setFullName,
                hintText: 'Enter full name',
              ),
              _TextField(
                label: 'Phone',
                initialValue: state.phone,
                errorText: state.fieldErrors['phone'] ??
                    state.fieldErrors['phoneNumber'],
                onChanged: controller.setPhone,
                hintText: 'Enter phone number',
                prefixIcon: Icons.phone_outlined,
              ),
              _TextField(
                label: 'Email *',
                initialValue: state.email,
                errorText: state.fieldErrors['email'],
                onChanged: controller.setEmail,
                hintText: 'Enter email address',
                prefixIcon: Icons.email_outlined,
              ),
              _RoleDropdown(
                roles: options.roles,
                selectedRoleId: state.roleId,
                errorText: state.fieldErrors['roleId'],
                onChanged: controller.setRoleId,
              ),
              _TextField(
                label: 'Employee ID',
                initialValue: state.employeeId,
                errorText: state.fieldErrors['employeeId'],
                onChanged: controller.setEmployeeId,
                hintText: 'Enter employee ID',
              ),
              const _ReadOnlyStaffCodeField(),
            ];

            if (!twoColumn) {
              return Column(
                children: [
                  for (final child in children) ...[
                    child,
                    const SizedBox(height: TenantAdminSpacing.lg),
                  ],
                ],
              );
            }

            return Wrap(
              spacing: TenantAdminSpacing.xl,
              runSpacing: TenantAdminSpacing.lg,
              children: [
                for (final child in children)
                  SizedBox(
                    width: (constraints.maxWidth - TenantAdminSpacing.xl) / 2,
                    child: child,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _StatusSelector(
          value: state.accountStatus,
          canInvite: canInvite,
          onChanged: controller.setAccountStatus,
        ),
      ],
    );

    final photo = _ProfilePhotoCard(state: state);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1080) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fields,
              const SizedBox(height: TenantAdminSpacing.xl),
              photo,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: fields),
            const SizedBox(width: TenantAdminSpacing.xl),
            SizedBox(width: 300, child: photo),
          ],
        );
      },
    );
  }
}

class _AccessSetupStep extends ConsumerWidget {
  const _AccessSetupStep({
    required this.state,
    required this.options,
    required this.canOverride,
  });

  final AddUserWizardState state;
  final TenantUserCreateOptions options;
  final bool canOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addUserWizardControllerProvider.notifier);
    final role = _roleFor(options, state.roleId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Access Setup',
          subtitle: "Configure the user's role, outlet access and permissions.",
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 980;
            final outletAccess = _AccessSetupPanel(
              title: 'Outlet Access',
              errorText: state.fieldErrors['outletIds'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OutletAccessModeTile(
                    selected: state.outletAccessMode ==
                        AddUserOutletAccessMode.allOutlets,
                    onTap: state.isSubmitting
                        ? null
                        : () => controller.setOutletAccessMode(
                              AddUserOutletAccessMode.allOutlets,
                            ),
                    title: const Text('All Outlets'),
                    subtitle: const Text(
                      'User can access all current tenant outlets.',
                    ),
                  ),
                  _OutletAccessModeTile(
                    selected: state.outletAccessMode ==
                        AddUserOutletAccessMode.specificOutlets,
                    onTap: state.isSubmitting
                        ? null
                        : () => controller.setOutletAccessMode(
                              AddUserOutletAccessMode.specificOutlets,
                            ),
                    title: const Text('Specific Outlets'),
                    subtitle: const Text('Choose one or more active outlets.'),
                  ),
                  if (state.outletAccessMode ==
                      AddUserOutletAccessMode.specificOutlets)
                    _SpecificOutletSelector(
                      outlets: options.outlets,
                      selectedOutletIds: state.selectedOutletIds,
                      isSubmitting: state.isSubmitting,
                      onChanged: controller.toggleOutlet,
                    ),
                ],
              ),
            );
            final leftColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AssignedRoleSummary(role: role),
                const SizedBox(height: TenantAdminSpacing.lg),
                outletAccess,
              ],
            );
            final permissionOverride = _PermissionOverridePanel(
              state: state,
              options: options,
              canOverride: canOverride,
              onToggleOverride: controller.setPermissionOverrideEnabled,
              onTogglePermission: controller.togglePermission,
            );

            if (!twoColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftColumn,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  permissionOverride,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: leftColumn),
                const SizedBox(width: TenantAdminSpacing.xl),
                Expanded(flex: 9, child: permissionOverride),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SecurityReviewStep extends StatelessWidget {
  const _SecurityReviewStep({
    required this.state,
    required this.options,
  });

  final AddUserWizardState state;
  final TenantUserCreateOptions options;

  @override
  Widget build(BuildContext context) {
    final role = _roleFor(options, state.roleId);
    final selectedOutlets = options.outlets
        .where((outlet) => state.selectedOutletIds.contains(outlet.id))
        .map((outlet) => outlet.name)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Security & Review',
          subtitle: 'Review the user before creating the account.',
        ),
        if (state.generalError != null) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          _InlineError(message: state.generalError!),
        ],
        const SizedBox(height: TenantAdminSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumn = constraints.maxWidth >= 900;
            final sections = [
              _ReviewSection(
                title: 'USER INFORMATION',
                rows: {
                  'Name': state.fullName.trim(),
                  'Email': state.email.trim(),
                  'Phone': state.phone.trim().isEmpty
                      ? 'Not provided'
                      : state.phone.trim(),
                  'Employee ID': state.employeeId.trim().isEmpty
                      ? 'Not provided'
                      : state.employeeId.trim(),
                  'Role': role?.name ?? 'Not selected',
                  'Status': state.accountStatusApiValue,
                },
              ),
              _ReviewSection(
                title: 'ACCESS',
                rows: {
                  'Outlet access': state.outletAccessMode ==
                          AddUserOutletAccessMode.allOutlets
                      ? 'All Outlets'
                      : selectedOutlets.join(', '),
                  'Permission override': state.permissionOverrideEnabled
                      ? '${state.selectedPermissionIds.length} selected'
                      : 'Off',
                  'Profile photo': state.profileMediaAssetId == null
                      ? 'Not provided'
                      : 'Staged media selected',
                },
              ),
            ];

            if (!twoColumn) {
              return Column(
                children: [
                  for (final section in sections) ...[
                    section,
                    const SizedBox(height: TenantAdminSpacing.lg),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: sections.first),
                const SizedBox(width: TenantAdminSpacing.xl),
                Expanded(child: sections.last),
              ],
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _SecurityMessage(status: state.accountStatus),
      ],
    );
  }
}

class _WizardStepper extends StatelessWidget {
  const _WizardStepper({required this.currentStep});

  final AddUserWizardStep currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = AddUserWizardStep.values;
    final currentIndex = steps.indexOf(currentStep);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                _StepperNode(
                  index: index + 1,
                  label: _stepLabel(steps[index]),
                  active: index == currentIndex,
                  completed: index < currentIndex,
                  compact: true,
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: TenantAdminSpacing.md,
                    margin: const EdgeInsets.only(left: 16),
                    color: index < currentIndex
                        ? TenantAdminColors.posHomeAccentOrange
                        : TenantAdminColors.border,
                  ),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Expanded(
                child: _StepperNode(
                  index: index + 1,
                  label: _stepLabel(steps[index]),
                  active: index == currentIndex,
                  completed: index < currentIndex,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: _StepperConnector(
                    key: ValueKey('addUserWizardStepperConnector$index'),
                    active: index < currentIndex,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StepperNode extends StatelessWidget {
  const _StepperNode({
    required this.index,
    required this.label,
    required this.active,
    required this.completed,
    this.compact = false,
  });

  final int index;
  final String label;
  final bool active;
  final bool completed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stateLabel = completed
        ? 'completed'
        : active
            ? 'current'
            : 'not started';
    final labelColor = active
        ? TenantAdminColors.posHomeAccentOrange
        : TenantAdminColors.bodyText;
    final circleBorder = active
        ? TenantAdminColors.posHomeAccentOrange
        : completed
            ? TenantAdminColors.success
            : TenantAdminColors.border;

    return Semantics(
      label: 'Step $index, $label, $stateLabel',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment:
              compact ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: active
                    ? TenantAdminColors.posHomeAccentOrange
                    : TenantAdminColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: circleBorder),
              ),
              child: completed
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: TenantAdminColors.success,
                    )
                  : Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperConnector extends StatelessWidget {
  const _StepperConnector({
    super.key,
    required this.active,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.sm),
      color: active
          ? TenantAdminColors.posHomeAccentOrange
          : TenantAdminColors.border,
    );
  }
}

class _WizardActions extends StatelessWidget {
  const _WizardActions({
    required this.state,
    required this.onCancel,
    required this.onBack,
    required this.onNext,
    required this.onCreate,
  });

  final AddUserWizardState state;
  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final backButton = onBack == null
        ? null
        : TenantAdminSecondaryButton(
            label: 'Back',
            icon: Icons.arrow_back,
            onPressed: state.isSubmitting ? null : onBack,
          );
    final cancelButton = _CancelWizardButton(
      onPressed: state.isSubmitting ? null : onCancel,
    );
    final primaryButton = onNext != null
        ? TenantAdminPrimaryButton(
            label: 'Next',
            icon: Icons.arrow_forward,
            onPressed: state.isSubmitting ? null : onNext,
            backgroundColor: TenantAdminColors.posHomeAccentOrange,
          )
        : TenantAdminPrimaryButton(
            label: 'Create User',
            icon: Icons.person_add_alt_1,
            loading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : onCreate,
            backgroundColor: TenantAdminColors.posHomeAccentOrange,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = [
          if (backButton != null) backButton,
          cancelButton,
          primaryButton,
        ];

        if (constraints.maxWidth < 620) {
          return Wrap(
            spacing: TenantAdminSpacing.md,
            runSpacing: TenantAdminSpacing.md,
            children: actions,
          );
        }

        return Row(
          children: [
            if (backButton != null) ...[
              backButton,
              const SizedBox(width: TenantAdminSpacing.md),
            ],
            cancelButton,
            const Spacer(),
            primaryButton,
          ],
        );
      },
    );
  }
}

class _CancelWizardButton extends StatelessWidget {
  const _CancelWizardButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.danger,
        side: BorderSide(
          color: TenantAdminColors.danger.withValues(alpha: 0.55),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
      icon: const Icon(Icons.close, size: 18),
      label: const Text(
        'Cancel',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.hintText,
    this.errorText,
    this.prefixIcon,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String hintText;
  final String? errorText;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.roles,
    required this.selectedRoleId,
    required this.onChanged,
    this.errorText,
  });

  final List<RoleOption> roles;
  final String? selectedRoleId;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedRoleId,
      decoration: InputDecoration(
        labelText: 'Role *',
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
      hint: const Text('Select role'),
      items: [
        for (final role in roles)
          DropdownMenuItem(
            value: role.id,
            child: Text(role.name),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ReadOnlyStaffCodeField extends StatelessWidget {
  const _ReadOnlyStaffCodeField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      initialValue: 'Auto-generated when user is created',
      decoration: InputDecoration(
        labelText: 'Staff Code',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.value,
    required this.canInvite,
    required this.onChanged,
  });

  final AddUserAccountStatus value;
  final bool canInvite;
  final ValueChanged<AddUserAccountStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'User Status *',
      child: SegmentedButton<AddUserAccountStatus>(
        segments: [
          const ButtonSegment(
            value: AddUserAccountStatus.inactive,
            label: Text('Inactive'),
            icon: Icon(Icons.pause_circle_outline),
          ),
          ButtonSegment(
            value: AddUserAccountStatus.invited,
            label: const Text('Invited'),
            icon: const Icon(Icons.mail_outline),
            enabled: canInvite,
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}

class _ProfilePhotoCard extends ConsumerWidget {
  const _ProfilePhotoCard({required this.state});

  final AddUserWizardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(outletImageUploadControllerProvider);
    final imageController =
        ref.read(outletImageUploadControllerProvider.notifier);
    final hasImage = imageState.previewBytes != null ||
        imageState.remoteImageUrl != null ||
        imageState.mediaAssetId != null;

    return TenantAdminSingleImageUploadCard(
      title: 'Profile Photo',
      description: 'Use a clear portrait to help identify this user.',
      fileName: imageState.fileName,
      preview: hasImage
          ? _UserProfilePreview(
              imageBytes: imageState.previewBytes,
              imageUrl: imageState.remoteImageUrl,
              initials: _initials(state.fullName),
            )
          : null,
      isBusy: imageState.status == OutletImageUploadStatus.uploading ||
          imageState.status == OutletImageUploadStatus.deleting,
      progress: imageState.status == OutletImageUploadStatus.uploading
          ? imageState.progress
          : null,
      errorText: imageState.errorMessage,
      onChooseImage:
          hasImage ? imageController.replaceImage : imageController.chooseImage,
      onRemoveImage: hasImage ? imageController.removeImage : null,
      onRetry:
          imageState.errorMessage == null ? null : imageController.retryUpload,
    );
  }
}

class _UserProfilePreview extends StatelessWidget {
  const _UserProfilePreview({
    required this.imageBytes,
    required this.imageUrl,
    required this.initials,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) return Image.memory(imageBytes!, fit: BoxFit.cover);
    if (imageUrl?.trim().isNotEmpty == true) {
      return Image.network(imageUrl!, fit: BoxFit.cover);
    }

    return Container(
      color: TenantAdminColors.secondary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _AssignedRoleSummary extends StatelessWidget {
  const _AssignedRoleSummary({required this.role});

  final RoleOption? role;

  @override
  Widget build(BuildContext context) {
    return _AccessSetupPanel(
      title: 'Assigned Role',
      subtitle: "Role determines the user's base permissions.",
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == null ? 'Select a role in Step 1' : role!.name,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (role?.roleDescription?.isNotEmpty == true) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    role!.roleDescription!,
                    style: TenantAdminTextStyles.muted(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          const Tooltip(
            message: 'Assigned from Basic Information',
            child: Icon(
              Icons.lock_outline,
              size: 20,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessSetupPanel extends StatelessWidget {
  const _AccessSetupPanel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.errorText,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TenantAdminTextStyles.sectionTitle(context),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        subtitle!,
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: TenantAdminSpacing.md),
                trailing!,
              ],
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              errorText!,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SpecificOutletSelector extends StatelessWidget {
  const _SpecificOutletSelector({
    required this.outlets,
    required this.selectedOutletIds,
    required this.isSubmitting,
    required this.onChanged,
  });

  final List<UserOutletOption> outlets;
  final Set<String> selectedOutletIds;
  final bool isSubmitting;
  final void Function(String outletId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TenantAdminSpacing.sm),
      child: outlets.isEmpty
          ? const TenantAdminEmptyState(
              title: 'No outlets available',
              message:
                  'Create an outlet before assigning specific outlet access.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select active outlets',
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Wrap(
                  spacing: TenantAdminSpacing.sm,
                  runSpacing: TenantAdminSpacing.sm,
                  children: [
                    for (final outlet in outlets)
                      FilterChip(
                        label: Text(outlet.name),
                        selected: selectedOutletIds.contains(outlet.id),
                        onSelected: isSubmitting
                            ? null
                            : (selected) => onChanged(outlet.id, selected),
                        avatar: const Icon(Icons.storefront_outlined),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PermissionOverridePanel extends StatelessWidget {
  const _PermissionOverridePanel({
    required this.state,
    required this.options,
    required this.canOverride,
    required this.onToggleOverride,
    required this.onTogglePermission,
  });

  final AddUserWizardState state;
  final TenantUserCreateOptions options;
  final bool canOverride;
  final ValueChanged<bool> onToggleOverride;
  final void Function(String permissionId, bool selected) onTogglePermission;

  @override
  Widget build(BuildContext context) {
    final canToggle = canOverride && !state.isSubmitting;

    return _AccessSetupPanel(
      title: 'Permission Override',
      subtitle: canOverride
          ? 'Grant selected backend-provided permissions beyond the role.'
          : 'You do not have permission to override user permissions.',
      errorText: state.fieldErrors['permissions'] ??
          state.fieldErrors['overriddenPermissionIds'],
      trailing: Switch(
        value: state.permissionOverrideEnabled,
        onChanged: canToggle ? onToggleOverride : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            onTap: canToggle
                ? () => onToggleOverride(!state.permissionOverrideEnabled)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: TenantAdminSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    state.permissionOverrideEnabled
                        ? Icons.tune
                        : Icons.tune_outlined,
                    color: state.permissionOverrideEnabled
                        ? TenantAdminColors.posHomeAccentOrange
                        : TenantAdminColors.mutedText,
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Enable permission override',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.permissionOverrideEnabled) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            if (options.permissionGroups.isEmpty)
              Text(
                'No backend permission groups are available for override.',
                style: TenantAdminTextStyles.muted(context),
              )
            else
              for (final group in options.permissionGroups) ...[
                Text(
                  group.groupName,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Wrap(
                  spacing: TenantAdminSpacing.sm,
                  runSpacing: TenantAdminSpacing.sm,
                  children: [
                    for (final permission in group.permissions)
                      FilterChip(
                        label: Text(
                          permission.description?.isNotEmpty == true
                              ? permission.description!
                              : permission.code,
                        ),
                        selected:
                            state.selectedPermissionIds.contains(permission.id),
                        onSelected: state.isSubmitting
                            ? null
                            : (selected) =>
                                onTogglePermission(permission.id, selected),
                      ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),
              ],
          ],
        ],
      ),
    );
  }
}

class _OutletAccessModeTile extends StatelessWidget {
  const _OutletAccessModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? TenantAdminColors.primary : TenantAdminColors.border;
    final backgroundColor =
        selected ? TenantAdminColors.secondary : TenantAdminColors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.mutedText,
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                      child: title,
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    DefaultTextStyle(
                      style: TenantAdminTextStyles.muted(context),
                      child: subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TenantAdminTextStyles.sectionTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(subtitle, style: TenantAdminTextStyles.muted(context)),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: title,
      child: Column(
        children: [
          for (final row in rows.entries)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(row.key,
                        style: TenantAdminTextStyles.muted(context)),
                  ),
                  Expanded(
                    child: Text(
                      row.value.isEmpty ? 'Not provided' : row.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityMessage extends StatelessWidget {
  const _SecurityMessage({required this.status});

  final AddUserAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final invited = status == AddUserAccountStatus.invited;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(
          color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            invited
                ? Icons.mark_email_read_outlined
                : Icons.lock_clock_outlined,
            color: TenantAdminColors.posHomeAccentOrange,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Text(
              invited
                  ? 'The user will receive a secure invitation email to set up their password.'
                  : 'This account will be created inactive and cannot sign in until activated through the approved lifecycle.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Text(message,
          style: const TextStyle(color: TenantAdminColors.danger)),
    );
  }
}

String _stepLabel(AddUserWizardStep step) {
  return switch (step) {
    AddUserWizardStep.basicInformation => 'Basic Information',
    AddUserWizardStep.accessSetup => 'Access Setup',
    AddUserWizardStep.securityReview => 'Security & Review',
  };
}

RoleOption? _roleFor(TenantUserCreateOptions options, String? roleId) {
  if (roleId == null) {
    return null;
  }

  for (final role in options.roles) {
    if (role.id == roleId) {
      return role;
    }
  }

  return null;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'AB';
  }
  if (parts.length == 1) {
    return parts.single.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
