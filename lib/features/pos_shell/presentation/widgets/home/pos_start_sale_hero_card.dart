import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

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
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : isCompact
                ? 300.0
                : 330.0;
        final tightHeight = height < 240;
        final imageWidthFactor = isCompact ? 0.48 : 0.52;
        final heroRadius = BorderRadius.circular(TenantAdminRadius.xl);

        return SizedBox(
          width: double.infinity,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: heroRadius,
              boxShadow: TenantAdminShadows.card,
            ),
            child: ClipRRect(
              borderRadius: heroRadius,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  const ColoredBox(
                    color: TenantAdminColors.startSaleHero,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: constraints.maxWidth * imageWidthFactor,
                    child: Image.asset(
                      'assets/images/pos_start_sale_background.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            TenantAdminColors.startSaleHero,
                            TenantAdminColors.startSaleHero.withValues(
                              alpha: 0.96,
                            ),
                            TenantAdminColors.startSaleHero.withValues(
                              alpha: 0,
                            ),
                          ],
                          stops: const [0, 0.44, 0.7],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(
                        isCompact || tightHeight
                            ? TenantAdminSpacing.lg
                            : TenantAdminSpacing.xxl,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth *
                                (isCompact ? 0.52 : 0.48),
                          ),
                          child: _HeroCopy(
                            isEnabled: isEnabled,
                            disabledMessage: disabledMessage,
                            title: title,
                            description: description,
                            buttonLabel: buttonLabel,
                            onStartSale: onStartSale,
                            compact: isCompact || tightHeight,
                          ),
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
            ? Theme.of(context).textTheme.titleLarge
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
          maxLines: compact ? 3 : 2,
          style: (compact
                  ? Theme.of(context).textTheme.bodyMedium
                  : Theme.of(context).textTheme.bodyLarge)
              ?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
        SizedBox(
            height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.xl),
        if (!compact && !isEnabled && disabledMessage != null) ...[
          Text(
            disabledMessage!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
        FilledButton(
          onPressed: isEnabled ? onStartSale : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, compact ? 44 : 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: Colors.white,
            foregroundColor: TenantAdminColors.startSaleHero,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.55),
            disabledForegroundColor:
                TenantAdminColors.startSaleHero.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_shopping_cart_rounded, size: 18),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                buttonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
