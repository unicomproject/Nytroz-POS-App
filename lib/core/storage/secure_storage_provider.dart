import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_secure_storage.dart';

final secureStorageProvider = Provider<AppSecureStorage>((ref) {
  return const AppSecureStorage(
    FlutterSecureStorage(
      aOptions: AndroidOptions(),
      webOptions: WebOptions(
        dbName: 'nytroz_pos_secure_storage',
        publicKey: 'nytroz_pos_secure_storage_key',
      ),
    ),
  );
});
