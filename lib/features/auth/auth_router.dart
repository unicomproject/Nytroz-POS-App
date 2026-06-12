import 'package:go_router/go_router.dart';

import 'presentation/screens/billing_summary_screen.dart';
import 'presentation/screens/payment_link_landing_screen.dart';
import 'presentation/screens/payment_processing_screen.dart';
import 'presentation/screens/payment_success_screen.dart';
import 'presentation/screens/set_password_screen.dart';
import 'presentation/screens/setup_link_validation_screen.dart';
import 'presentation/screens/setup_success_screen.dart';
import 'presentation/screens/login_screen.dart';

List<RouteBase> authRoutes() {
  return [
    GoRoute(
      path: '/tenant-admin/payment/processing',
      builder: (context, state) => PaymentProcessingScreen(
        paymentToken: state.uri.queryParameters['paymentToken'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tenant-admin/payment/success',
      builder: (context, state) => const PaymentSuccessScreen(),
    ),
    GoRoute(
      path: '/tenant-admin/payment/:paymentToken/summary',
      builder: (context, state) => BillingSummaryScreen(
        paymentToken: state.pathParameters['paymentToken'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tenant-admin/payment/:paymentToken',
      builder: (context, state) => PaymentLinkLandingScreen(
        paymentToken: state.pathParameters['paymentToken'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tenant-admin/setup/success',
      builder: (context, state) => const SetupSuccessScreen(),
    ),
    GoRoute(
      path: '/tenant-admin/setup/:setupToken',
      builder: (context, state) => SetupLinkValidationScreen(
        setupToken: state.pathParameters['setupToken'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tenant-admin/setup/:setupToken/password',
      builder: (context, state) => SetPasswordScreen(
        setupToken: state.pathParameters['setupToken'] ?? '',
      ),
    ),
    GoRoute(
      path: '/tenant-admin/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ];
}
