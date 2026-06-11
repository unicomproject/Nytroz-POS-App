import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import '../../data/datasources/tenant_admin_auth_remote_datasource.dart';
import '../../data/repositories/tenant_admin_auth_repository_impl.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../../domain/repositories/tenant_admin_auth_repository.dart';
import '../../domain/usecases/get_payment_summary.dart';
import '../../domain/usecases/start_payment.dart';
import '../../domain/usecases/verify_payment_status.dart';

final tenantAdminAuthRemoteDatasourceProvider =
    Provider<TenantAdminAuthRemoteDatasource>((ref) {
  return TenantAdminAuthRemoteDatasource(ref.watch(tenantAdminDioProvider));
});

final tenantAdminAuthRepositoryProvider =
    Provider<TenantAdminAuthRepository>((ref) {
  return TenantAdminAuthRepositoryImpl(
    ref.watch(tenantAdminAuthRemoteDatasourceProvider),
  );
});

final getPaymentSummaryProvider = Provider<GetPaymentSummary>((ref) {
  return GetPaymentSummary(ref.watch(tenantAdminAuthRepositoryProvider));
});

final startPaymentProvider = Provider<StartPayment>((ref) {
  return StartPayment(ref.watch(tenantAdminAuthRepositoryProvider));
});

final verifyPaymentStatusProvider = Provider<VerifyPaymentStatus>((ref) {
  return VerifyPaymentStatus(ref.watch(tenantAdminAuthRepositoryProvider));
});

final paymentSummaryProvider =
    FutureProvider.family<TenantPaymentSummary, String>((ref, paymentToken) {
  return ref.watch(getPaymentSummaryProvider).call(paymentToken);
});
