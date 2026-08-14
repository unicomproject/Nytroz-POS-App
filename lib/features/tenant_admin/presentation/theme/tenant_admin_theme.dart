import 'package:flutter/material.dart';

class TenantAdminColors {
  const TenantAdminColors._();

  static const navy = Color(0xFF071A33);
  static const navySoft = Color(0xFF0E2748);
  static const startSaleHero = Color(0xFF001C38);
  static const background = Color(0xFF030303);
  static const subtleBackground = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE5EAF4);
  static const mutedText = Color(0xFF64748B);
  static const bodyText = Color(0xFF081B3A);
  static const primary = Color(0xFFFF6A00);
  static const primaryHover = Color(0xFFE85F00);
  static const secondary = Color(0xFFFFF3EA);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
  static const pending = Color(0xFFF59E0B);
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
  static const posOnboardingAccent = Color(0xFFFF5A1F);
  static const posOnboardingHeading = Color(0xFF17191F);
  static const posOnboardingFieldText = Color(0xFF30343B);
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
  static const xlg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
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
  static const smallTablet = 700.0;
  static const tablet = 900.0;
  static const tabletLandscape = 1024.0;
  static const desktop = 1280.0;
  static const largeDesktop = 1440.0;

  static bool isDesktop(double width) => width >= desktop;

  static bool isLargeDesktop(double width) => width >= largeDesktop;

  static bool isTablet(double width) => width >= tablet && width < desktop;

  static bool isTabletLandscape(double width) =>
      width >= tabletLandscape && width < desktop;

  static bool isSmallTablet(double width) =>
      width >= smallTablet && width < tablet;

  static bool isMobile(double width) => width < smallTablet;
}

class TenantAdminInsets {
  const TenantAdminInsets._();

  static EdgeInsets pageForWidth(double width) {
    if (width < TenantAdminBreakpoints.mobile) {
      return const EdgeInsets.all(TenantAdminSpacing.lg);
    }

    if (width < TenantAdminBreakpoints.tablet) {
      return const EdgeInsets.all(TenantAdminSpacing.lg);
    }

    if (width < TenantAdminBreakpoints.desktop) {
      return const EdgeInsets.all(TenantAdminSpacing.xlg);
    }

    return const EdgeInsets.fromLTRB(
      TenantAdminSpacing.xl,
      TenantAdminSpacing.xl,
      TenantAdminSpacing.xl,
      TenantAdminSpacing.xlg,
    );
  }
}

class TenantAdminFooterNav {
  const TenantAdminFooterNav._();

  /// Height of the fixed bottom footer navigation shown on all Tenant Admin
  /// routes (matches [PosCashierBottomNavigation]'s height).
  static const height = 48.0;

  /// Extra bottom inset to reserve for scrollable content so the fixed
  /// footer never overlaps the last visible row.
  static const contentInset = EdgeInsets.only(bottom: height);
}

class TenantAdminAppHeaderTokens {
  const TenantAdminAppHeaderTokens._();

  /// Height of the shared black Tenant Admin application header.
  static const height = 44.0;
}

class TenantAdminSidebarTokens {
  const TenantAdminSidebarTokens._();

  static const width = 248.0;
  static const compactWidth = 78.0;
  static const tabletWidth = 220.0;
  static const childIndent = 28.0;
  static const compactChildIndent = 18.0;

  static const background = TenantAdminColors.posHomeDarkBackground;
  static const border = Colors.transparent;
  static const foreground = TenantAdminColors.surface;
  static const mutedForeground = TenantAdminColors.mutedText;
  static const icon = Color(0xFF94A3B8);
  static const activeBackground = TenantAdminColors.posHomeOrangeEnd;
  static const activeForeground = TenantAdminColors.surface;
  static const disabledForeground = Color(0xFFB6C0D1);
}

class TenantAdminContentTokens {
  const TenantAdminContentTokens._();

  static const sidePanelWidth = 420.0;
  static const formFieldHeight = 48.0;
  static const buttonHeight = 44.0;
  static const tabletButtonHeight = 48.0;
  static const tableHeaderHeight = 48.0;
  static const contentGap = TenantAdminSpacing.lg;
  static const defaultListPageSize = 5;
  static const desktopMasterRatio = 0.65;
  static const detailPanelRatio = 0.35;
  static const minUsablePanelWidth = 320.0;
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
