import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.heroTitle = 'Powering every sale.',
    this.heroSubtitle = 'Every business. Every checkout.',
  });

  final String title;
  final String? subtitle;
  final String heroTitle;
  final String heroSubtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= TenantAdminBreakpoints.tablet;

    return Scaffold(
      backgroundColor: const Color(0xFF020B1F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020B1F),
              Color(0xFF061A3D),
              Color(0xFF020817),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            SafeArea(
              child: isWide
                  ? Row(
                      children: [
                        Flexible(
                          flex: 11,
                          child: _BrandPanel(
                            heroTitle: heroTitle,
                            heroSubtitle: heroSubtitle,
                          ),
                        ),
                        Flexible(
                          flex: 10,
                          child: _CardHost(
                            title: title,
                            subtitle: subtitle,
                            child: child,
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(TenantAdminSpacing.md),
                      child: Column(
                        children: [
                          const _MobileBrandHeader(),
                          const SizedBox(height: TenantAdminSpacing.xl),
                          _CardHost(
                            title: title,
                            subtitle: subtitle,
                            child: child,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHost extends StatelessWidget {
  const _CardHost({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: _cardOuterPadding(MediaQuery.sizeOf(context).width),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 410),
          child: Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < TenantAdminBreakpoints.mobile
                  ? TenantAdminSpacing.lg
                  : TenantAdminSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ) ??
                      const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: TenantAdminColors.mutedText),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

EdgeInsets _cardOuterPadding(double width) {
  if (width >= TenantAdminBreakpoints.tablet) {
    return const EdgeInsets.fromLTRB(12, 22, 72, 22);
  }

  if (width >= TenantAdminBreakpoints.mobile) {
    return const EdgeInsets.all(TenantAdminSpacing.xl);
  }

  return EdgeInsets.zero;
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.heroTitle,
    required this.heroSubtitle,
  });

  final String heroTitle;
  final String heroSubtitle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        width < 1100 ? 42 : 64,
        36,
        24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandLockup(),
          const Spacer(),
          Text(
            heroTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ) ??
                TextStyle(
                  color: Colors.white,
                  fontSize: width < 1100 ? 34 : 42,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            heroSubtitle,
            style: const TextStyle(
              color: Color(0xFF1D7CFF),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          const _FeaturePoint(
            icon: Icons.bolt,
            title: 'Fast & Reliable',
            subtitle: 'Built for busy sales operations',
          ),
          const _FeaturePoint(
            icon: Icons.lock,
            title: 'Secure by Design',
            subtitle: 'Enterprise-grade account protection',
          ),
          const _FeaturePoint(
            icon: Icons.insights,
            title: 'Real-time Insights',
            subtitle: 'Make smarter decisions, faster',
          ),
          const Spacer(),
          Text(
            '© 2026 OneVerz POS. All rights reserved.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: _BrandLockup(),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF075CFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF075CFF).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.point_of_sale, color: Colors.white),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OneVerz POS',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'UNIFIED COMMERCE',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1D7CFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF075CFF).withValues(alpha: 0.24),
            child: Icon(icon, color: const Color(0xFF2F86FF), size: 20),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthBackdropPainter());
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF042816).withValues(alpha: 0.78),
          const Color(0xFF061F12),
        ],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.58, size.width, size.height * 0.42));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.58, size.width, size.height * 0.42),
      fieldPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.58 + i * 0.035);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.height * 0.18),
        linePaint,
      );
    }

    _drawLight(canvas, size, Offset(size.width * 0.08, size.height * 0.56));
    _drawLight(canvas, size, Offset(size.width * 0.94, size.height * 0.45));
    _drawGlow(canvas, size, Offset(size.width * 0.2, size.height * 0.68), 0.28);
    _drawGlow(
        canvas, size, Offset(size.width * 0.88, size.height * 0.55), 0.22);

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.52),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawLight(Canvas canvas, Size size, Offset center) {
    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.58),
          const Color(0xFF1478FF).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.22));
    canvas.drawCircle(center, size.width * 0.22, beamPaint);

    final corePaint = Paint()..color = Colors.white.withValues(alpha: 0.82);
    canvas.drawCircle(center, 3.8, corePaint);
  }

  void _drawGlow(Canvas canvas, Size size, Offset center, double radiusFactor) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1478FF).withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * radiusFactor),
      );
    canvas.drawCircle(center, size.width * radiusFactor, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
