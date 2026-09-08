import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../network/dio_provider.dart';
import 'pos_theme_config.dart';
import 'pos_theme_remote_datasource.dart';

final posThemeRemoteDatasourceProvider = Provider<PosThemeRemoteDatasource>(
  (ref) => PosThemeRemoteDatasource(ref.watch(appDioProvider)),
);

final posThemeRepositoryProvider = Provider<PosThemeRepository>(
  (ref) => PosThemeRepository(ref.watch(posThemeRemoteDatasourceProvider)),
);

final posThemeProvider =
    StateNotifierProvider<PosThemeController, PosThemeConfig>((ref) {
  final controller = PosThemeController(ref.read(posThemeRepositoryProvider));
  ref.listen<AuthSession?>(authSessionProvider, (_, session) {
    controller.setSession(session);
  }, fireImmediately: true);
  return controller;
});

class PosThemeController extends StateNotifier<PosThemeConfig> {
  PosThemeController(this._repository) : super(PosThemeConfig.fallback);

  final PosThemeRepository _repository;
  String? _sessionKey;
  bool _loading = false;

  Future<void> setSession(AuthSession? session) async {
    final key = session?.isAuthenticated == true ? session!.userId : null;
    if (key == _sessionKey) return;
    _sessionKey = key;
    state = PosThemeConfig.fallback;
    if (key == null || _loading) return;
    await _load(key);
  }

  Future<void> retry() async {
    final key = _sessionKey;
    if (key != null && !_loading) await _load(key);
  }

  Future<void> _load(String key) async {
    _loading = true;
    try {
      final resolved = await _repository.load();
      if (_sessionKey == key) state = resolved;
    } catch (_) {
      if (_sessionKey == key) state = PosThemeConfig.fallback;
    } finally {
      _loading = false;
    }
  }
}
