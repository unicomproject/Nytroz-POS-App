import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';

class PresetAuthSessionNotifier extends AuthSessionNotifier {
  PresetAuthSessionNotifier(AuthSession session)
      : super(TestAuthSessionStorage()) {
    state = session;
  }
}

class TestAuthSessionStorage extends AuthSessionStorage {
  TestAuthSessionStorage()
      : super(const AppSecureStorage(FlutterSecureStorage()));

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> save(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
