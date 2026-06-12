import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../application/usecases/get_payment_summary.dart';
import '../../application/usecases/start_payment.dart';
import '../../application/usecases/verify_payment_status.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(appDioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDatasourceProvider),
  );
});

final getPaymentSummaryProvider = Provider<GetPaymentSummary>((ref) {
  return GetPaymentSummary(ref.watch(authRepositoryProvider));
});

final startPaymentProvider = Provider<StartPayment>((ref) {
  return StartPayment(ref.watch(authRepositoryProvider));
});

final verifyPaymentStatusProvider = Provider<VerifyPaymentStatus>((ref) {
  return VerifyPaymentStatus(ref.watch(authRepositoryProvider));
});

final paymentSummaryProvider =
    FutureProvider.family<TenantPaymentSummary, String>((ref, paymentToken) {
  return ref.watch(getPaymentSummaryProvider).call(paymentToken);
});
