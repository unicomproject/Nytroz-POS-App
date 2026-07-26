import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'dashboard_dot_pattern.dart';

class PosHomeActionTile extends StatelessWidget {
  const PosHomeActionTile({
    super.key,
    required this.title,
    required this.assetPath,
    required this.fallbackIcon,
    required this.colors,
    required this.accent,
    required this.enabled,
    required this.onPressed,
    this.disabledReason,
  });

  final String title;
  final String assetPath;
  final IconData fallbackIcon;
  final List<Color> colors;
  final Color accent;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: title,
      hint: enabled ? null : disabledReason,
      child: Tooltip(
        message: enabled ? title : disabledReason ?? title,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          clipBehavior: Clip.antiAlias,
          elevation: enabled ? 2 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: TenantAdminColors.surface.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              splashColor: TenantAdminColors.surface.withValues(alpha: 0.16),
              highlightColor: TenantAdminColors.posHomeDarkBackground
                  .withValues(alpha: 0.1),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -35,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            TenantAdminColors.surface.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 56,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Icon(
                              fallbackIcon,
                              size: 104,
                              color: TenantAdminColors.surface,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 44,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: TenantAdminColors.surface,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                      ),
                                ),
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final showDotPattern =
                                      constraints.maxWidth >= 92;
                                  final actionSize =
                                      constraints.maxWidth < 56 ? 40.0 : 50.0;

                                  return Row(
                                    children: [
                                      SizedBox.square(
                                        dimension: actionSize,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: TenantAdminColors.surface,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: enabled
                                                  ? accent
                                                  : TenantAdminColors.offline,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: enabled
                                                ? accent
                                                : TenantAdminColors.offline,
                                          ),
                                        ),
                                      ),
                                      if (showDotPattern) ...[
                                        const Spacer(),
                                        const DashboardDotPattern(),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!enabled)
                    Positioned.fill(
                      child: ColoredBox(
                        color: TenantAdminColors.posHomeDarkBackground
                            .withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
