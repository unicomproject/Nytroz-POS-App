import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_api_errors.dart';
import '../widgets/user_access_section.dart';
import '../widgets/user_basic_info_section.dart';
import '../widgets/user_permission_override_panel.dart';
import '../widgets/user_profile_image_upload.dart';
import '../widgets/user_status_preview.dart';

class AddEditUserScreen extends ConsumerWidget {
  const AddEditUserScreen({super.key, this.userId});

  final String? userId;

  bool get isEdit => userId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authHeaderSyncProvider);
    final canCreate = ref.watch(userCreateAccessProvider);
    final canInvite = ref.watch(userInviteAccessProvider);
    final canOverride = ref.watch(userPermissionOverrideAccessProvider);
    final canUpdate = ref.watch(userUpdateAccessProvider);
    final optionsState = ref.watch(userCreateOptionsProvider);

    final hasAccess = isEdit ? canUpdate : (canCreate || canInvite);
    if (!hasAccess) {
      return TenantAdminPageScaffold(
        title: isEdit ? 'Edit User' : 'Add New User',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: isEdit
              ? 'You do not have permission to edit users.'
              : 'You do not have permission to add users.',
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: isEdit ? 'Edit User' : 'Add New User',
      subtitle: isEdit
          ? "Update this user's details and access."
          : 'Create a new user and assign their role and outlet access.',
      child: optionsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load form options',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(userCreateOptionsProvider),
        ),
        data: (options) {
          if (!isEdit) {
            return _UserForm(
              options: options,
              initialDetail: null,
              canInvite: canInvite,
              canOverride: canOverride,
            );
          }

          final detailState = ref.watch(userDetailProvider(userId!));
          return detailState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
            error: (error, stackTrace) => TenantAdminErrorState(
              title: 'Unable to load user',
              message: 'Please try again.',
              onRetry: () => ref.invalidate(userDetailProvider(userId!)),
            ),
            data: (detail) => _UserForm(
              options: options,
              initialDetail: detail,
              canInvite: canInvite,
              canOverride: canOverride,
              userId: userId,
            ),
          );
        },
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({
    required this.options,
    required this.initialDetail,
    required this.canInvite,
    required this.canOverride,
    this.userId,
  });

  final TenantUserCreateOptions options;
  final TenantUserDetail? initialDetail;
  final bool canInvite;
  final bool canOverride;
  final String? userId;

  bool get isEdit => userId != null;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _selectedRoleId;
  late Set<String> _selectedOutletIds;
  late bool _permissionOverrideEnabled;
  late Set<String> _overriddenPermissionIds;
  bool _sendInviteEmail = false;
  late String _status;
  String? _profileImageFileName;

  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    _fullNameController = TextEditingController(text: detail?.fullName ?? '');
    _emailController = TextEditingController(text: detail?.email ?? '');
    _phoneController = TextEditingController(text: detail?.phone ?? '');
    _selectedRoleId = detail?.roleId;
    _selectedOutletIds = detail?.outlets.map((o) => o.id).toSet() ?? {};
    _permissionOverrideEnabled = detail?.permissionOverrideEnabled ?? false;
    _overriddenPermissionIds = detail?.overriddenPermissionIds.toSet() ?? {};
    final rawStatus = detail?.status.trim().toUpperCase();
    _status = (rawStatus == null || rawStatus.isEmpty) ? 'ACTIVE' : rawStatus;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus =
        widget.isEdit ? _status : (_sendInviteEmail ? 'INVITED' : 'INACTIVE');
    final statusHelper = widget.isEdit
        ? 'Current account status for this user.'
        : (_sendInviteEmail
            ? 'An invite link will be generated for this user to set up their account.'
            : 'The user will be created as inactive until activated.');

    final formCard = Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserBasicInfoSection(
              fullNameController: _fullNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              roles: widget.options.roles,
              selectedRoleId: _selectedRoleId,
              onRoleChanged: (value) => setState(() => _selectedRoleId = value),
              enabled: !_submitting,
              backendErrors: _fieldErrors,
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            const Divider(height: 1, color: TenantAdminColors.border),
            const SizedBox(height: TenantAdminSpacing.xl),
            UserAccessSection(
              outlets: widget.options.outlets,
              selectedOutletIds: _selectedOutletIds,
              onOutletsChanged: (value) =>
                  setState(() => _selectedOutletIds = value),
              enabled: !_submitting,
              errorText: _fieldErrors['outletIds'],
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            if (widget.canOverride) ...[
              UserToggleRow(
                title: 'Permission Override',
                subtitle: _selectedRoleId == null
                    ? 'Select a role first to override individual permissions.'
                    : 'Grant this user extra permissions beyond their role.',
                value: _permissionOverrideEnabled,
                enabled: !_submitting && _selectedRoleId != null,
                onChanged: (value) =>
                    setState(() => _permissionOverrideEnabled = value),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            if (!widget.isEdit && widget.canInvite) ...[
              UserToggleRow(
                title: 'Send Invite Email',
                subtitle:
                    'Generate an invite link for this user instead of creating an inactive account.',
                value: _sendInviteEmail,
                enabled: !_submitting,
                onChanged: (value) => setState(() => _sendInviteEmail = value),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            if (widget.isEdit) ...[
              _statusDropdown(),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            UserStatusPreview(
              status: effectiveStatus,
              helperText: statusHelper,
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            UserProfileImageUpload(
              fileName: _profileImageFileName,
              onChanged: (value) =>
                  setState(() => _profileImageFileName = value),
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TenantAdminSecondaryButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                TenantAdminPrimaryButton(
                  label: widget.isEdit ? 'Save Changes' : 'Save User',
                  icon: Icons.save_outlined,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final overridePanel = widget.canOverride &&
            _permissionOverrideEnabled &&
            _selectedRoleId != null
        ? UserPermissionOverridePanel(
            groups: widget.options.permissionGroups,
            selectedPermissionIds: _overriddenPermissionIds,
            onChanged: (next) =>
                setState(() => _overriddenPermissionIds = next),
            onReset: () => setState(() {
              _permissionOverrideEnabled = false;
              _overriddenPermissionIds = {};
            }),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              formCard,
              if (overridePanel != null) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                overridePanel,
              ],
            ],
          );
        }

        if (overridePanel == null) {
          return formCard;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: formCard),
            const SizedBox(width: TenantAdminSpacing.xl),
            Expanded(flex: 1, child: overridePanel),
          ],
        );
      },
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.circle, size: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
        DropdownMenuItem(value: 'INVITED', child: Text('Invited')),
      ],
      onChanged: _submitting
          ? null
          : (value) => setState(() => _status = value ?? 'ACTIVE'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleId == null) {
      setState(() => _fieldErrors = {'roleId': 'Role is required.'});
      return;
    }

    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    final form = UserFormData(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      roleId: _selectedRoleId!,
      outletIds: _selectedOutletIds.toList(growable: false),
      permissionOverrideEnabled: _permissionOverrideEnabled,
      overriddenPermissionIds: _overriddenPermissionIds.toList(growable: false),
      sendInviteEmail: _sendInviteEmail,
      status: widget.isEdit ? _status : null,
      profileImageFileName: _profileImageFileName,
    );

    try {
      if (widget.isEdit) {
        await ref.read(updateUserProvider).call(widget.userId!, form);
        ref.invalidate(userDetailProvider(widget.userId!));
      } else {
        await ref.read(createUserProvider).call(form);
      }

      ref.invalidate(userListProvider);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'User updated successfully.'
                : 'User created successfully.',
          ),
        ),
      );
      context.go('/tenant-admin/staff');
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please sign in again.'),
            ),
          );
          context.go('/tenant-login');
        }
        return;
      }

      final fieldErrors = userValidationErrors(error);
      setState(() => _fieldErrors = fieldErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userSubmitErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
