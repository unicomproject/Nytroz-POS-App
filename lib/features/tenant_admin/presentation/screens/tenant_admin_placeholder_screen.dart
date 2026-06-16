import 'package:flutter/material.dart';

import '../widgets/tenant_admin_page_scaffold.dart';

class TenantAdminPlaceholderScreen extends StatelessWidget {
  const TenantAdminPlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return TenantAdminPageScaffold(
      title: title,
      subtitle:
          subtitle ?? 'This Tenant Admin screen is ready for implementation.',
      child: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
