import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/widgets/user_avatar.dart';

void main() {
  const userWithImage = TenantUser(
    id: 'user-1',
    fullName: 'Kavin',
    email: 'cashier001@gmail.com',
    roleName: 'Cashier',
    outletName: 'Main Outlet',
    status: 'Active',
    profileImageUrl: 'https://example.com/cashier.jpg',
  );

  const userWithoutImage = TenantUser(
    id: 'user-2',
    fullName: 'Sarah Ahmed',
    email: 'sarah@example.com',
    roleName: 'Store Manager',
    outletName: 'Main Outlet',
    status: 'Active',
  );

  testWidgets('uses a network profile image when an absolute URL exists',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserAvatar(user: userWithImage)),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(avatar.foregroundImage, isA<NetworkImage>());
    expect((avatar.foregroundImage! as NetworkImage).url,
        'https://example.com/cashier.jpg');
    expect(find.text('K'), findsOneWidget);
  });

  testWidgets('keeps initials fallback when profile image is missing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserAvatar(user: userWithoutImage)),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(avatar.foregroundImage, isNull);
    expect(find.text('SA'), findsOneWidget);
  });

  testWidgets('keeps initials fallback for invalid profile image values',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          user: TenantUser(
            id: 'user-3',
            fullName: 'Broken Image',
            email: 'broken@example.com',
            roleName: 'Cashier',
            outletName: 'Main Outlet',
            status: 'Active',
            profileImageUrl: 'not-a-url',
          ),
        ),
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(avatar.foregroundImage, isNull);
    expect(find.text('BI'), findsOneWidget);
  });
}
