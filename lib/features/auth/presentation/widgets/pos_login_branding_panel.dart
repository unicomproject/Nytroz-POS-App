import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../domain/entities/pos_login_branding.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

const _fallbackLogoAsset = 'assets/images/logo.png';
const _fallbackHeroAsset = 'assets/images/log-screen-terminal.png';

class PosLoginBrandingPanel extends StatelessWidget {
  const PosLoginBrandingPanel({
    super.key,
    required this.branding,
    required this.compact,
  });
  final PosLoginBranding branding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color =
        Color(branding.backgroundColor.posLoginColorValue ?? 0xFF000E2B);
    final logoUrl = branding.logoUrl?.trim();
    final heroUrl = branding.heroImageUrl?.trim();
    final backgroundUrl = branding.backgroundImageUrl?.trim();
    final content = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color),
        if (branding.backgroundMode == PosLoginBackgroundMode.image &&
            backgroundUrl != null &&
            backgroundUrl.isNotEmpty)
          AppCachedNetworkImage(
            imageUrl: backgroundUrl,
            fit: BoxFit.cover,
            errorWidget: ColoredBox(color: color),
          ),
        const ColoredBox(color: Color(0x66000000)),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 48,
              vertical: compact ? 20 : 40,
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: LayoutBuilder(
                    builder: (context, constraints) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: compact ? 64 : 92,
                              child: logoUrl != null && logoUrl.isNotEmpty
                                  ? AppCachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.contain,
                                      errorWidget: const SizedBox.shrink(),
                                    )
                                  : Image.asset(
                                      _fallbackLogoAsset,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            if (branding.brandDisplayName
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                branding.brandDisplayName.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 30 : 46,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ],
                            if (branding.systemName.trim().isNotEmpty) ...[
                              SizedBox(height: compact ? 6 : 8),
                              Text(
                                branding.systemName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 17 : 23,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ],
                            SizedBox(height: compact ? 14 : 18),
                            Container(
                              width: 48,
                              height: 3,
                              color: TenantAdminColors.posOnboardingAccent,
                            ),
                            if (branding.description.trim().isNotEmpty) ...[
                              SizedBox(height: compact ? 14 : 18),
                              Text(
                                branding.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 16 : 21,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: heroUrl != null && heroUrl.isNotEmpty
                      ? AppCachedNetworkImage(
                          imageUrl: heroUrl,
                          fit: BoxFit.contain,
                          errorWidget: const SizedBox.shrink(),
                        )
                      : Image.asset(
                          _fallbackHeroAsset,
                          fit: BoxFit.contain,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return _frame(content);
  }

  Widget _frame(Widget child) => ClipRRect(
        borderRadius: compact ? BorderRadius.circular(16) : BorderRadius.zero,
        child: SizedBox(
          width: double.infinity,
          height: compact ? 480 : null,
          child: child,
        ),
      );
}
