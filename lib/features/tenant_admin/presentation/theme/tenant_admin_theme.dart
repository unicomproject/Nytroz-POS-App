import 'package:flutter/material.dart';

class TenantAdminColors {
  const TenantAdminColors._();

  static const navy = Color(0xFF071A33);
  static const navySoft = Color(0xFF0E2748);
  static const background = Color(0xFFF8FAFF);
  static const surface = Colors.white;
  static const border = Color(0xFFE5EAF4);
  static const mutedText = Color(0xFF64748B);
  static const bodyText = Color(0xFF081B3A);
  static const primary = Color(0xFF3F2BFF);
  static const primaryHover = Color(0xFF2F21D7);
  static const secondary = Color(0xFFEFF6FF);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
  static const pending = Color(0xFF7C3AED);
  static const offline = Color(0xFF94A3B8);
}

class TenantAdminSpacing {
  const TenantAdminSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class TenantAdminRadius {
  const TenantAdminRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

class TenantAdminShadows {
  const TenantAdminShadows._();

  static const card = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% opacity
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];
}

class TenantAdminBreakpoints {
  const TenantAdminBreakpoints._();

  static const mobile = 600.0;
  static const tablet = 900.0;
}

class TenantAdminInsets {
  const TenantAdminInsets._();

  static EdgeInsets pageForWidth(double width) {
    if (width < TenantAdminBreakpoints.mobile) {
      return const EdgeInsets.all(TenantAdminSpacing.lg);
    }

    if (width < TenantAdminBreakpoints.tablet) {
      return const EdgeInsets.all(TenantAdminSpacing.xl);
    }

    return const EdgeInsets.fromLTRB(24, 22, 24, 24);
  }
}

class TenantAdminTextStyles {
  const TenantAdminTextStyles._();

  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
              letterSpacing: -0.5,
            ) ??
        const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
          letterSpacing: -0.5,
        );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
              letterSpacing: -0.3,
            ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: TenantAdminColors.bodyText,
          letterSpacing: -0.3,
        );
  }

  static TextStyle muted(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.mutedText,
            ) ??
        const TextStyle(color: TenantAdminColors.mutedText);
  }
}
