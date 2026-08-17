import 'package:flutter/material.dart';

import '../../../presentation/widgets/tenant_admin_widgets.dart';
import '../../domain/entities/tenant_user.dart';

class UserBasicInfoSection extends StatelessWidget {
  const UserBasicInfoSection({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.roles,
    required this.selectedRoleId,
    required this.onRoleChanged,
    required this.enabled,
    this.backendErrors = const {},
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final List<RoleOption> roles;
  final String? selectedRoleId;
  final ValueChanged<String?> onRoleChanged;
  final bool enabled;
  final Map<String, String> backendErrors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context,
            icon: Icons.badge_outlined, title: 'Basic Information'),
        const SizedBox(height: TenantAdminSpacing.lg),
        TenantAdminResponsiveFormGrid(
          children: [
            TextFormField(
              controller: fullNameController,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter full name',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                errorText: backendErrors['fullName'],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required.';
                }
                if (value.trim().length > 120) {
                  return 'Full name must be 120 characters or less.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: emailController,
              enabled: enabled,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                errorText: backendErrors['email'],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required.';
                }
                final valid =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
                if (!valid) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: phoneController,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter phone number',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                errorText: backendErrors['phone'],
              ),
              validator: (value) {
                if (value != null && value.trim().length > 20) {
                  return 'Phone number must be 20 characters or less.';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: selectedRoleId,
              decoration: InputDecoration(
                labelText: 'Role',
                hintText: 'Select role',
                prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                errorText: backendErrors['roleId'],
              ),
              items: [
                for (final role in roles)
                  DropdownMenuItem<String>(
                    value: role.id,
                    child: Text(role.name),
                  ),
              ],
              onChanged: enabled ? onRoleChanged : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Role is required.';
                }
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Icon(icon, size: 18, color: TenantAdminColors.primary),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
      ],
    );
  }
}
