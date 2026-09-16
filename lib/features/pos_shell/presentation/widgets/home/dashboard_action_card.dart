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
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isTight = cardConstraints.maxHeight < 135 ||
                          cardConstraints.maxWidth < 220;
                      final titleFontSize = isTight ? 16.0 : 20.0;
                      final verticalPadding = isTight ? 8.0 : 12.0;

                      return Row(
                        children: [
                          Expanded(
                            flex: 52,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  fallbackIcon,
                                  size: isTight ? 72 : 104,
                                  color: TenantAdminColors.surface,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 48,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                6,
                                verticalPadding,
                                12,
                                verticalPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: TenantAdminColors.surface,
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, actionConstraints) {
                                      final showDotPattern =
                                          actionConstraints.maxWidth >= 104 &&
                                              cardConstraints.maxHeight >= 120;
                                      final actionSize = isTight ||
                                              actionConstraints.maxWidth < 64
                                          ? 38.0
                                          : 46.0;

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                                size: actionSize * 0.5,
                                                color: enabled
                                                    ? accent
                                                    : TenantAdminColors.offline,
                                              ),
                                            ),
                                          ),
                                          if (showDotPattern)
                                            const DashboardDotPattern(),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
