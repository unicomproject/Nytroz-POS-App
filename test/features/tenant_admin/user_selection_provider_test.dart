import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/users/presentation/providers/tenant_user_providers.dart';

void main() {
  test('selected user starts empty and tracks the current selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(selectedUserIdProvider), isNull);

    container.read(selectedUserIdProvider.notifier).state = 'user-b';

    expect(container.read(selectedUserIdProvider), 'user-b');
  });
}
