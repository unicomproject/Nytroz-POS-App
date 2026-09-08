import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/repositories/tenant_user_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/widgets/user_invite_actions.dart';

void main() {
  testWidgets('resends and revokes a pending invitation', (tester) async {
    final repository = _InviteRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantUserRepositoryProvider.overrideWithValue(repository),
          userInviteResendAccessProvider.overrideWithValue(true),
          userInviteRevokeAccessProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Scaffold(body: UserInviteActions(user: _invitedUser)),
        ),
      ),
    );

    await tester.tap(find.text('Resend Invite'));
    await tester.pumpAndSettle();
    expect(repository.resendCount, 1);

    await tester.tap(find.text('Revoke Invite'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Revoke Invite'));
    await tester.pumpAndSettle();
    expect(repository.revokeCount, 1);
  });

  testWidgets('shows resend and revoke actions independently', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userInviteResendAccessProvider.overrideWithValue(true),
          userInviteRevokeAccessProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          home: Scaffold(body: UserInviteActions(user: _invitedUser)),
        ),
      ),
    );

    expect(find.text('Resend Invite'), findsOneWidget);
    expect(find.text('Revoke Invite'), findsNothing);
  });
}

const _invitedUser = TenantUserDetail(
  id: 'user-1',
  fullName: 'Invited User',
  email: 'invited@oneverz.com',
  roleName: 'Cashier',
  outlets: [],
  status: 'INVITED',
  invitationStatus: 'SENT',
  permissionOverrideEnabled: false,
  overriddenPermissionIds: [],
);

class _InviteRepository implements TenantUserRepository {
  int resendCount = 0;
  int revokeCount = 0;

  @override
  Future<TenantUserDetail> resendInvite(String id) async {
    resendCount++;
    return _invitedUser;
  }

  @override
  Future<TenantUserDetail> revokeInvite(String id) async {
    revokeCount++;
    return _invitedUser;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
