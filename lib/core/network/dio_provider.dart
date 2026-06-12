import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDioProvider = Provider<Dio>((ref) {
  throw UnimplementedError(
    'Override appDioProvider with the centrally configured Dio client.',
  );
});
