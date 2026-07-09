import 'package:web/web.dart' as web;

class PlatformLocalStorage {
  const PlatformLocalStorage._();

  static Future<String?> read(String key) async {
    final value = web.window.localStorage.getItem(key);
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  static Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  static Future<void> delete(String key) async {
    web.window.localStorage.removeItem(key);
  }
}
