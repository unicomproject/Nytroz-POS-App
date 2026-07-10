import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../shared/pos_session/pos_session_context.dart';
import '../../../../shared/pos_session/pos_session_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/till_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../widgets/open_till_form.dart';

const double _openTillCompactBreakpoint = 760;
const double _openTillSidebarWidth = 280;

class TillOpenScreen extends ConsumerStatefulWidget {
  const TillOpenScreen({super.key});

  @override
  ConsumerState<TillOpenScreen> createState() => _TillOpenScreenState();
}

class _TillOpenScreenState extends ConsumerState<TillOpenScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _openingFloatController;
  late final TextEditingController _openingNoteController;
  bool _initializedOpeningFloat = false;

  @override
  void initState() {
    super.initState();
    _openingFloatController = TextEditingController();
    _openingNoteController = TextEditingController();
  }

  @override
  void dispose() {
    _openingFloatController.dispose();
    _openingNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceActivationProvider);
    final tillState = ref.watch(tillProvider);
    final sessionContext = ref.watch(posSessionContextProvider);
    final authSession = ref.watch(authSessionProvider);
    final device = deviceState.deviceContext;

    if (device != null && !_initializedOpeningFloat) {
      _initializedOpeningFloat = true;
      final defaultFloat = device.defaultOpeningFloatAmount;
      _openingFloatController.text = defaultFloat.toStringAsFixed(2);
    }

    if (device == null || !device.isTrusted) {
      return Scaffold(
        backgroundColor: TenantAdminColors.background,
        body: Center(
          child: _BlockedPanel(
            title: 'Device activation required',
            message:
                'This POS device must be trusted before a till can be opened.',
            actionLabel: 'Activate device',
            onPressed: () => context.go('/pos/device-activation'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TenantAdminColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _openTillCompactBreakpoint;

          if (isCompact) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PosSetupSidebar(
                    contextData: sessionContext,
                    stretchVertically: false,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  OpenTillForm(
                    formKey: _formKey,
                    openingFloatController: _openingFloatController,
                    openingNoteController: _openingNoteController,
                    errorMessage: tillState.errorMessage,
                    isSubmitting: tillState.isSubmitting,
                    outletName: sessionContext.outletName,
                    tillName: device.tillName,
                    deviceName: sessionContext.deviceCode,
                    currencyCode: device.currencyCode,
                    openingBy: authSession?.userDisplayName ?? '',
                    onBack: () => context.go('/pos/device-activation'),
                    onSubmit: _submitOpenTill,
                  ),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _openTillSidebarWidth,
                child: PosSetupSidebar(
                  contextData: sessionContext,
                  stretchVertically: true,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: TenantAdminColors.background,
                  child: SingleChildScrollView(
                    padding: TenantAdminInsets.pageForWidth(
                      constraints.maxWidth - _openTillSidebarWidth,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: OpenTillForm(
                          formKey: _formKey,
                          openingFloatController: _openingFloatController,
                          openingNoteController: _openingNoteController,
                          errorMessage: tillState.errorMessage,
                          isSubmitting: tillState.isSubmitting,
                          outletName: sessionContext.outletName,
                          tillName: device.tillName,
                          deviceName: sessionContext.deviceCode,
                          currencyCode: device.currencyCode,
                          openingBy: authSession?.userDisplayName ?? '',
                          embedded: true,
                          onBack: () => context.go('/pos/device-activation'),
                          onSubmit: _submitOpenTill,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOpenTill() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {});
      return;
    }

    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device == null) {
      context.go('/pos/device-activation');
      return;
    }

    final opened = await ref.read(tillProvider.notifier).openTill(
          deviceContext: device,
          openingFloat: double.parse(_openingFloatController.text),
          openingNote: _openingNoteController.text,
        );

    if (opened && mounted) {
      await ref
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
      if (!mounted) {
        return;
      }
      final route = ref.read(postLoginRouteProvider);
      context.go(route.path);
    }
  }
}

class PosSetupSidebar extends StatelessWidget {
  const PosSetupSidebar({
    super.key,
    required this.contextData,
    this.stretchVertically = true,
  });

  final PosSessionContext contextData;
  final bool stretchVertically;

  @override
  Widget build(BuildContext context) {
    final sidebarContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF075DFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextData.brandName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      contextData.brandSubtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC4CEE3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SidebarInfoCard(
            icon: Icons.storefront_outlined,
            title: contextData.outletName,
            subtitle: contextData.outletLocation,
          ),
          const SizedBox(height: 8),
          _SidebarInfoCard(
            icon: Icons.point_of_sale_outlined,
            title: contextData.tillName,
            subtitle: contextData.tillStatus,
            subtitleColor: const Color(0xFF28D17C),
          ),
          const SizedBox(height: 10),
          _UserCard(
            name: contextData.userName,
            role: contextData.userRole,
          ),
          const SizedBox(height: 18),
          const _SetupStep(
            number: '1',
            title: 'Outlet Fetch',
            subtitle: 'Completed',
            isActive: false,
          ),
          const _SetupStep(
            number: '2',
            title: 'Till Fetch',
            subtitle: 'Completed',
            isActive: false,
          ),
          const _SetupStep(
            number: '3',
            title: 'Open Till',
            subtitle: 'Step 3 of 3',
            isActive: true,
          ),
          if (stretchVertically) const Spacer(),
          if (!stretchVertically) const SizedBox(height: 18),
          _SystemStatusCard(
            status: contextData.systemStatus,
            lastSync: contextData.lastSyncLabel,
          ),
        ],
      );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071D40), Color(0xFF031126)],
        ),
      ),
      child: stretchVertically
          ? SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: sidebarContent,
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: sidebarContent,
            ),
    );
  }
}

class _SidebarInfoCard extends StatelessWidget {
  const _SidebarInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor = const Color(0xFFE3E9F8),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .04)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.role,
  });

  final String name;
  final String role;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      final end = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, end).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF075DFF),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFFC4CEE3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70, size: 16),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isActive,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF075DFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : const Color(0xFF22C55E),
                width: 2,
              ),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? const Color(0xFF075DFF) : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF35D884),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard({
    required this.status,
    required this.lastSync,
  });

  final String status;
  final String lastSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF35D884), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastSync,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC4CEE3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedPanel extends StatelessWidget {
  const _BlockedPanel({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10233F),
                      ),
                ),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onPressed,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
