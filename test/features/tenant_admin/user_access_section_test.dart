import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/domain/entities/tenant_user.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/widgets/user_access_section.dart';

void main() {
  testWidgets('renders explicit outlet and till access controls',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserAccessSection(
              outlets: const [
                UserOutletOption(
                  id: 'outlet-1',
                  name: 'Main Store',
                  code: 'MAIN',
                  status: 'ACTIVE',
                ),
              ],
              tills: const [
                UserTillOption(
                  id: 'till-1',
                  outletId: 'outlet-1',
                  name: 'Front Till',
                  code: 'FT-01',
                  status: 'ACTIVE',
                ),
              ],
              outletAccessScope: 'SELECTED_OUTLETS',
              selectedOutletIds: const {'outlet-1'},
              defaultOutletId: 'outlet-1',
              tillAccessScope: 'SELECTED_TILLS',
              selectedTillIds: const {'till-1'},
              defaultTillId: 'till-1',
              supportedOutletAccessScopes: const [
                'ALL_OUTLETS',
                'SELECTED_OUTLETS',
                'NO_OUTLET_ACCESS',
              ],
              supportedTillAccessScopes: const [
                'ALL_ACCESSIBLE_TILLS',
                'SELECTED_TILLS',
                'NO_TILL_ACCESS',
              ],
              supportsDefaultOutlet: true,
              supportsDefaultTill: true,
              onOutletScopeChanged: (_) {},
              onOutletsChanged: (_) {},
              onDefaultOutletChanged: (_) {},
              onTillScopeChanged: (_) {},
              onTillsChanged: (_) {},
              onDefaultTillChanged: (_) {},
              enabled: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Outlet & Till Access'), findsOneWidget);
    expect(find.text('Selected outlets only'), findsOneWidget);
    expect(find.text('Selected tills only'), findsOneWidget);
    expect(find.text('Main Store'), findsNWidgets(2));
    expect(find.text('Front Till (FT-01)'), findsOneWidget);
  });
}
