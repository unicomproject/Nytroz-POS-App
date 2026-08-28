import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import 'pos_theme_config.dart';

class PosThemeRemoteDatasource {
  const PosThemeRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosThemeDto> load() async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.posTheme);
    return PosThemeDto.fromJson(response.data ?? const {});
  }
}

class PosThemeRepository {
  const PosThemeRepository(this._remote);

  final PosThemeRemoteDatasource _remote;

  Future<PosThemeConfig> load() async =>
      PosThemeConfig.fromDto(await _remote.load());
}
