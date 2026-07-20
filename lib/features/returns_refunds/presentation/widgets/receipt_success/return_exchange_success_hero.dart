import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnExchangeSuccessHero extends StatelessWidget {
  const ReturnExchangeSuccessHero({
    super.key,
    required this.heading,
    required this.supportingMessage,
  });

  final String heading;
  final String supportingMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: TenantAdminColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: TenantAdminColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: TenantAdminColors.success.withValues(alpha: 0.7),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 6,
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: TenantAdminColors.success.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: TenantAdminColors.bodyText,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          supportingMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
