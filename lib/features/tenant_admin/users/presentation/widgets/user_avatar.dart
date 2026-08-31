import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 19,
    this.fallbackIcon,
  });

  final TenantUser user;
  final double radius;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _profileImageProvider(user.profileImageUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: TenantAdminColors.secondary,
      foregroundImage: imageProvider,
      onForegroundImageError: imageProvider == null ? null : (_, __) {},
      child: fallbackIcon == null
          ? Text(
              _initials(user.fullName),
              style: const TextStyle(
                color: TenantAdminColors.posHomeAccentOrange,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(fallbackIcon, color: TenantAdminColors.primary),
    );
  }

  static ImageProvider? _profileImageProvider(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    return NetworkImage(url);
  }
}

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
