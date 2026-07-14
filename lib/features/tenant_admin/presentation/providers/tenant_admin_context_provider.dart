import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../application/usecases/get_tenant_admin_context.dart';
import '../../data/datasources/tenant_admin_remote_datasource.dart';
import '../../data/repositories/tenant_admin_repository_impl.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/errors/tenant_admin_context_exception.dart';
import '../../domain/repositories/tenant_admin_repository.dart';

final tenantAdminRemoteDatasourceProvider =
    Provider<TenantAdminRemoteDatasource>((ref) {
  return TenantAdminRemoteDatasource(ref.watch(appDioProvider));
});

final tenantAdminRepositoryProvider = Provider<TenantAdminRepository>((ref) {
  return TenantAdminRepositoryImpl(
    ref.watch(tenantAdminRemoteDatasourceProvider),
  );
});

final getTenantAdminContextProvider = Provider<GetTenantAdminContext>((ref) {
  return GetTenantAdminContext(ref.watch(tenantAdminRepositoryProvider));
});

final tenantAdminContextProvider =
    FutureProvider<TenantAdminContext>((ref) async {
  ref.watch(authHeaderSyncProvider);

  final currentSession = ref.watch(authSessionProvider);
  if (currentSession == null || !currentSession.isAuthenticated) {
    throw const TenantAdminContextException(
      code: TenantAdminContextErrorCodes.authRequired,
      message: 'Sign in is required to load tenant admin access.',
    );
  }

  final session = currentSession.isExpired
      ? await ref
          .read(authSessionProvider.notifier)
          .ensureFreshSession(ref.read(appDioProvider))
      : currentSession;

  if (session == null || !session.isAuthenticated) {
    throw const TenantAdminContextException(
      code: TenantAdminContextErrorCodes.authRequired,
      message: 'Sign in is required to load tenant admin access.',
    );
  }

  try {
    return await ref.read(getTenantAdminContextProvider).call();
  } on DioException catch (error) {
    final statusCode = error.response?.statusCode;
    final apiMessage = _readApiMessage(error.response?.data);

    if (statusCode == 401) {
      await ref.read(authSessionProvider.notifier).clear();

      throw TenantAdminContextException(
        code: TenantAdminContextErrorCodes.authRequired,
        message: apiMessage ?? 'Authentication expired. Sign in again.',
      );
    }

    if (statusCode == 403) {
      throw TenantAdminContextException(
        code: TenantAdminContextErrorCodes.accessDenied,
        message: apiMessage ??
            'Your account does not have tenant admin dashboard access.',
      );
    }

    throw TenantAdminContextException(
      code: TenantAdminContextErrorCodes.loadFailed,
      message: apiMessage ?? 'Unable to load tenant admin context.',
    );
  }
});

String? _readApiMessage(Object? data) {
  if (data is! Map) {
    return null;
  }

  final payload = Map<String, dynamic>.from(data);
  final message = payload['message']?.toString();
  if (message != null && message.trim().isNotEmpty) {
    return message;
  }

  return payload['errorCode']?.toString();
}
