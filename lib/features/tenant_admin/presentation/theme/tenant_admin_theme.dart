import 'package:flutter/material.dart';

class TenantAdminColors {
  const TenantAdminColors._();

  static const navy = Color(0xFF071A33);
  static const navySoft = Color(0xFF0E2748);
  static const startSaleHero = Color(0xFF001C38);
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
  static const posHomeProfileStart = Color(0xFF142C55);
  static const posHomeProfileEnd = Color(0xFF0B1C38);
  static const posHomeSaleCard = Color(0xFFE8F2FF);
  static const posHomeReturnsCard = Color(0xFFFFF0E6);
  static const posHomeCashCard = Color(0xFFE8F8F0);
  static const posHomeOrdersCard = Color(0xFFF1EBFF);
  static const posHomeHeldCard = Color(0xFFFFF7D9);
  static const posHomeEndShiftCard = Color(0xFFFFE9ED);
  static const posHomeDot = Color(0x29081B3A);
  static const posHomeDarkBackground = Color(0xFF030303);
  static const posHomeDarkSurface = Color(0xFF101010);
  static const posHomeDarkBorder = Color(0xFF555555);
  static const posHomeAccentOrange = Color(0xFFFF6A00);
  static const posHomeOrangeStart = Color(0xFFFFC400);
  static const posHomeOrangeEnd = Color(0xFFFF6A00);
  static const posHomeTealStart = Color(0xFF13DCC7);
  static const posHomeTealEnd = Color(0xFF009688);
  static const posHomeGreenStart = Color(0xFF9CEB22);
  static const posHomeGreenEnd = Color(0xFF22B814);
  static const posHomeBlueStart = Color(0xFF18B9FF);
  static const posHomeBlueEnd = Color(0xFF0878DF);
  static const posHomePurpleStart = Color(0xFFB759D0);
  static const posHomePurpleEnd = Color(0xFF6B1AA4);
  static const posHomeRedStart = Color(0xFFFF685C);
  static const posHomeRedEnd = Color(0xFFF51F2B);
  static const posHomeProfileBlueStart = Color(0xFF53B5FF);
  static const posHomeProfileBlueEnd = Color(0xFF0752C8);
  static const posNewSaleAccent = Color(0xFFFF2D1A);
  static const posNewSaleAccentEnd = Color(0xFFFF6A00);
  static const posNewSaleSearchText = Color(0xFF101828);
  static const posNewSaleSearchHint = Color(0xFF173A84);
  static const posNewSaleOnline = Color(0xFF00E522);
  static const posNewSaleOnlineBorder = Color(0xFF006B1B);
  static const posNewSaleHoldAction = Color(0xFFA600BE);
  static const posNewSaleClearAction = Color(0xFFFF3B30);
  static const posNewSaleDiscountAction = Color(0xFF008F8B);
  static const posNewSaleCustomAction = Color(0xFFFF8A00);
  static const posNewSaleCustomerAction = Color(0xFF2563EB);
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
      color: Color(0x0F0F172A),
      blurRadius: 24,
      offset: Offset(0, 10),
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
              fontWeight: FontWeight.w900,
              color: TenantAdminColors.bodyText,
            ) ??
        const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: TenantAdminColors.bodyText,
        );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: TenantAdminColors.bodyText,
        );
  }

  static TextStyle muted(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.mutedText,
            ) ??
        const TextStyle(color: TenantAdminColors.mutedText);
  }
}
