import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/core/storage/secure_storage_provider.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/workspace/domain/workspace_access.dart';
import 'package:nytroz_pos/features/workspace/presentation/providers/workspace_selection_provider.dart';

void main() {
  test('persists and restores a valid remembered workspace', () async {
    final storage = _MemorySecureStorage();
    final first = _container(storage);
    addTearDown(first.dispose);

    await _waitForPreference(first);
    final saved = await first.read(workspaceSelectionProvider.notifier).select(
          AppWorkspace.pos,
          rememberChoice: true,
        );

    expect(saved, isTrue);
    expect(storage.values['workspace.preference.user-1'], 'pos');

    final restored = _container(storage);
    addTearDown(restored.dispose);
    await _waitForPreference(restored);

    expect(
      restored.read(workspaceSelectionProvider).selected,
      AppWorkspace.pos,
    );
    expect(restored.read(workspaceSelectionProvider).rememberChoice, isTrue);
  });

  test('does not restore a workspace removed by current permissions', () async {
    final storage = _MemorySecureStorage()
      ..values['workspace.preference.user-1'] = 'tenantAdmin';
    final container = _container(storage, session: _posOnlySession);
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(
        container.read(workspaceSelectionProvider).selected, AppWorkspace.pos);
    expect(container.read(workspaceSelectionProvider).rememberChoice, isFalse);
  });
}

Future<void> _waitForPreference(ProviderContainer container) async {
  container.read(workspaceSelectionProvider);
  for (var attempt = 0; attempt < 10; attempt++) {
    if (!container.read(workspaceSelectionProvider).isPreferenceLoading) return;
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _container(
  _MemorySecureStorage storage, {
  AuthSession session = _dualSession,
}) =>
    ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        authSessionStorageProvider.overrideWithValue(_EmptySessionStorage()),
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(session),
        ),
      ],
    );

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session)
      : super(_EmptySessionStorage()) {
    state = session;
  }
}

class _EmptySessionStorage extends AuthSessionStorage {
  _EmptySessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

class _MemorySecureStorage extends AppSecureStorage {
  _MemorySecureStorage() : super(const FlutterSecureStorage());

  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

const _dualSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userDisplayName: 'Multi User',
  permissionCodes: ['tenant.dashboard.view', 'pos.home.view'],
);

const _posOnlySession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userDisplayName: 'Cashier',
  permissionCodes: ['pos.home.view'],
);
