import 'dart:io';

void main() {
  final file = File(
      r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();

  const startText = 'class _OutletReviewStep extends StatelessWidget {';
  const endText = 'class _OutletWizardActions extends StatelessWidget {';

  final startIndex = content.indexOf(startText);
  final endIndex = content.indexOf(endText);

  if (startIndex == -1 || endIndex == -1) {
    // ignore: avoid_print
    print('Indices not found!');
    return;
  }

  final newContent = content.replaceRange(
      startIndex, endIndex, '''class _OutletReviewStep extends ConsumerWidget {
  const _OutletReviewStep({
    required this.form,
    required this.onEdit,
  });

  final OutletFormData form;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(outletImageUploadControllerProvider);
    
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 1250;
      
      final leftContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Outlet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: TenantAdminColors.bodyText)),
          const SizedBox(height: 4),
          Text('Review your information before creating the outlet.', style: TenantAdminTextStyles.muted(context)),
          const SizedBox(height: TenantAdminSpacing.xl),
          LayoutBuilder(builder: (context, gridConstraints) {
            final isGridWide = gridConstraints.maxWidth >= 700;
            return Wrap(
              spacing: TenantAdminSpacing.lg,
              runSpacing: TenantAdminSpacing.lg,
              children: [
                SizedBox(
                  width: isGridWide ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2 : gridConstraints.maxWidth,
                  child: _buildDetailsCard(),
                ),
                SizedBox(
                  width: isGridWide ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2 : gridConstraints.maxWidth,
                  child: _buildLocationContactCard(),
                ),
                SizedBox(
                  width: isGridWide ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2 : gridConstraints.maxWidth,
                  child: _buildBusinessHoursCard(),
                ),
                SizedBox(
                  width: isGridWide ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2 : gridConstraints.maxWidth,
                  child: _buildImagePreviewCard(imageState),
                ),
              ],
            );
          }),
        ],
      );
      
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: leftContent),
            const SizedBox(width: TenantAdminSpacing.xl),
            const Expanded(flex: 3, child: _ReviewInfoPanel()),
          ],
        );
      }
      
      return Column(
        children: [
          leftContent,
          const SizedBox(height: TenantAdminSpacing.xl),
          const _ReviewInfoPanel(),
        ],
      );
    });
  }
  
  Widget _buildCard({required String title, required int step, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                InkWell(
                  onTap: () => onEdit(step),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: TenantAdminColors.posHomeOrangeEnd),
                      SizedBox(width: 4),
                      Text('Edit step', style: TextStyle(color: TenantAdminColors.posHomeOrangeEnd, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    Widget _row(String label, String value, {bool isBadge = false, bool badgeSuccess = true}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: TenantAdminColors.mutedText))),
            Expanded(
              child: isBadge
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: badgeSuccess ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeSuccess ? Colors.green : Colors.grey[700])),
                      ),
                    )
                  : Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    return _buildCard(
      title: 'Outlet Details',
      step: 0,
      child: Column(
        children: [
          _row('Outlet Name', form.outletName.isNotEmpty ? form.outletName : '-'),
          _row('Outlet Code', 'Generated by backend'),
          _row('Outlet Type', _displayOutletType(form.outletType)),
          _row('Status', _displayStatus(form.status), isBadge: true, badgeSuccess: form.status == 'ACTIVE'),
          _row('Outlet Manager', form.contactName ?? '-'),
          _row('Outlet Email', form.emailAddress.isNotEmpty ? form.emailAddress : '-'),
          _row('Outlet Phone', form.mainPhoneNumber.isNotEmpty ? form.mainPhoneNumber : '-'),
          _row('Timezone', form.timezone.isNotEmpty ? form.timezone : '-'),
          _row('Main / Central Outlet', 'No', isBadge: true, badgeSuccess: false),
          _row('Default for New Tills', form.isDefaultOutlet ? 'Yes' : 'No', isBadge: true, badgeSuccess: form.isDefaultOutlet),
        ],
      ),
    );
  }

  Widget _buildLocationContactCard() {
    final address = [
      if (form.addressLine1.isNotEmpty) form.addressLine1,
      if (form.addressLine2 != null && form.addressLine2!.isNotEmpty) form.addressLine2,
      [if (form.city.isNotEmpty) form.city, if (form.state != null && form.state!.isNotEmpty) form.state, if (form.postalCode.isNotEmpty) form.postalCode].where((e) => e != null && e.isNotEmpty).join(', '),
      if (form.country.isNotEmpty) form.country,
    ];

    return _buildCard(
      title: 'Location & Contact',
      step: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Address', style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText)),
          const SizedBox(height: 4),
          Text(address.isEmpty ? '-' : address.join('\\n'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          const Text('Contact Person', style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText)),
          const SizedBox(height: 4),
          Text(form.contactName?.isNotEmpty == true ? form.contactName! : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          const Text('Phone Number', style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText)),
          const SizedBox(height: 4),
          Text(form.contactPhone?.isNotEmpty == true ? form.contactPhone! : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          const Text('Email Address', style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText)),
          const SizedBox(height: 4),
          Text(form.contactEmail?.isNotEmpty == true ? form.contactEmail! : '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursCard() {
    Widget _hourRow(OutletOpeningHour hour) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(hour.day, style: const TextStyle(fontSize: 13, color: TenantAdminColors.mutedText))),
            Expanded(
              child: Text(
                hour.closed ? 'Closed' : '\${hour.openTime} - \${hour.closeTime}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: hour.closed ? Colors.red : TenantAdminColors.bodyText),
              ),
            ),
          ],
        ),
      );
    }
    
    final col1 = form.openingHours.take(4).toList();
    final col2 = form.openingHours.skip(4).toList();

    return _buildCard(
      title: 'Business Hours',
      step: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Regular Hours (Timezone: \${form.timezone})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: col1.map(_hourRow).toList())),
              Expanded(child: Column(children: col2.map(_hourRow).toList())),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Special Days / Holiday Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 140, child: Text('Christmas Day (Dec 25)', style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText))),
                const Expanded(child: Text('09:00 AM - 06:00 PM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 140, child: Text("New Year's Day (Jan 01)", style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText))),
                const Expanded(child: Text('10:00 AM - 08:00 PM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard(OutletImageUploadState imageState) {
    final hasImage = imageState.previewBytes != null || imageState.remoteImageUrl != null;
    
    return _buildCard(
      title: 'Outlet Image Preview',
      step: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: hasImage
                  ? (imageState.previewBytes != null
                      ? Image.memory(imageState.previewBytes!, fit: BoxFit.cover)
                      : Image.network(imageState.remoteImageUrl!, fit: BoxFit.cover))
                  : Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(Icons.storefront_outlined, size: 48, color: TenantAdminColors.mutedText),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text('This image will represent your outlet across the system.', style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReviewInfoPanel extends StatelessWidget {
  const _ReviewInfoPanel();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: const Column(
        children: [
          _PanelItem(Icons.storefront_outlined, 'Outlet will be created', 'The outlet will be created with the information shown on this review page once you confirm.'),
          Divider(height: 1, color: TenantAdminColors.border),
          _PanelItem(Icons.point_of_sale_outlined, 'Till assignment', 'New tills will be assigned to this outlet by default.'),
          Divider(height: 1, color: TenantAdminColors.border),
          _PanelItem(Icons.bar_chart_outlined, 'Sales & reporting', 'This outlet will be included in sales, stock, and performance reports immediately.'),
          Divider(height: 1, color: TenantAdminColors.border),
          _PanelItem(Icons.group_outlined, 'Access & permissions', 'Access is managed through user roles and outlet assignments.'),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  const _PanelItem(this.icon, this.title, this.desc);
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF0E6),
            radius: 20,
            child: Icon(icon, color: TenantAdminColors.posHomeOrangeEnd, size: 20),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: TenantAdminColors.mutedText, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

''');
  file.writeAsStringSync(newContent);
  // ignore: avoid_print
  print('Successfully updated _OutletReviewStep');
}
