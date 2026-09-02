import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/theme/tenant_admin_motion.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_stepper_header.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/add_user_wizard_provider.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../providers/user_profile_image_upload_provider.dart';

const _stepLabels = [
  'Basic Information',
  'Assign Role',
  'Configure Permissions',
  'Outlet, Till & Access Scope',
  'Security & Review',
];

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

    ref.listen(userProfileImageUploadControllerProvider, (previous, next) {
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
      subtitle: 'Create a user and assign role-based access in five steps.',
      scrollable: false,
      child: optionsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load create options',
          message: 'Roles, outlets and permission options could not load.',
          onRetry: () => ref.invalidate(userCreateOptionsProvider),
        ),
        data: (options) => _WizardBody(
          options: options,
          canInvite: canInvite,
          canOverride: canOverride,
        ),
      ),
    );
  }
}

class _WizardBody extends ConsumerStatefulWidget {
  const _WizardBody({
    required this.options,
    required this.canInvite,
    required this.canOverride,
  });

  final TenantUserCreateOptions options;
  final bool canInvite;
  final bool canOverride;

  @override
  ConsumerState<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends ConsumerState<_WizardBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(addUserWizardControllerProvider.notifier)
            .syncCreateOptions(widget.options);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addUserWizardControllerProvider);
    final controller = ref.read(addUserWizardControllerProvider.notifier);
    final stepIndex = AddUserWizardStep.values.indexOf(state.currentStep);

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.isDirty) _confirmDiscard();
      },
      child: Container(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          boxShadow: TenantAdminShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TenantAdminSpacing.xlg,
                TenantAdminSpacing.xlg,
                TenantAdminSpacing.xlg,
                0,
              ),
              child: TenantAdminStepperHeader(
                steps: _stepLabels,
                currentStep: stepIndex,
                completedColor: TenantAdminColors.success,
                onStepTap: (index) => controller.goToCompletedStep(
                  AddUserWizardStep.values[index],
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.xlg,
                ),
                physics: const ClampingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: TenantAdminMotion.normal,
                  switchInCurve: TenantAdminMotion.emphasized,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.currentStep),
                    child: _StepContent(
                      state: state,
                      options: widget.options,
                      canInvite: widget.canInvite,
                      canOverride: widget.canOverride,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: const BoxDecoration(
                color: TenantAdminColors.surface,
                border: Border(
                  top: BorderSide(color: TenantAdminColors.border),
                ),
              ),
              child: Row(
                children: [
                  TenantAdminSecondaryButton(
                    label: stepIndex == 0 ? 'Cancel' : 'Back',
                    icon: stepIndex == 0 ? Icons.close : Icons.arrow_back,
                    onPressed: state.isSubmitting
                        ? null
                        : stepIndex == 0
                            ? _handleCancel
                            : controller.back,
                  ),
                  if (stepIndex > 0)
                    TextButton(
                      onPressed: state.isSubmitting ? null : _handleCancel,
                      child: const Text('Cancel'),
                    ),
                  const Spacer(),
                  TenantAdminPrimaryButton(
                    label: stepIndex == 4 ? 'Create User' : 'Next',
                    icon: stepIndex == 4
                        ? Icons.person_add_alt_1
                        : Icons.arrow_forward,
                    loading: state.isSubmitting,
                    onPressed: stepIndex == 4 ? _submit : _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancel() async {
    final state = ref.read(addUserWizardControllerProvider);
    if (!state.isDirty) {
      context.go('/tenant-admin/staff');
      return;
    }
    await _confirmDiscard();
  }

  void _next() {
    final state = ref.read(addUserWizardControllerProvider);
    if (state.currentStep == AddUserWizardStep.basicInformation &&
        !_profileImageReady()) {
      return;
    }
    ref.read(addUserWizardControllerProvider.notifier).next();
  }

  bool _profileImageReady() {
    final upload = ref.read(userProfileImageUploadControllerProvider);
    if (upload.status == UserProfileImageUploadStatus.selecting ||
        upload.status == UserProfileImageUploadStatus.uploading ||
        upload.status == UserProfileImageUploadStatus.deleting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Wait for the profile image upload to finish.')),
      );
      return false;
    }
    if (upload.status == UserProfileImageUploadStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Retry or remove the profile image before continuing.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _confirmDiscard() async {
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
    if (discard != true || !mounted) return;
    try {
      await ref
          .read(userProfileImageUploadControllerProvider.notifier)
          .discardStagedImage();
    } catch (_) {}
    if (!mounted) return;
    ref.read(addUserWizardControllerProvider.notifier).reset();
    context.go('/tenant-admin/staff');
  }

  Future<void> _submit() async {
    if (!_profileImageReady()) return;
    final created =
        await ref.read(addUserWizardControllerProvider.notifier).submit();
    if (!mounted) return;
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
    ref.read(userProfileImageUploadControllerProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User created successfully.')),
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
    final stepIndex = AddUserWizardStep.values.indexOf(state.currentStep);
    final content = switch (state.currentStep) {
      AddUserWizardStep.basicInformation => _BasicStep(
          state: state,
          options: options,
          canInvite: canInvite,
        ),
      AddUserWizardStep.assignRole => _RoleStep(state: state, options: options),
      AddUserWizardStep.configurePermissions => _PermissionStep(
          state: state,
          options: options,
          canOverride: canOverride,
        ),
      AddUserWizardStep.accessScope =>
        _AccessStep(state: state, options: options),
      AddUserWizardStep.securityReview =>
        _ReviewStep(state: state, options: options),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepEyebrow(
          current: stepIndex + 1,
          total: AddUserWizardStep.values.length,
          label: _stepLabels[stepIndex],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        content,
        const SizedBox(height: TenantAdminSpacing.xlg),
      ],
    );
  }
}

class _BasicStep extends ConsumerWidget {
  const _BasicStep({
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
    final upload = ref.watch(userProfileImageUploadControllerProvider);
    final uploader =
        ref.read(userProfileImageUploadControllerProvider.notifier);
    final busy = upload.status == UserProfileImageUploadStatus.selecting ||
        upload.status == UserProfileImageUploadStatus.uploading ||
        upload.status == UserProfileImageUploadStatus.deleting;
    Widget? preview;
    if (upload.previewBytes != null) {
      preview = _ImagePreview(bytes: upload.previewBytes!);
    }

    final fields = _Panel(
      title: 'Basic Information',
      subtitle: "Enter the user's identity and account details.",
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 680
              ? (constraints.maxWidth - TenantAdminSpacing.lg) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: TenantAdminSpacing.lg,
            runSpacing: TenantAdminSpacing.lg,
            children: [
              _field(width, 'Full Name *', state.fullName, 'Enter full name',
                  controller.setFullName, state.fieldErrors['fullName']),
              _field(width, 'Phone', state.phone, 'Enter phone number',
                  controller.setPhone, state.fieldErrors['phone'],
                  icon: Icons.phone_outlined),
              _field(width, 'Email *', state.email, 'Enter email address',
                  controller.setEmail, state.fieldErrors['email'],
                  icon: Icons.email_outlined),
              _field(
                  width,
                  'Employee ID (Optional)',
                  state.employeeId,
                  'Enter employee ID',
                  controller.setEmployeeId,
                  state.fieldErrors['employeeId'],
                  icon: Icons.badge_outlined),
              SizedBox(
                width: width,
                child: const _ReadOnlyField(
                  label: 'Staff Code',
                  value: 'Generated when the user is created',
                ),
              ),
              SizedBox(
                width: width,
                child: _StatusField(
                  state: state,
                  options: options,
                  canInvite: canInvite,
                  onChanged: controller.setAccountStatus,
                ),
              ),
              if (state.accountStatus == AddUserAccountStatus.active) ...[
                _field(
                  width,
                  'Password *',
                  state.password,
                  'Create a secure password',
                  controller.setPassword,
                  state.fieldErrors['password'],
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                _field(
                  width,
                  'Confirm Password *',
                  state.confirmPassword,
                  'Enter the password again',
                  controller.setConfirmPassword,
                  state.fieldErrors['confirmPassword'],
                  icon: Icons.lock_reset_outlined,
                  obscureText: true,
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: const Text(
                    'Minimum 8 characters with uppercase, lowercase, and a number. Only a secure password hash is stored.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    final photo = TenantAdminSingleImageUploadCard(
      title: 'Profile Photo',
      description: 'Square JPG or PNG, up to 2 MB.',
      fileName: upload.fileName,
      preview: preview,
      isBusy: busy,
      progress: upload.progress,
      errorText: upload.errorMessage,
      onChooseImage: upload.mediaAssetId == null
          ? uploader.chooseImage
          : uploader.replaceImage,
      onRemoveImage: upload.mediaAssetId == null ? null : uploader.removeImage,
      onRetry: upload.pendingInput == null ? null : uploader.retryUpload,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(children: [
            fields,
            const SizedBox(height: TenantAdminSpacing.lg),
            photo,
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: fields),
            const SizedBox(width: TenantAdminSpacing.lg),
            SizedBox(width: 280, child: photo),
          ],
        );
      },
    );
  }

  Widget _field(
    double width,
    String label,
    String value,
    String hint,
    ValueChanged<String> onChanged,
    String? error, {
    IconData? icon,
    bool obscureText = false,
  }) {
    return SizedBox(
      width: width,
      child: _Input(
        label: label,
        initialValue: value,
        hint: hint,
        onChanged: onChanged,
        error: error,
        icon: icon,
        obscureText: obscureText,
      ),
    );
  }
}

class _RoleStep extends ConsumerWidget {
  const _RoleStep({required this.state, required this.options});
  final AddUserWizardState state;
  final TenantUserCreateOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addUserWizardControllerProvider.notifier);
    final role = _roleFor(options, state.roleId);
    return _Panel(
      title: 'Assign Role',
      subtitle: "Select the role that defines this user's base access.",
      child: LayoutBuilder(
        builder: (context, constraints) {
          final list = Column(
            children: [
              for (final item in options.roles.where((item) => item.isActive))
                Padding(
                  padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                  child: _RoleCard(
                    role: item,
                    selected: item.id == state.roleId,
                    onTap: () => controller.setRoleId(item.id),
                  ),
                ),
              if (state.fieldErrors['roleId'] != null)
                _ErrorText(state.fieldErrors['roleId']!),
            ],
          );
          final preview = _RolePreview(role: role);
          if (constraints.maxWidth < 900) {
            return Column(children: [
              list,
              const SizedBox(height: TenantAdminSpacing.lg),
              preview,
            ]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: list),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(flex: 2, child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionStep extends ConsumerWidget {
  const _PermissionStep({
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
    final groups = options.permissionGroups;
    final role = _roleFor(options, state.roleId);
    final selectedIndex = groups.isEmpty
        ? 0
        : state.selectedPermissionGroupIndex
            .clamp(0, groups.length - 1)
            .toInt();
    final enabled =
        canOverride && options.capabilities.supportsUserPermissionOverrides;
    final ids = groups
        .expand((group) => group.permissions)
        .where((permission) => permission.isAssignable)
        .map((permission) => permission.id);

    return Column(
      children: [
        _InfoBanner(
          text: state.permissionOverrideEnabled
              ? 'Permission override is enabled.'
              : 'Permissions are inherited from the selected role.',
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _Panel(
          title: 'Configure Permissions',
          subtitle: 'Review modules and fine-tune access if allowed.',
          trailing: Switch.adaptive(
            value: state.permissionOverrideEnabled,
            onChanged: enabled
                ? (value) => controller.setPermissionOverrideEnabled(
                      value,
                      inheritedPermissionIds: ids,
                    )
                : null,
          ),
          child: groups.isEmpty
              ? const Text('No permission catalog is available.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final modules = _ModuleList(
                      groups: groups,
                      selectedIndex: selectedIndex,
                      state: state,
                      onSelected: controller.setPermissionGroupIndex,
                    );
                    final permissions = _PermissionList(
                      group: groups[selectedIndex],
                      state: state,
                      enabled: enabled && state.permissionOverrideEnabled,
                      onChanged: controller.togglePermission,
                    );
                    if (constraints.maxWidth < 820) {
                      return Column(children: [
                        modules,
                        const SizedBox(height: TenantAdminSpacing.lg),
                        permissions,
                      ]);
                    }
                    return SizedBox(
                      height: 390,
                      child: Row(children: [
                        SizedBox(width: 260, child: modules),
                        const SizedBox(width: TenantAdminSpacing.lg),
                        Expanded(child: permissions),
                      ]),
                    );
                  },
                ),
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          _MetricSummaryBar(
            items: [
              _SummaryMetric(
                icon: Icons.widgets_outlined,
                label: 'Modules',
                value: '${groups.length}',
              ),
              _SummaryMetric(
                icon: Icons.verified_user_outlined,
                label: 'Permissions',
                value: state.permissionOverrideEnabled
                    ? '${state.selectedPermissionIds.length}'
                    : '${role?.permissionCount ?? ids.length}',
              ),
              _SummaryMetric(
                icon: Icons.insights_outlined,
                label: 'Access level',
                value: _accessLevel(
                  state.permissionOverrideEnabled
                      ? state.selectedPermissionIds.length
                      : role?.permissionCount ?? ids.length,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AccessStep extends ConsumerWidget {
  const _AccessStep({required this.state, required this.options});
  final AddUserWizardState state;
  final TenantUserCreateOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(addUserWizardControllerProvider.notifier);
    final outlets = _availableOutlets(options, state).toList();
    final tills = _availableTills(options, state).toList();
    final outletPanel = _Panel(
      title: 'Outlet Access',
      subtitle: 'Choose where this user can work.',
      child: Column(
        children: [
          _ChoiceTile(
            title: 'All Outlets',
            subtitle: 'Access all active tenant outlets.',
            selected:
                state.outletAccessMode == AddUserOutletAccessMode.allOutlets,
            onTap: () => controller
                .setOutletAccessMode(AddUserOutletAccessMode.allOutlets),
          ),
          _ChoiceTile(
            title: 'Selected Outlets',
            subtitle: 'Access only selected outlets.',
            selected: state.outletAccessMode ==
                AddUserOutletAccessMode.selectedOutlets,
            onTap: () => controller
                .setOutletAccessMode(AddUserOutletAccessMode.selectedOutlets),
          ),
          if (options.capabilities.supportsNoOutletAccess)
            _ChoiceTile(
              title: 'No Outlet Access',
              subtitle: 'Create without outlet access.',
              selected: state.outletAccessMode ==
                  AddUserOutletAccessMode.noOutletAccess,
              onTap: () => controller
                  .setOutletAccessMode(AddUserOutletAccessMode.noOutletAccess),
            ),
          if (state.outletAccessMode == AddUserOutletAccessMode.selectedOutlets)
            for (final outlet in options.outlets)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.selectedOutletIds.contains(outlet.id),
                title: Text(outlet.name),
                subtitle: Text(outlet.code),
                activeColor: TenantAdminColors.primary,
                onChanged: (value) => controller.toggleOutlet(
                  outlet.id,
                  value ?? false,
                  tills: options.tills,
                ),
              ),
          if (state.fieldErrors['outletIds'] != null)
            _ErrorText(state.fieldErrors['outletIds']!),
          if (options.capabilities.supportsDefaultOutlet &&
              state.outletAccessMode != AddUserOutletAccessMode.noOutletAccess)
            _Dropdown<String>(
              label: 'Default Outlet (Optional)',
              value: state.defaultOutletId,
              items: outlets
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ))
                  .toList(),
              onChanged: controller.setDefaultOutlet,
              error: state.fieldErrors['defaultOutletId'],
            ),
        ],
      ),
    );
    final tillPanel = _Panel(
      title: 'Till Access',
      subtitle: 'Choose which tills are available.',
      child: Column(
        children: [
          _ChoiceTile(
            title: 'All Accessible Tills',
            subtitle: 'Access all tills within outlet scope.',
            selected: state.tillAccessMode ==
                AddUserTillAccessMode.allAccessibleTills,
            onTap:
                state.outletAccessMode == AddUserOutletAccessMode.noOutletAccess
                    ? null
                    : () => controller.setTillAccessMode(
                          AddUserTillAccessMode.allAccessibleTills,
                        ),
          ),
          if (options.capabilities.supportsExplicitTillAccess)
            _ChoiceTile(
              title: 'Selected Tills',
              subtitle: 'Access only selected tills.',
              selected:
                  state.tillAccessMode == AddUserTillAccessMode.selectedTills,
              onTap: () => controller
                  .setTillAccessMode(AddUserTillAccessMode.selectedTills),
            ),
          _ChoiceTile(
            title: 'No Till Access',
            subtitle: 'No POS till access.',
            selected:
                state.tillAccessMode == AddUserTillAccessMode.noTillAccess,
            onTap: () => controller
                .setTillAccessMode(AddUserTillAccessMode.noTillAccess),
          ),
          if (state.tillAccessMode == AddUserTillAccessMode.selectedTills)
            for (final till in tills)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: state.selectedTillIds.contains(till.id),
                title: Text(till.name),
                subtitle: Text(till.code),
                activeColor: TenantAdminColors.primary,
                onChanged: (value) =>
                    controller.toggleTill(till.id, value ?? false),
              ),
          if (state.fieldErrors['tillIds'] != null)
            _ErrorText(state.fieldErrors['tillIds']!),
          if (options.capabilities.supportsDefaultTill &&
              state.tillAccessMode != AddUserTillAccessMode.noTillAccess)
            _Dropdown<String>(
              label: 'Default Till (Optional)',
              value: state.defaultTillId,
              items: tills
                  .where((till) =>
                      state.tillAccessMode !=
                          AddUserTillAccessMode.selectedTills ||
                      state.selectedTillIds.contains(till.id))
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ))
                  .toList(),
              onChanged: controller.setDefaultTill,
              error: state.fieldErrors['defaultTillId'],
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Outlet, Till & Access Scope',
          subtitle: 'Configure outlet and till access for this user.',
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(children: [
              outletPanel,
              const SizedBox(height: TenantAdminSpacing.lg),
              tillPanel,
            ]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: outletPanel),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(child: tillPanel),
            ],
          );
        }),
        const SizedBox(height: TenantAdminSpacing.lg),
        _MetricSummaryBar(
          items: [
            _SummaryMetric(
              icon: Icons.storefront_outlined,
              label: 'Outlet scope',
              value: switch (state.outletAccessMode) {
                AddUserOutletAccessMode.allOutlets => 'All outlets',
                AddUserOutletAccessMode.selectedOutlets =>
                  '${state.selectedOutletIds.length} selected',
                AddUserOutletAccessMode.noOutletAccess => 'No access',
              },
            ),
            _SummaryMetric(
              icon: Icons.point_of_sale_outlined,
              label: 'Till scope',
              value: switch (state.tillAccessMode) {
                AddUserTillAccessMode.allAccessibleTills => 'All accessible',
                AddUserTillAccessMode.selectedTills =>
                  '${state.selectedTillIds.length} selected',
                AddUserTillAccessMode.noTillAccess => 'No access',
              },
            ),
            _SummaryMetric(
              icon: Icons.shield_outlined,
              label: 'Role',
              value: _roleFor(options, state.roleId)?.name ?? 'Not selected',
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.options});
  final AddUserWizardState state;
  final TenantUserCreateOptions options;

  @override
  Widget build(BuildContext context) {
    final role = _roleFor(options, state.roleId);
    final cards = [
      _ReviewCard(
          icon: Icons.person_outline,
          title: '1. User Information',
          rows: {
            'Full Name': state.fullName,
            'Email': state.email,
            'Phone': state.phone.isEmpty ? 'Not provided' : state.phone,
            'Employee ID':
                state.employeeId.isEmpty ? 'Not provided' : state.employeeId,
            'Status': state.accountStatusApiValue,
            if (state.accountStatus == AddUserAccountStatus.active)
              'Password': 'Configured securely',
          }),
      _ReviewCard(
          icon: Icons.admin_panel_settings_outlined,
          title: '2. Role & Permissions',
          rows: {
            'Selected Role': role?.name ?? 'Not selected',
            'Role Permissions': (role?.permissionCount ?? 0).toString(),
            'Override': state.permissionOverrideEnabled
                ? '${state.selectedPermissionIds.length} selected'
                : 'Inherited',
          }),
      _ReviewCard(
          icon: Icons.storefront_outlined,
          title: '3. Outlets & Tills',
          rows: {
            'Outlet Scope': state.outletAccessMode.apiValue,
            'Selected Outlets': state.selectedOutletIds.length.toString(),
            'Till Scope': state.tillAccessMode.apiValue,
            'Selected Tills': state.selectedTillIds.length.toString(),
          }),
      _ReviewCard(
          icon: Icons.lock_outline,
          title: '4. Security & Invitation',
          rows: {
            'Access Method': switch (state.accountStatus) {
              AddUserAccountStatus.invited => 'Email invitation',
              AddUserAccountStatus.active => 'Email and created password',
              AddUserAccountStatus.inactive => 'Login disabled',
            },
            'Account Status': state.accountStatusApiValue,
            'Profile Photo':
                state.profileMediaAssetId == null ? 'Not provided' : 'Selected',
          }),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Security & Review',
          subtitle: 'Review all details before creating the user.',
        ),
        if (state.generalError != null) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _ErrorText(state.generalError!),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth >= 900
              ? (constraints.maxWidth - TenantAdminSpacing.lg) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: TenantAdminSpacing.lg,
            runSpacing: TenantAdminSpacing.lg,
            children: [
              for (final card in cards) SizedBox(width: width, child: card),
            ],
          );
        }),
        const SizedBox(height: TenantAdminSpacing.lg),
        _ReadyPanel(
          checks: [
            state.fullName.trim().isNotEmpty && state.email.trim().isNotEmpty,
            role != null,
            state.outletAccessMode != AddUserOutletAccessMode.selectedOutlets ||
                state.selectedOutletIds.isNotEmpty,
            state.tillAccessMode != AddUserTillAccessMode.selectedTills ||
                state.selectedTillIds.isNotEmpty,
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _SectionTitle(title: title, subtitle: subtitle)),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: TenantAdminSpacing.md),
          Material(
            color: Colors.transparent,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
          if (subtitle != null) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(subtitle!, style: TenantAdminTextStyles.muted(context)),
          ],
        ],
      );
}

class _StepEyebrow extends StatelessWidget {
  const _StepEyebrow({
    required this.current,
    required this.total,
    required this.label,
  });

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= TenantAdminBreakpoints.tablet) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: TenantAdminSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
                ),
                child: Text(
                  'Step $current of $total',
                  style: const TextStyle(
                    color: TenantAdminColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.icon,
    this.error,
    this.obscureText = false,
  });
  final String label;
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final String? error;
  final bool obscureText;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TenantAdminTextStyles.fieldLabel(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            key: ValueKey(label),
            initialValue: initialValue,
            obscureText: obscureText,
            enableSuggestions: !obscureText,
            autocorrect: !obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon),
              errorText: error,
            ),
          ),
        ],
      );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TenantAdminTextStyles.fieldLabel(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          InputDecorator(
            decoration:
                const InputDecoration(suffixIcon: Icon(Icons.lock_outline)),
            child: Text(value, style: TenantAdminTextStyles.muted(context)),
          ),
        ],
      );
}

class _StatusField extends StatelessWidget {
  const _StatusField({
    required this.state,
    required this.options,
    required this.canInvite,
    required this.onChanged,
  });
  final AddUserWizardState state;
  final TenantUserCreateOptions options;
  final bool canInvite;
  final ValueChanged<AddUserAccountStatus> onChanged;
  @override
  Widget build(BuildContext context) {
    final statuses =
        options.supportedStatuses.map((item) => item.toUpperCase()).toSet();
    final segments = <ButtonSegment<AddUserAccountStatus>>[
      if (statuses.contains('INVITED') && canInvite)
        const ButtonSegment(
          value: AddUserAccountStatus.invited,
          label: Text('Invited'),
          icon: Icon(Icons.mail_outline),
        ),
      if (statuses.contains('ACTIVE') &&
          options.capabilities.supportsDirectActiveCreation &&
          options.capabilities.supportsTemporaryPassword)
        const ButtonSegment(
          value: AddUserAccountStatus.active,
          label: Text('Active'),
          icon: Icon(Icons.check_circle_outline),
        ),
      if (statuses.contains('INACTIVE'))
        const ButtonSegment(
          value: AddUserAccountStatus.inactive,
          label: Text('Inactive'),
          icon: Icon(Icons.pause_circle_outline),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Status *',
            style: TenantAdminTextStyles.fieldLabel(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (segments.isEmpty)
          const Text('No supported account status is available.')
        else
          SegmentedButton<AddUserAccountStatus>(
            segments: segments,
            selected: segments.any((item) => item.value == state.accountStatus)
                ? {state.accountStatus}
                : {segments.first.value},
            onSelectionChanged: (values) => onChanged(values.first),
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });
  final RoleOption role;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TenantAdminPressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: AnimatedContainer(
            duration: TenantAdminMotion.fast,
            curve: TenantAdminMotion.standard,
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: selected
                  ? TenantAdminColors.secondary
                  : TenantAdminColors.surface,
              border: Border.all(
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? TenantAdminColors.primary.withValues(alpha: 0.12)
                      : TenantAdminColors.subtleBackground,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: selected
                      ? TenantAdminColors.primary
                      : TenantAdminColors.mutedText,
                  size: 28,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.name,
                        style: TenantAdminTextStyles.cardTitle(context)),
                    Text(role.roleDescription ?? role.code,
                        style: TenantAdminTextStyles.muted(context)),
                    Text(
                      '${role.moduleCount} modules • '
                      '${role.permissionCount} permissions',
                      style: TenantAdminTextStyles.helperText(context),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.mutedText,
              ),
            ]),
          ),
        ),
      );
}

class _RolePreview extends StatelessWidget {
  const _RolePreview({required this.role});
  final RoleOption? role;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: BoxDecoration(
          color: role == null
              ? TenantAdminColors.subtleBackground
              : TenantAdminColors.successSurface,
          border: Border.all(
            color: role == null
                ? TenantAdminColors.border
                : TenantAdminColors.successBorder,
          ),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: role == null
            ? const Text('Select a role to preview inherited access.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: TenantAdminColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: TenantAdminColors.success,
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permission Inheritance',
                              style: TenantAdminTextStyles.cardTitle(context),
                            ),
                            Text(
                              role!.name,
                              style: TenantAdminTextStyles.muted(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  for (final module in role!.modulePreview)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: TenantAdminColors.success, size: 18),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        Expanded(child: Text(module)),
                      ]),
                    ),
                ],
              ),
      );
}

class _ModuleList extends StatelessWidget {
  const _ModuleList({
    required this.groups,
    required this.selectedIndex,
    required this.state,
    required this.onSelected,
  });
  final List<PermissionGroup> groups;
  final int selectedIndex;
  final AddUserWizardState state;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final count = state.permissionOverrideEnabled
                ? group.permissions
                    .where(
                        (item) => state.selectedPermissionIds.contains(item.id))
                    .length
                : group.permissions.length;
            return ListTile(
              selected: index == selectedIndex,
              selectedTileColor: TenantAdminColors.secondary,
              title: Text(group.groupName),
              trailing: Text('$count/${group.permissions.length}'),
              onTap: () => onSelected(index),
            );
          },
        ),
      );
}

class _PermissionList extends StatelessWidget {
  const _PermissionList({
    required this.group,
    required this.state,
    required this.enabled,
    required this.onChanged,
  });
  final PermissionGroup group;
  final AddUserWizardState state;
  final bool enabled;
  final void Function(String, bool) onChanged;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: group.permissions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = group.permissions[index];
            final checked = state.permissionOverrideEnabled
                ? state.selectedPermissionIds.contains(item.id)
                : true;
            return CheckboxListTile(
              value: checked,
              activeColor: TenantAdminColors.primary,
              title: Text(item.displayName),
              subtitle: Text(item.description ?? item.code),
              secondary: item.isLocked ? const Icon(Icons.lock_outline) : null,
              onChanged: enabled && item.isAssignable && !item.isLocked
                  ? (value) => onChanged(item.id, value ?? false)
                  : null,
            );
          },
        ),
      );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: TenantAdminMotion.fast,
        margin: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? TenantAdminColors.secondary : Colors.transparent,
          border: Border.all(
            color: selected
                ? TenantAdminColors.primary.withValues(alpha: 0.45)
                : TenantAdminColors.border,
          ),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: TenantAdminSpacing.xs,
            ),
            leading: Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.mutedText,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: onTap,
          ),
        ),
      );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.error,
  });
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? error;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TenantAdminTextStyles.fieldLabel(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          DropdownButtonFormField<T>(
            initialValue:
                items.any((item) => item.value == value) ? value : null,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(errorText: error),
          ),
        ],
      );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.rows,
  });
  final IconData icon;
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.secondary,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: TenantAdminColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: TenantAdminTextStyles.cardTitle(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            for (final entry in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                child: Row(children: [
                  SizedBox(
                    width: 120,
                    child: Text(entry.key,
                        style: TenantAdminTextStyles.muted(context)),
                  ),
                  Expanded(child: Text(entry.value)),
                ]),
              ),
          ],
        ),
      );
}

class _SummaryMetric {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetricSummaryBar extends StatelessWidget {
  const _MetricSummaryBar({required this.items});

  final List<_SummaryMetric> items;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: TenantAdminColors.subtleBackground,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final children = [
              for (final item in items)
                _MetricItem(item: item, compact: compact),
            ];
            if (compact) {
              return Wrap(
                spacing: TenantAdminSpacing.md,
                runSpacing: TenantAdminSpacing.md,
                children: children
                    .map(
                      (child) => SizedBox(
                        width:
                            (constraints.maxWidth - TenantAdminSpacing.md) / 2,
                        child: child,
                      ),
                    )
                    .toList(),
              );
            }
            return Row(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  Expanded(child: children[index]),
                  if (index < children.length - 1)
                    const SizedBox(
                      height: 42,
                      child: VerticalDivider(color: TenantAdminColors.border),
                    ),
                ],
              ],
            );
          },
        ),
      );
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.item, required this.compact});

  final _SummaryMetric item;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment:
            compact ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: Icon(item.icon, color: TenantAdminColors.primary, size: 20),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: TenantAdminTextStyles.muted(context)),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.cardTitle(context),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.checks});

  final List<bool> checks;

  @override
  Widget build(BuildContext context) {
    final ready = checks.every((item) => item);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: ready
            ? TenantAdminColors.info.withValues(alpha: 0.07)
            : TenantAdminColors.warningSurface,
        border: Border.all(
          color: ready
              ? TenantAdminColors.info.withValues(alpha: 0.28)
              : TenantAdminColors.warningBorder,
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ready
                  ? TenantAdminColors.info.withValues(alpha: 0.12)
                  : TenantAdminColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.check_circle_outline : Icons.info_outline,
              color: ready ? TenantAdminColors.info : TenantAdminColors.warning,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Ready to create user' : 'Review required details',
                  style: TenantAdminTextStyles.cardTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Create User performs one atomic server-side validation and save.',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.info.withValues(alpha: 0.08),
          border:
              Border.all(color: TenantAdminColors.info.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, color: TenantAdminColors.info),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(child: Text(text)),
        ]),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: const TextStyle(color: TenantAdminColors.danger, fontSize: 12),
        ),
      );
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
        ),
      );
}

RoleOption? _roleFor(TenantUserCreateOptions options, String? roleId) {
  for (final role in options.roles) {
    if (role.id == roleId) return role;
  }
  return null;
}

String _accessLevel(int permissionCount) {
  if (permissionCount >= 30) return 'High';
  if (permissionCount >= 12) return 'Standard';
  return 'Focused';
}

Iterable<UserOutletOption> _availableOutlets(
  TenantUserCreateOptions options,
  AddUserWizardState state,
) {
  if (state.outletAccessMode == AddUserOutletAccessMode.noOutletAccess) {
    return const [];
  }
  if (state.outletAccessMode == AddUserOutletAccessMode.allOutlets) {
    return options.outlets
        .where((item) => item.status.toUpperCase() == 'ACTIVE');
  }
  return options.outlets
      .where((item) => state.selectedOutletIds.contains(item.id));
}

Iterable<UserTillOption> _availableTills(
  TenantUserCreateOptions options,
  AddUserWizardState state,
) {
  final outletIds =
      _availableOutlets(options, state).map((item) => item.id).toSet();
  return options.tills.where(
    (item) =>
        outletIds.contains(item.outletId) &&
        item.status.toUpperCase() == 'ACTIVE',
  );
}
