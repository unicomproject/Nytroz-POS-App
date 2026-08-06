import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/hardware_remote_datasource.dart';
import '../../data/repositories/hardware_repository_impl.dart';
import '../../domain/repositories/hardware_repository.dart';

final hardwareRemoteDataSourceProvider =
    Provider<HardwareRemoteDataSource>((ref) {
  final dio = ref.watch(appDioProvider);
  return HardwareRemoteDataSourceImpl(dio);
});

final hardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  final remoteDataSource = ref.watch(hardwareRemoteDataSourceProvider);
  return HardwareRepositoryImpl(remoteDataSource);
});
