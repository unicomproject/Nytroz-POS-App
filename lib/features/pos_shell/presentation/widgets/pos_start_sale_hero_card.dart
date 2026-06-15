import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosStartSaleHeroCard extends StatelessWidget {
  const PosStartSaleHeroCard({
    super.key,
    this.title = 'Start a Sale',
    this.description =
        'Create a new transaction for any product, ticket, service or experience.',
    this.buttonLabel = 'Start New Sale',
    this.isEnabled = true,
    this.disabledMessage,
    this.onStartSale,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final bool isEnabled;
  final String? disabledMessage;
  final VoidCallback? onStartSale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < TenantAdminBreakpoints.mobile;

        return SizedBox(
          height: isCompact ? 300 : 330,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              boxShadow: TenantAdminShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/pos_start_sale_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          TenantAdminColors.navy.withValues(alpha: 0.96),
                          TenantAdminColors.navy.withValues(
                            alpha: isCompact ? 0.78 : 0.7,
                          ),
                          TenantAdminColors.primary.withValues(
                            alpha: isCompact ? 0.38 : 0.08,
                          ),
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      isCompact
                          ? TenantAdminSpacing.lg
                          : TenantAdminSpacing.xxl,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 270 : 390,
                        ),
                        child: _HeroCopy(
                          isEnabled: isEnabled,
                          disabledMessage: disabledMessage,
                          title: title,
                          description: description,
                          buttonLabel: buttonLabel,
                          onStartSale: onStartSale,
                          compact: isCompact,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.isEnabled,
    required this.disabledMessage,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onStartSale,
    this.compact = false,
  });

  final bool isEnabled;
  final String? disabledMessage;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onStartSale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final headingStyle = (compact
            ? Theme.of(context).textTheme.headlineSmall
            : Theme.of(context).textTheme.headlineMedium)
        ?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: headingStyle),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
              ),
        ),
        SizedBox(
          height: compact ? TenantAdminSpacing.lg : TenantAdminSpacing.xl,
        ),
        if (!compact && !isEnabled && disabledMessage != null) ...[
          Text(
            disabledMessage!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isEnabled ? onStartSale : null,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.surface,
              foregroundColor: TenantAdminColors.primary,
              disabledBackgroundColor:
                  TenantAdminColors.surface.withValues(alpha: 0.72),
              disabledForegroundColor:
                  TenantAdminColors.primary.withValues(alpha: 0.62),
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.xl,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
