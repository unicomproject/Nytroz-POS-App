import 'dart:convert';

Map<String, dynamic>? readJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) {
    return null;
  }

  try {
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payload = jsonDecode(decoded);

    if (payload is Map<String, dynamic>) {
      return payload;
    }
  } catch (_) {
    return null;
  }

  return null;
}

List<String> readJwtPermissionCodes(String token) {
  final payload = readJwtPayload(token);
  if (payload == null) {
    return const [];
  }

  final permissions = payload['permissions'] ?? payload['Permissions'];
  if (permissions is! Iterable) {
    return const [];
  }

  return permissions
      .map((item) {
        if (item is Map) {
          return item['permissionCode']?.toString() ??
              item['PermissionCode']?.toString() ??
              item['code']?.toString() ??
              item['Code']?.toString() ??
              '';
        }

        return item.toString();
      })
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
