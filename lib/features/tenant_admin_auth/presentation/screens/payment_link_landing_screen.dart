import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_page_shell.dart';

class PaymentLinkLandingScreen extends StatefulWidget {
  const PaymentLinkLandingScreen({
    super.key,
    required this.paymentToken,
  });

  final String paymentToken;

  @override
  State<PaymentLinkLandingScreen> createState() =>
      _PaymentLinkLandingScreenState();
}

class _PaymentLinkLandingScreenState extends State<PaymentLinkLandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.go('/tenant-admin/payment/${widget.paymentToken}/summary');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AuthPageShell(
      title: 'Opening payment link',
      subtitle: 'Please wait while we prepare your billing summary.',
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
