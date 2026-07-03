import '../../../../../core/network/api_config.dart';

String? resolveProductImageUrl(String? imageStorageKey) {
  final key = imageStorageKey?.trim();
  if (key == null || key.isEmpty) {
    return null;
  }

  if (key.startsWith('http://') || key.startsWith('https://')) {
    return key;
  }

  final baseUrl = resolveApiBaseUrl().replaceAll(RegExp(r'/+$'), '');
  final normalizedKey = key.startsWith('/') ? key.substring(1) : key;
  return '$baseUrl/uploads/$normalizedKey';
}
