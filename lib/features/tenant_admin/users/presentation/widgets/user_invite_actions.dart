import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/tenant_user.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../utils/user_api_errors.dart';

class UserInviteActions extends ConsumerStatefulWidget {
  const UserInviteActions({super.key, required this.user});

  final TenantUserDetail user;

  @override
  ConsumerState<UserInviteActions> createState() => _UserInviteActionsState();
}

class _UserInviteActionsState extends ConsumerState<UserInviteActions> {
  bool _busy = false;

  bool get _hasPendingInvite {
    final invitation = widget.user.invitationStatus?.trim().toUpperCase() ?? '';
    return invitation == 'PENDING' ||
        invitation == 'SENT' ||
        (invitation.isEmpty && widget.user.status.toUpperCase() == 'INVITED');
  }

  @override
  Widget build(BuildContext context) {
    final canResend = ref.watch(userInviteResendAccessProvider);
    final canRevoke = ref.watch(userInviteRevokeAccessProvider);
    if ((!canResend && !canRevoke) || !_hasPendingInvite) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        if (canResend)
          TenantAdminSecondaryButton(
            label: 'Resend Invite',
            icon: Icons.forward_to_inbox_outlined,
            loading: _busy,
            onPressed: _busy ? null : _resend,
          ),
        if (canRevoke)
          TenantAdminSecondaryButton(
            label: 'Revoke Invite',
            icon: Icons.link_off_outlined,
            onPressed: _busy ? null : _revoke,
          ),
      ],
    );
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ref.read(resendUserInviteProvider).call(widget.user.id);
      _refreshUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation resent to ${widget.user.email}.')),
        );
      }
    } on DioException catch (error) {
      _showError(userSubmitErrorMessage(error));
    } catch (_) {
      _showError('Unable to resend the invitation. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke invitation'),
        content: Text(
          'Revoke the pending invitation for ${widget.user.email}? The existing invite link will stop working.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke Invite'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(revokeUserInviteProvider).call(widget.user.id);
      _refreshUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invitation for ${widget.user.email} revoked.')),
        );
      }
    } on DioException catch (error) {
      _showError(userSubmitErrorMessage(error));
    } catch (_) {
      _showError('Unable to revoke the invitation. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshUserData() {
    ref.invalidate(userDetailProvider(widget.user.id));
    ref.invalidate(userListProvider);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
