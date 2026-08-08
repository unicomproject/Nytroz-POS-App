import 'package:flutter/material.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class OutletLocationGuidancePanel extends StatelessWidget {
  const OutletLocationGuidancePanel({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(TenantAdminSpacing.lg), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: TenantAdminColors.border), borderRadius: BorderRadius.circular(TenantAdminRadius.md)), child: const Column(children: [
    _Guidance(Icons.location_on_outlined, 'Accurate address matters', 'A complete address helps with reporting, deliveries, and accurate business insights.'), Divider(),
    _Guidance(Icons.people_outline, 'Keep contact details up to date', 'We’ll use these details for communication and operational updates.'), Divider(),
    _Guidance(Icons.image_outlined, 'Image helps you identify outlets', 'Use a clear image of the outlet front or logo to quickly recognise it in the system.'), Divider(),
    _Guidance(Icons.public_outlined, 'Location impacts operations', 'The country and region you select may affect taxes, compliance and available features.'),
  ]));
}
class _Guidance extends StatelessWidget { const _Guidance(this.icon, this.title, this.body); final IconData icon; final String title; final String body; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(backgroundColor: TenantAdminColors.posHomeOrangeEnd.withValues(alpha: .1), child: Icon(icon, color: TenantAdminColors.posHomeOrangeEnd)), const SizedBox(width: TenantAdminSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText)), const SizedBox(height: 4), Text(body, style: TenantAdminTextStyles.muted(context))]))])); }
