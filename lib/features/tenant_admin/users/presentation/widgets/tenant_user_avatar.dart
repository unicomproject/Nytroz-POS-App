import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class TenantUserAvatar extends ConsumerWidget {
  const TenantUserAvatar({
    super.key,
    required this.fullName,
    this.imageUrl,
    this.radius = 24,
  });

  final String fullName;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawImageUrl = imageUrl?.trim();
    final resolvedImageUrl = rawImageUrl == null || rawImageUrl.isEmpty
        ? null
        : MediaUrlResolver.resolve(
              rawImageUrl,
              apiBaseUrl: ref.watch(appDioProvider).options.baseUrl,
            ) ??
            rawImageUrl;
    final diameter = radius * 2;

    return Semantics(
      image: true,
      label: 'Profile image for $fullName',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.45),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: resolvedImageUrl == null
              ? _fallback()
              : Image.network(
                  resolvedImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) =>
                      loadingProgress == null ? child : _fallback(),
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Image.asset(
      'assets/images/user-avatar-placeholder.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: TenantAdminColors.secondary,
        child: Center(
          child: Text(
            _initials(fullName),
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
