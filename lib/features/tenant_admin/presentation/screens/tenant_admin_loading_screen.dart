import 'package:flutter/material.dart';

class TenantAdminLoadingScreen extends StatelessWidget {
  const TenantAdminLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
