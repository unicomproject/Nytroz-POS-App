import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Large blue-gradient "Start a Sale" hero card. The entire card is the button.
class PosStartSaleHeroCard extends StatelessWidget {
  const PosStartSaleHeroCard({
    super.key,
    this.title = 'Start a Sale',
    this.description =
        'Tap anywhere on this card to start a new sale and serve your customer.',
    this.isEnabled = true,
    this.disabledMessage,
    this.onStartSale,
  });

  final String title;
  final String description;
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
        final canTap = isEnabled && onStartSale != null;

        return SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              boxShadow: TenantAdminShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canTap ? onStartSale : null,
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
                          isCompact || tightHeight
                              ? TenantAdminSpacing.lg
                              : TenantAdminSpacing.xxl,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  isCompact ? 270 : constraints.maxWidth * 0.58,
                            ),
                            child: _HeroCopy(
                              isEnabled: isEnabled,
                              disabledMessage: disabledMessage,
                              onStartSale: onStartSale,
                              title: title,
                              description: description,
                              compact: isCompact || tightHeight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
    required this.onStartSale,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final bool isEnabled;
  final String? disabledMessage;
  final VoidCallback? onStartSale;
  final String title;
  final String description;
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
        if (!isEnabled && disabledMessage != null) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            disabledMessage!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        ElevatedButton.icon(
          onPressed: isEnabled ? onStartSale : null,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Start New Sale'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}
