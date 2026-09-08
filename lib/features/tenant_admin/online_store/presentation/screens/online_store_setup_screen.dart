// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/online_store.dart';
import '../providers/online_store_providers.dart';

const _onlineStoreOrange = TenantAdminColors.primary;
const _onlineStoreText = TenantAdminColors.bodyText;
const _onlineStoreMuted = TenantAdminColors.mutedText;
const _onlineStoreBorder = TenantAdminColors.border;

class OnlineStoreSetupScreen extends ConsumerWidget {
  const OnlineStoreSetupScreen({
    super.key,
    required this.stepNumber,
  });

  final int stepNumber;

  static const steps = <_OnlineStoreStepConfig>[
    _OnlineStoreStepConfig(
      number: 1,
      label: 'Overview',
      title: 'Online Store Overview',
      subtitle:
          'Monitor your online store setup and take the next steps to go live.',
      route: '/tenant-admin/online-store',
    ),
    _OnlineStoreStepConfig(
      number: 2,
      label: 'Activation',
      title: 'Online Store Activation',
      subtitle:
          'Enable your online channel for setup and confirm the Release 1 configuration.',
      route: '/tenant-admin/online-store/activation',
    ),
    _OnlineStoreStepConfig(
      number: 3,
      label: 'Identity',
      title: 'Store Identity',
      subtitle:
          'Define the information customers will see on your online store.',
      route: '/tenant-admin/online-store/identity',
    ),
    _OnlineStoreStepConfig(
      number: 4,
      label: 'Domain',
      title: 'Storefront URL & Domain',
      subtitle:
          'Set your store URL, connect a custom domain, and track verification & SSL status.',
      route: '/tenant-admin/online-store/domain',
    ),
    _OnlineStoreStepConfig(
      number: 5,
      label: 'Branding',
      title: 'Branding & Banners',
      subtitle: 'Customize how your online store looks and feels to customers.',
      route: '/tenant-admin/online-store/branding',
    ),
    _OnlineStoreStepConfig(
      number: 6,
      label: 'Support',
      title: 'Contact & Support',
      subtitle:
          'Configure how customers can contact your store and get support.',
      route: '/tenant-admin/online-store/support',
    ),
    _OnlineStoreStepConfig(
      number: 7,
      label: 'Click & Collect',
      title: 'Configure Click & Collect',
      subtitle: 'Configure collection outlets and pickup rules.',
      route: '/tenant-admin/online-store/click-collect',
    ),
    _OnlineStoreStepConfig(
      number: 8,
      label: 'Products & Policies',
      title: 'Products & Policies',
      subtitle: 'Manage online product visibility and customer policies.',
      route: '/tenant-admin/online-store/products-policies',
    ),
    _OnlineStoreStepConfig(
      number: 9,
      label: 'Review & Publish',
      title: 'Review & Publish',
      subtitle: 'Review all settings before publishing your online store.',
      route: '/tenant-admin/online-store/review',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStep = steps.firstWhere(
      (step) => step.number == stepNumber,
      orElse: () => steps.first,
    );
    final overviewState = ref.watch(onlineStoreOverviewProvider);
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return accessState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _OnlineStoreErrorCard(
        message: 'Unable to load Tenant Admin access.',
        onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
      ),
      data: (access) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow =
                constraints.maxWidth < TenantAdminBreakpoints.tabletLandscape;

            return _OnlineStoreJourneyScaffold(
              activeStep: activeStep,
              overview: overviewState.asData?.value,
              access: access,
              isNarrow: isNarrow,
              child: _OnlineStoreStepBody(
                key: ValueKey('online-store-step-${activeStep.number}'),
                stepNumber: activeStep.number,
                access: access,
              ),
            );
          },
        );
      },
    );
  }
}

class _OnlineStoreJourneyScaffold extends StatelessWidget {
  const _OnlineStoreJourneyScaffold({
    required this.activeStep,
    required this.overview,
    required this.access,
    required this.isNarrow,
    required this.child,
  });

  final _OnlineStoreStepConfig activeStep;
  final OnlineStoreOverview? overview;
  final TenantAdminAccessChecker access;
  final bool isNarrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TenantAdminColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
            boxShadow: TenantAdminShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomActions = _OnlineStoreBottomActions(
                  activeStep: activeStep,
                  overview: overview,
                  access: access,
                );

                final scrollView = Scrollbar(
                  child: SingleChildScrollView(
                    key: const ValueKey('online-store-content-scroll'),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isNarrow
                                ? TenantAdminSpacing.lg
                                : TenantAdminSpacing.xxl,
                            isNarrow
                                ? TenantAdminSpacing.lg
                                : TenantAdminSpacing.xl,
                            isNarrow
                                ? TenantAdminSpacing.lg
                                : TenantAdminSpacing.xxl,
                            TenantAdminSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OnlineStoreHeader(
                                activeStep: activeStep,
                                overview: overview,
                              ),
                              SizedBox(
                                height: TenantAdminSpacing.xl,
                              ),
                              child,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                return Column(
                  children: [
                    Expanded(child: scrollView),
                    bottomActions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineStoreStepConfig {
  const _OnlineStoreStepConfig({
    required this.number,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final int number;
  final String label;
  final String title;
  final String subtitle;
  final String route;
}

class _OnlineStoreHeader extends StatelessWidget {
  const _OnlineStoreHeader({
    required this.activeStep,
    required this.overview,
  });

  final _OnlineStoreStepConfig activeStep;
  final OnlineStoreOverview? overview;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeStep.title.toUpperCase(),
          style: TenantAdminTextStyles.pageTitle(
            context,
            isDesktop: !isNarrow,
          ).copyWith(fontWeight: FontWeight.w900, letterSpacing: .2),
        ),
        const SizedBox(height: 6),
        Text(
          activeStep.subtitle,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            height: 1.35,
          ),
        ),
      ],
    );
    final progress = activeStep.number == 1
        ? _OnlineStoreOverviewProgress(overview: overview)
        : _OnlineStoreProgressHeader(activeStep: activeStep);

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: TenantAdminSpacing.lg),
          progress,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: TenantAdminSpacing.xl),
        SizedBox(width: 430, child: progress),
      ],
    );
  }
}

class _OnlineStoreOverviewProgress extends StatelessWidget {
  const _OnlineStoreOverviewProgress({required this.overview});

  final OnlineStoreOverview? overview;

  @override
  Widget build(BuildContext context) {
    final percentage = (overview?.setupProgressPercent ?? 0).clamp(0, 100);
    final status = percentage >= 100 ? 'Ready' : 'In Progress';

    return Semantics(
      key: const ValueKey('online-store-progress'),
      label: 'Online store setup progress $percentage percent, $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: _onlineStoreBorder),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Setup Progress',
                  style: TextStyle(
                    color: _onlineStoreText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  color: _onlineStoreOrange,
                  backgroundColor: const Color(0xFFE8EAED),
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: _onlineStoreOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineStoreProgressHeader extends StatelessWidget {
  const _OnlineStoreProgressHeader({required this.activeStep});

  final _OnlineStoreStepConfig activeStep;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('online-store-progress'),
      label: 'Step ${activeStep.number} of 9, ${activeStep.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: _onlineStoreBorder),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          children: [
            Text(
              '${activeStep.number}/9',
              style: const TextStyle(
                color: _onlineStoreText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: Row(
                children: List.generate(9, (index) {
                  final completed = index < activeStep.number;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 5,
                      margin: EdgeInsets.only(right: index == 8 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: completed
                            ? _onlineStoreOrange
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Text(
              'STEP ${activeStep.number} OF 9',
              style: const TextStyle(
                color: _onlineStoreText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineStoreStepper extends StatelessWidget {
  const _OnlineStoreStepper({
    required this.currentStep,
    required this.overview,
  });

  final _OnlineStoreStepConfig currentStep;
  final OnlineStoreOverview? overview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Online store setup progress stepper',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 980;
          return Wrap(
            spacing: isCompact ? 14 : 0,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: OnlineStoreSetupScreen.steps.map((step) {
              return _OnlineStoreStepNode(
                step: step,
                currentStepNumber: currentStep.number,
                backendStep: _backendStep(step.number),
                compact: isCompact,
              );
            }).toList(growable: false),
          );
        },
      ),
    );
  }

  OnlineStoreStep? _backendStep(int number) {
    final allSteps = overview?.steps ?? const <OnlineStoreStep>[];
    for (final item in allSteps) {
      if (item.stepNumber == number) {
        return item;
      }
    }
    return null;
  }
}

class _OnlineStoreStepNode extends StatelessWidget {
  const _OnlineStoreStepNode({
    required this.step,
    required this.currentStepNumber,
    required this.backendStep,
    required this.compact,
  });

  final _OnlineStoreStepConfig step;
  final int currentStepNumber;
  final OnlineStoreStep? backendStep;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isCurrent = step.number == currentStepNumber;
    final isComplete = _isStepComplete(backendStep);
    final isBlocked = _isStepBlocked(backendStep);
    final circleColor = isCurrent
        ? _onlineStoreOrange
        : isComplete
            ? TenantAdminColors.success
            : TenantAdminColors.surface;
    final borderColor = isCurrent || isComplete
        ? circleColor
        : isBlocked
            ? TenantAdminColors.warning
            : const Color(0xFFCBD5E1);
    final labelColor = isCurrent
        ? _onlineStoreOrange
        : isBlocked
            ? TenantAdminColors.warning
            : _onlineStoreText;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go(step.route),
      child: Semantics(
        button: true,
        label:
            'Step ${step.number}, ${step.label}, ${isCurrent ? 'current' : isComplete ? 'complete' : isBlocked ? 'blocked' : 'incomplete'}',
        child: SizedBox(
          width: compact ? 120 : 132,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: _onlineStoreOrange.withValues(alpha: .18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: isComplete && !isCurrent
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '${step.number}',
                        style: TextStyle(
                          color: isCurrent || isComplete
                              ? Colors.white
                              : _onlineStoreText,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                step.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineStoreStepBody extends ConsumerWidget {
  const _OnlineStoreStepBody({
    super.key,
    required this.stepNumber,
    required this.access,
  });

  final int stepNumber;
  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (stepNumber) {
      case 1:
        return _OnlineStoreOverviewStep(access: access);
      case 2:
        return _OnlineStoreActivationStep(access: access);
      case 3:
        return _OnlineStoreIdentityStep(access: access);
      case 4:
        return _OnlineStoreDomainStep(access: access);
      case 5:
        return _OnlineStoreBrandingStep(access: access);
      case 6:
        return _OnlineStoreSupportStep(access: access);
      case 7:
        return _OnlineStoreClickCollectStep(access: access);
      case 8:
        return _OnlineStoreProductsPoliciesStep(access: access);
      case 9:
        return _OnlineStoreReviewStep(access: access);
      default:
        return const _OnlineStoreEmptyState(
          title: 'Unknown setup step',
          message: 'This route does not map to a supported Online Store step.',
        );
    }
  }
}

class _OnlineStoreOverviewStep extends ConsumerWidget {
  const _OnlineStoreOverviewStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(onlineStoreOverviewProvider);
    return _AsyncSection<OnlineStoreOverview>(
      state: overviewState,
      onRetry: () => ref.invalidate(onlineStoreOverviewProvider),
      builder: (overview) {
        final steps =
            overview.steps.isEmpty ? overview.readiness.steps : overview.steps;
        return _OnlineStoreOverviewContent(
          overview: overview,
          steps: steps,
        );
      },
    );
  }
}

class _OnlineStoreOverviewContent extends StatelessWidget {
  const _OnlineStoreOverviewContent({
    required this.overview,
    required this.steps,
  });

  final OnlineStoreOverview overview;
  final List<OnlineStoreStep> steps;

  @override
  Widget build(BuildContext context) {
    final incompleteSteps = _prioritizedOverviewSteps(steps);

    return _ResponsiveTwoColumn(
      leftFlex: 3,
      rightFlex: 2,
      left: Column(
        children: [
          _OverviewReadinessCard(overview: overview),
          const SizedBox(height: TenantAdminSpacing.lg),
          _OverviewInsightsCard(steps: steps),
        ],
      ),
      right: Column(
        children: [
          _OverviewHeroCard(canPublish: overview.readiness.canPublish),
          const SizedBox(height: TenantAdminSpacing.lg),
          _OverviewNextStepsCard(steps: incompleteSteps),
        ],
      ),
    );
  }
}

class _OverviewReadinessCard extends StatelessWidget {
  const _OverviewReadinessCard({required this.overview});

  final OnlineStoreOverview overview;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 820;
    final domainReady = overview.domain.configured &&
        _isOnlineStoreReadyStatus(overview.domain.dnsStatus) &&
        _isOnlineStoreReadyStatus(overview.domain.sslStatus);
    final brandingReady = _isOnlineStoreReadyStatus(overview.branding.status);
    final supportReady =
        _isOnlineStoreReadyStatus(overview.contactSupport.status);
    final clickCollectReady =
        _isOnlineStoreReadyStatus(overview.clickCollect.status);
    final policiesReady = _isOnlineStoreReadyStatus(overview.policies.status);
    final notificationsReady =
        _isOnlineStoreReadyStatus(overview.notificationsStatus);
    final visibleProducts = overview.catalog.onlineVisibleProducts;
    final groups = <_OverviewReadinessGroup>[
      _OverviewReadinessGroup(
        label: 'STORE',
        items: [
          _OverviewReadinessItem(
            icon: Icons.language,
            label: 'Store URL',
            value: _display(overview.hostedUrl),
            color: overview.hostedUrl == null
                ? _onlineStoreMuted
                : TenantAdminColors.info,
            showExternal: overview.hostedUrl != null,
          ),
          _OverviewReadinessItem(
            icon: Icons.public_outlined,
            label: 'Custom Domain',
            value: overview.domain.domain ?? 'Requires setup',
            color: domainReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: domainReady,
            warning: !domainReady,
          ),
        ],
      ),
      _OverviewReadinessGroup(
        label: 'COMMERCE',
        items: [
          _OverviewReadinessItem(
            icon: Icons.palette_outlined,
            label: 'Branding',
            value: brandingReady ? 'Complete' : 'In progress',
            color: brandingReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: brandingReady,
            warning: !brandingReady,
          ),
          _OverviewReadinessItem(
            icon: Icons.support_agent_outlined,
            label: 'Contact & Support',
            value: supportReady ? 'Complete' : 'In progress',
            color: supportReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: supportReady,
            warning: !supportReady,
          ),
          _OverviewReadinessItem(
            icon: Icons.inventory_2_outlined,
            label: 'Product Catalogue',
            value: visibleProducts > 0
                ? '$visibleProducts online products'
                : 'In progress',
            color: visibleProducts > 0
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: visibleProducts > 0,
            warning: visibleProducts == 0,
          ),
          _OverviewReadinessItem(
            icon: Icons.person_outline,
            label: 'Customer Account',
            value: _onlineStoreContractLabel(overview.customerAccountMode),
          ),
          _OverviewReadinessItem(
            icon: Icons.location_on_outlined,
            label: 'Click & Collect',
            value: clickCollectReady
                ? '${overview.clickCollect.eligibleOutletCount} outlets enabled'
                : 'Requires configuration',
            color: clickCollectReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: clickCollectReady,
            warning: !clickCollectReady,
          ),
        ],
      ),
      _OverviewReadinessGroup(
        label: 'FULFILMENT',
        items: [
          _OverviewReadinessItem(
            icon: Icons.policy_outlined,
            label: 'Policies',
            value:
                '${overview.policies.publishedRequiredCount} of ${overview.policies.requiredCount} complete',
            color: policiesReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: policiesReady,
            warning: !policiesReady,
          ),
        ],
      ),
      _OverviewReadinessGroup(
        label: 'LAUNCH',
        items: [
          _OverviewReadinessItem(
            icon: Icons.mark_email_read_outlined,
            label: 'Email Verification',
            value:
                overview.emailVerificationRequired ? 'Enabled' : 'Not required',
            color: TenantAdminColors.success,
            positive: true,
          ),
          _OverviewReadinessItem(
            icon: Icons.payment_outlined,
            label: 'Payment Method',
            value: _onlineStoreContractLabel(overview.paymentMode),
          ),
          _OverviewReadinessItem(
            icon: Icons.notifications_none_outlined,
            label: 'Notifications',
            value: notificationsReady ? 'Ready' : 'Pending',
            color: notificationsReady
                ? TenantAdminColors.success
                : TenantAdminColors.warning,
            positive: notificationsReady,
            warning: !notificationsReady,
          ),
        ],
      ),
    ];

    return _OnlineStoreCard(
      title: 'Setup Readiness',
      padding: EdgeInsets.all(dense ? 14 : 20),
      headerSpacing: dense ? 8 : 14,
      child: Column(
        children: groups
            .map(
              (group) => _OverviewReadinessGroupView(
                group: group,
                dense: dense,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OverviewReadinessGroup {
  const _OverviewReadinessGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<_OverviewReadinessItem> items;
}

class _OverviewReadinessItem {
  const _OverviewReadinessItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.positive = false,
    this.warning = false,
    this.showExternal = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool positive;
  final bool warning;
  final bool showExternal;
}

class _OverviewReadinessGroupView extends StatelessWidget {
  const _OverviewReadinessGroupView({
    required this.group,
    required this.dense,
  });

  final _OverviewReadinessGroup group;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final label = Container(
          width: compact ? double.infinity : 92,
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: dense ? 8 : 13,
          ),
          alignment: compact ? Alignment.centerLeft : Alignment.topCenter,
          color: const Color(0xFFF8FAFC),
          child: Text(
            group.label,
            style: const TextStyle(
              color: _onlineStoreText,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
        );
        final rows = Column(
          children: group.items
              .map(
                (item) => _OverviewReadinessRow(item: item, dense: dense),
              )
              .toList(growable: false),
        );

        return Container(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.only(bottom: dense ? 6 : 10),
          decoration: BoxDecoration(
            border: Border.all(color: _onlineStoreBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: compact
              ? Column(children: [label, rows])
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [label, Expanded(child: rows)],
                  ),
                ),
        );
      },
    );
  }
}

class _OverviewReadinessRow extends StatelessWidget {
  const _OverviewReadinessRow({
    required this.item,
    required this.dense,
  });

  final _OverviewReadinessItem item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 39 : 47),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 11 : 14,
        vertical: dense ? 5 : 8,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: _onlineStoreText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: _onlineStoreText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: item.positive
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
                  : EdgeInsets.zero,
              decoration: item.positive
                  ? BoxDecoration(
                      color: const Color(0xFFEAF8EE),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.color ?? _onlineStoreText,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (item.positive) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle,
              size: 17,
              color: TenantAdminColors.success,
            ),
          ] else if (item.warning) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: TenantAdminColors.warning,
            ),
          ],
          if (item.showExternal) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.open_in_new,
              size: 17,
              color: TenantAdminColors.info,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewInsightsCard extends StatelessWidget {
  const _OverviewInsightsCard({required this.steps});

  final List<OnlineStoreStep> steps;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 820;
    final completed = steps.where(_isStepComplete).length;
    final attention = steps.where(_isStepBlocked).length;
    final inProgress = steps
        .where((step) => !_isStepComplete(step) && !_isStepBlocked(step))
        .length;
    final insights = [
      _OverviewInsight(
        Icons.check_circle,
        TenantAdminColors.success,
        completed,
        'Completed',
        'Everything good',
      ),
      _OverviewInsight(
        Icons.priority_high_rounded,
        TenantAdminColors.warning,
        attention,
        'Need attention',
        'Action required',
      ),
      _OverviewInsight(
        Icons.schedule,
        _onlineStoreText,
        inProgress,
        'In progress',
        'Almost there',
      ),
      _OverviewInsight(
        Icons.info,
        TenantAdminColors.info,
        steps.where((step) => step.blockingReasons.isEmpty).length,
        'Informational',
        'For your awareness',
      ),
    ];

    return _OnlineStoreCard(
      title: 'Setup Insights',
      padding: EdgeInsets.all(dense ? 13 : 18),
      headerSpacing: dense ? 8 : 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 560 ? 2 : 4;
          final width = (constraints.maxWidth - (12 * (columns - 1))) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: insights
                .map((item) => SizedBox(
                      width: width,
                      child: _OverviewInsightTile(item: item, dense: dense),
                    ))
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _OverviewInsight {
  const _OverviewInsight(
    this.icon,
    this.color,
    this.value,
    this.label,
    this.caption,
  );

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final String caption;
}

class _OverviewInsightTile extends StatelessWidget {
  const _OverviewInsightTile({required this.item, required this.dense});

  final _OverviewInsight item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 72 : 92),
      padding: EdgeInsets.all(dense ? 8 : 11),
      decoration: BoxDecoration(
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: dense ? 22 : 27),
              const SizedBox(width: 8),
              Text(
                '${item.value}',
                style: TextStyle(
                  color: _onlineStoreText,
                  fontSize: dense ? 19 : 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: const TextStyle(
              color: _onlineStoreText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            item.caption,
            style: const TextStyle(color: _onlineStoreMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  const _OverviewHeroCard({required this.canPublish});

  final bool canPublish;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Build. Configure. Launch.',
      padding: const EdgeInsets.all(22),
      headerSpacing: 14,
      child: Column(
        children: [
          const _OnlineStoreHeroIllustration(),
          const SizedBox(height: 16),
          Text(
            canPublish
                ? 'Your store is ready to publish.'
                : 'Complete your remaining setup tasks, publish your store and start selling.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _onlineStoreMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStoreHeroIllustration extends StatelessWidget {
  const _OnlineStoreHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFFFFF8F3),
        child: AspectRatio(
          aspectRatio: 1693 / 929,
          child: Image.asset(
            'assets/images/online_store/overview_storefront_hero.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel:
                'Online storefront with products, shopping cart and success badge',
          ),
        ),
      ),
    );
  }
}

class _OverviewNextStepsCard extends StatelessWidget {
  const _OverviewNextStepsCard({required this.steps});

  final List<OnlineStoreStep> steps;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Next Steps',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${steps.length} tasks remaining',
          style: const TextStyle(
            color: _onlineStoreOrange,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      headerSpacing: 10,
      child: Column(
        children: [
          if (steps.isEmpty)
            _ActionRow(
              icon: Icons.rocket_launch_outlined,
              title: 'Review & Publish',
              subtitle: 'Review all settings and publish your store',
              onTap: () => context.go('/tenant-admin/online-store/review'),
            )
          else
            ...steps.map(
              (step) => _ActionRow(
                icon: _overviewActionIcon(step.stepNumber),
                title: _overviewActionTitle(step),
                subtitle: _overviewActionSubtitle(step),
                onTap: () => context.go(
                  OnlineStoreSetupScreen.steps
                      .firstWhere(
                        (item) => item.number == step.stepNumber,
                        orElse: () => OnlineStoreSetupScreen.steps.last,
                      )
                      .route,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnlineStoreActivationStep extends ConsumerWidget {
  const _OnlineStoreActivationStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activationState = ref.watch(onlineStoreActivationProvider);
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    final canManage = access.canManageOnlineStore();

    return _AsyncSection<OnlineStoreActivation>(
      state: activationState,
      onRetry: () => ref.invalidate(onlineStoreActivationProvider),
      builder: (activation) {
        final readiness = activation.readiness;

        return Column(
          children: [
            const _ActivationPrivacyBanner(),
            const SizedBox(height: 18),
            _ActivationResponsiveLayout(
              left: _OnlineStoreCard(
                title: 'Launch Configuration',
                padding: const EdgeInsets.all(20),
                headerSpacing: 10,
                child: Column(
                  children: [
                    _ActivationConfigurationRow(
                      icon: Icons.power_settings_new,
                      title: 'Online Store Enabled',
                      description:
                          'Turn on your online channel to begin setup.',
                      trailing: Switch(
                        value: activation.setupEnabled,
                        activeThumbColor: _onlineStoreOrange,
                        onChanged: canManage && !mutationState.isLoading
                            ? (value) => _mutate(
                                  context,
                                  ref
                                      .read(
                                        onlineStoreMutationControllerProvider
                                            .notifier,
                                      )
                                      .updateActivation(value),
                                )
                            : null,
                      ),
                    ),
                    _ActivationConfigurationRow(
                      icon: Icons.my_location_outlined,
                      title: 'Release Scope',
                      description:
                          'Release 1 uses the entitled fulfilment channel.',
                      trailing: _ActivationValueChip(
                        label: _onlineStoreContractLabel(
                          activation.releaseScope,
                        ),
                      ),
                    ),
                    _ActivationConfigurationRow(
                      icon: Icons.person_outline,
                      title: 'Checkout Mode',
                      description:
                          'Customers must sign in before placing orders.',
                      trailing: _ActivationValueChip(
                        label: _onlineStoreContractLabel(
                          activation.checkoutMode,
                        ),
                      ),
                    ),
                    _ActivationConfigurationRow(
                      icon: Icons.mark_email_read_outlined,
                      title: 'Email Verification',
                      description:
                          'Customer email verification is required at checkout.',
                      trailing: _StatusChip(
                        label: activation.emailVerificationRequired
                            ? 'Required'
                            : 'Optional',
                      ),
                    ),
                    _ActivationConfigurationRow(
                      icon: Icons.payment_outlined,
                      title: 'Payment Method',
                      description:
                          'Release 1 orders are paid when they are collected.',
                      trailing: _ActivationValueChip(
                        label: _onlineStoreContractLabel(
                          activation.paymentMode,
                        ),
                      ),
                    ),
                    _ActivationConfigurationRow(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      description:
                          'Order and system notifications become available during setup.',
                      trailing: _StatusChip(
                        label: _onlineStoreContractLabel(
                          activation.notificationsStatus,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _ActivationInfoStrip(
                      message:
                          'Collection outlets will be configured later in Step 7 — Click & Collect.',
                    ),
                    if (!canManage)
                      const _PermissionNotice(
                        message:
                            '`tenant.online_store.manage` is required to change activation.',
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  _OnlineStoreCard(
                    title: 'Setup Readiness',
                    padding: const EdgeInsets.all(20),
                    headerSpacing: 8,
                    child: Column(
                      children: [
                        for (var index = 0; index < readiness.length; index++)
                          _ActivationReadinessRow(
                            title: readiness[index].label,
                            description: readiness[index].message,
                            status: readiness[index].status,
                            isLast: index == readiness.length - 1,
                          ),
                        if (readiness.isEmpty)
                          const _ActivationReadinessRow(
                            title: 'Readiness unavailable',
                            description:
                                'The backend did not return activation readiness details.',
                            status: 'NOT_READY',
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  if (activation.privateUntilPublished) ...[
                    const SizedBox(height: 18),
                    const _PrivateUntilPublishedCard(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivationPrivacyBanner extends StatelessWidget {
  const _ActivationPrivacyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        border: Border.all(color: const Color(0xFFAECBF9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final message = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D63D8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your store remains private until you publish it.',
                      style: TextStyle(
                        color: _onlineStoreText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Enabling the online store allows you to complete setup tasks. It will not be visible to customers until you publish.',
                      style: TextStyle(
                        color: Color(0xFF53627A),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 720) {
            return message;
          }

          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 24),
              const _StoreLockIllustration(),
            ],
          );
        },
      ),
    );
  }
}

class _StoreLockIllustration extends StatelessWidget {
  const _StoreLockIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC7D7F4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Color(0xFF1D63D8),
              size: 46,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 4,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1D63D8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationResponsiveLayout extends StatelessWidget {
  const _ActivationResponsiveLayout({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: [
              left,
              const SizedBox(height: 18),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: left),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: right),
          ],
        );
      },
    );
  }
}

class _ActivationConfigurationRow extends StatelessWidget {
  const _ActivationConfigurationRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _onlineStoreText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: _onlineStoreMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: trailing),
        ],
      ),
    );
  }
}

class _ActivationValueChip extends StatelessWidget {
  const _ActivationValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: _onlineStoreText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActivationInfoStrip extends StatelessWidget {
  const _ActivationInfoStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        border: Border.all(color: const Color(0xFFAECBF9)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1D63D8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF174EA6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationReadinessRow extends StatelessWidget {
  const _ActivationReadinessRow({
    required this.title,
    required this.description,
    required this.status,
    this.isLast = false,
  });

  final String title;
  final String description;
  final String status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _onlineStoreMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(_statusIcon(status), color: color, size: 22),
        ],
      ),
    );
  }
}

class _PrivateUntilPublishedCard extends StatelessWidget {
  const _PrivateUntilPublishedCard();

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Private Until Published',
      padding: const EdgeInsets.all(20),
      headerSpacing: 12,
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFF1D63D8),
              size: 50,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Text(
              'Your store is private during setup. Customers cannot access your store until you publish it.',
              style: TextStyle(
                color: Color(0xFF53627A),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _onlineStoreContractLabel(String value) {
  return value
      .trim()
      .toLowerCase()
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

bool _isOnlineStoreReadyStatus(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'PASS':
    case 'READY':
    case 'COMPLETE':
    case 'CONFIGURED':
    case 'ENABLED':
    case 'ACTIVE':
    case 'VERIFIED':
    case 'PUBLISHED':
      return true;
    default:
      return false;
  }
}

class _OnlineStoreIdentityStep extends ConsumerWidget {
  const _OnlineStoreIdentityStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityState = ref.watch(onlineStoreIdentityProvider);
    final checkoutRulesState = ref.watch(onlineStoreCheckoutRulesProvider);
    return _AsyncSection<OnlineStoreIdentity>(
      state: identityState,
      onRetry: () => ref.invalidate(onlineStoreIdentityProvider),
      builder: (identity) => _AsyncSection<OnlineStoreCheckoutRules>(
        state: checkoutRulesState,
        onRetry: () => ref.invalidate(onlineStoreCheckoutRulesProvider),
        builder: (checkoutRules) => _OnlineStoreIdentityForm(
          identity: identity,
          checkoutRules: checkoutRules,
          readOnly: !access.canManageOnlineStore(),
        ),
      ),
    );
  }
}

class _OnlineStoreIdentityForm extends ConsumerStatefulWidget {
  const _OnlineStoreIdentityForm({
    required this.identity,
    required this.checkoutRules,
    required this.readOnly,
  });

  final OnlineStoreIdentity identity;
  final OnlineStoreCheckoutRules checkoutRules;
  final bool readOnly;

  @override
  ConsumerState<_OnlineStoreIdentityForm> createState() =>
      _OnlineStoreIdentityFormState();
}

class _OnlineStoreIdentityFormState
    extends ConsumerState<_OnlineStoreIdentityForm> {
  late final TextEditingController _storeNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _emailController;
  late final TextEditingController _taglineController;

  @override
  void initState() {
    super.initState();
    _storeNameController =
        TextEditingController(text: widget.identity.storeName);
    _displayNameController =
        TextEditingController(text: widget.identity.businessDisplayName);
    _descriptionController =
        TextEditingController(text: widget.identity.storeDescription ?? '');
    _emailController =
        TextEditingController(text: widget.identity.storeEmail ?? '');
    _taglineController =
        TextEditingController(text: widget.identity.supportTagline ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(onlineStoreIdentityEditorProvider.notifier)
          .initialize(widget.identity);
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onlineStoreIdentityEditorProvider);
    final editor = ref.read(onlineStoreIdentityEditorProvider.notifier);
    final identityCard = _OnlineStoreCard(
      title: 'Store Identity',
      child: Column(
        children: [
          _TextInput(
            label: 'Online Store Name',
            controller: _storeNameController,
            readOnly: widget.readOnly,
            required: true,
            helperText: 'The public name of your online store.',
            errorText: draft.storeNameError,
            onChanged: editor.updateStoreName,
          ),
          _TextInput(
            label: 'Business Display Name',
            controller: _displayNameController,
            readOnly: widget.readOnly,
            required: true,
            helperText: 'The name displayed to customers on your storefront.',
            errorText: draft.businessDisplayNameError,
            onChanged: editor.updateBusinessDisplayName,
          ),
          _TextInput(
            label: 'Store Description',
            controller: _descriptionController,
            readOnly: widget.readOnly,
            required: false,
            maxLines: 3,
            helperText: 'A short description of your store and what you offer.',
            onChanged: editor.updateStoreDescription,
          ),
          _TextInput(
            label: 'Order Notification Email',
            controller: _emailController,
            readOnly: widget.readOnly,
            required: false,
            helperText: 'Email address to receive order notifications.',
            errorText: draft.storeEmailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: editor.updateStoreEmail,
          ),
          _TextInput(
            label: 'Support Tagline',
            controller: _taglineController,
            readOnly: widget.readOnly,
            required: false,
            helperText:
                'A short tagline shown on your storefront for customers.',
            onChanged: editor.updateSupportTagline,
          ),
          if (widget.readOnly)
            const _PermissionNotice(
              message:
                  '`tenant.online_store.manage` is required to edit identity.',
            ),
        ],
      ),
    );
    final rulesCard = _OnlineStoreCard(
      title: 'Release 1 Checkout Rules',
      child: Column(
        children: [
          _CheckoutRuleTile(
            icon: Icons.person_outline,
            title: 'Customer Account',
            description: 'Allow customers to create an account.',
            value: widget.checkoutRules.customerAccount.label,
          ),
          _CheckoutRuleTile(
            icon: Icons.person_off_outlined,
            title: 'Guest Checkout',
            description: 'Allow customers to checkout as guests.',
            value: widget.checkoutRules.guestCheckout.label,
            neutral: !widget.checkoutRules.guestCheckout.available,
          ),
          _CheckoutRuleTile(
            icon: Icons.mail_outline,
            title: 'Email Verification',
            description: 'Require email verification for new accounts.',
            value: widget.checkoutRules.emailVerification.label,
          ),
          _CheckoutRuleTile(
            icon: Icons.location_on_outlined,
            title: 'Fulfilment Mode',
            description: 'How orders will be fulfilled.',
            value: widget.checkoutRules.fulfilment.label,
          ),
          _CheckoutRuleTile(
            icon: Icons.credit_card_outlined,
            title: 'Payment Mode',
            description: 'How customers will complete payment.',
            value: widget.checkoutRules.payment.label,
          ),
          const _PermissionNotice(
            message:
                'These Release 1 rules are supplied and enforced by the backend checkout contract.',
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              identityCard,
              const SizedBox(height: 18),
              rulesCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identityCard),
            const SizedBox(width: 18),
            Expanded(child: rulesCard),
          ],
        );
      },
    );
  }
}

class _CheckoutRuleTile extends StatelessWidget {
  const _CheckoutRuleTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    this.neutral = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String value;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _onlineStoreText, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _onlineStoreMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: value,
            backgroundColor:
                neutral ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
            foregroundColor:
                neutral ? _onlineStoreMuted : const Color(0xFF1D4ED8),
          ),
        ],
      ),
    );
  }
}

class _OnlineStoreDomainStep extends ConsumerWidget {
  const _OnlineStoreDomainStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(onlineStoreUrlDomainProvider);
    return _AsyncSection<OnlineStoreUrlDomain>(
      state: domainState,
      onRetry: () => ref.invalidate(onlineStoreUrlDomainProvider),
      builder: (urlDomain) => _OnlineStoreDomainForm(
        urlDomain: urlDomain,
        canManageUrl: access.canManageOnlineStore(),
        canManageDomains: access.canManageOnlineStoreDomains(),
      ),
    );
  }
}

class _OnlineStoreDomainForm extends ConsumerStatefulWidget {
  const _OnlineStoreDomainForm({
    required this.urlDomain,
    required this.canManageUrl,
    required this.canManageDomains,
  });

  final OnlineStoreUrlDomain urlDomain;
  final bool canManageUrl;
  final bool canManageDomains;

  @override
  ConsumerState<_OnlineStoreDomainForm> createState() =>
      _OnlineStoreDomainFormState();
}

class _OnlineStoreDomainFormState
    extends ConsumerState<_OnlineStoreDomainForm> {
  late final TextEditingController _slugController;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController(text: widget.urlDomain.storeSlug);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(onlineStoreDomainEditorProvider.notifier)
          .initialize(widget.urlDomain);
    });
  }

  @override
  void didUpdateWidget(covariant _OnlineStoreDomainForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final editor = ref.read(onlineStoreDomainEditorProvider);
    if (!editor.isDirty &&
        widget.urlDomain.storeSlug != oldWidget.urlDomain.storeSlug) {
      _slugController.text = widget.urlDomain.storeSlug ?? '';
    }
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(onlineStoreDomainEditorProvider);
    final controller = ref.read(onlineStoreDomainEditorProvider.notifier);
    final selectedDomain = _selectedDomain(editor.selectedDomainId);
    return Column(
      children: [
        _ResponsiveTwoColumn(
          left: _OnlineStoreCard(
            title: 'Storefront URL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TextInput(
                  label: 'Store Slug',
                  controller: _slugController,
                  readOnly: !widget.canManageUrl,
                  required: true,
                  onChanged: controller.updateStoreSlug,
                  errorText: editor.slugError,
                  helperText:
                      'Your unique store slug used in the default OneVerz storefront URL.',
                ),
                _CopyableValueField(
                  label: 'Default Store URL',
                  value: widget.urlDomain.hostedUrl,
                ),
                const SizedBox(height: 2),
                const _FieldLabel(
                  label: 'Custom Domain (Optional)',
                  required: false,
                ),
                const SizedBox(height: 8),
                _DomainSelectionField(
                  domain: selectedDomain,
                  onManage: widget.canManageDomains ? _manageDomains : null,
                ),
                if (editor.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _InlineMessage(
                    icon: Icons.error_outline,
                    message: editor.errorMessage!,
                    tone: _InlineMessageTone.danger,
                  ),
                ],
              ],
            ),
          ),
          right: _OnlineStoreCard(
            title: 'Domain Verification',
            trailing: TextButton.icon(
              onPressed: widget.canManageDomains && !editor.isWorking
                  ? _manageDomains
                  : null,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Manage Domains'),
            ),
            child: _DomainVerificationContent(
              domain: selectedDomain,
              verificationToken: selectedDomain == null
                  ? null
                  : editor.verificationTokens[selectedDomain.id],
              working: editor.isWorking,
              canManage: widget.canManageDomains,
              onAction: selectedDomain == null
                  ? null
                  : (action) => _handleDomainAction(selectedDomain, action),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _InlineMessage(
          icon: Icons.info_outline,
          message:
              'Custom domains are optional. SSL and DNS status are checked by the backend; refresh after provider processing starts.',
          tone: _InlineMessageTone.info,
        ),
      ],
    );
  }

  OnlineStoreDomain? _selectedDomain(String? selectedId) {
    final customDomains = widget.urlDomain.domains
        .where((domain) => domain.domainType == 'CUSTOM');
    for (final domain in customDomains) {
      if (domain.id == selectedId) return domain;
    }
    for (final domain in customDomains) {
      if (domain.isPrimary) return domain;
    }
    return customDomains.firstOrNull;
  }

  Future<void> _manageDomains() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final domainState = ref.watch(onlineStoreUrlDomainProvider);
          final editor = ref.watch(onlineStoreDomainEditorProvider);
          return AlertDialog(
            title: const Text('Manage Custom Domains'),
            content: SizedBox(
              width: 720,
              child: domainState.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _OnlineStoreErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(onlineStoreUrlDomainProvider),
                ),
                data: (data) => data.domains
                        .where((domain) => domain.domainType == 'CUSTOM')
                        .isEmpty
                    ? const _OnlineStoreEmptyState(
                        title: 'No custom domains',
                        message:
                            'Add a hostname to begin DNS verification and SSL setup.',
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 430),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: data.domains
                              .where((domain) => domain.domainType == 'CUSTOM')
                              .length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final domain = data.domains
                                .where(
                                  (domain) => domain.domainType == 'CUSTOM',
                                )
                                .elementAt(index);
                            return _DomainRow(
                              domain: domain,
                              selected: editor.selectedDomainId == domain.id,
                              canManage:
                                  widget.canManageDomains && !editor.isWorking,
                              onTap: () => ref
                                  .read(
                                      onlineStoreDomainEditorProvider.notifier)
                                  .selectDomain(domain.id),
                              onAction: (action) =>
                                  _handleDomainAction(domain, action),
                            );
                          },
                        ),
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: editor.isWorking ? null : _addDomain,
                child: const Text('Add Domain'),
              ),
              FilledButton(
                onPressed: editor.isWorking
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addDomain() async {
    final textController = TextEditingController();
    final domainName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add custom domain'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'store.example.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              textController.text.trim(),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (!mounted || domainName == null || domainName.isEmpty) return;
    await _showDomainResult(
      ref
          .read(onlineStoreDomainEditorProvider.notifier)
          .createDomain(domainName),
      'Custom domain added. Copy the new TXT token before closing this step.',
    );
  }

  Future<void> _handleDomainAction(
    OnlineStoreDomain domain,
    String action,
  ) async {
    if (action == 'delete' &&
        !await _confirm(
          'Remove domain?',
          'The domain will be removed only after the backend confirms the request.',
        )) {
      return;
    }
    if (action == 'rotate' &&
        !await _confirm(
          'Rotate verification token?',
          'The previous DNS TXT token will no longer be valid.',
        )) {
      return;
    }
    final controller = ref.read(onlineStoreDomainEditorProvider.notifier);
    final future = switch (action) {
      'verify' => controller.verify(domain.id),
      'rotate' => controller.rotateToken(domain.id),
      'refresh' => controller.refreshStatus(domain.id),
      'ssl' => controller.provisionSsl(domain.id),
      'primary' => controller.setPrimary(domain.id),
      'delete' => controller.deleteDomain(domain.id),
      _ => Future<bool>.value(false),
    };
    await _showDomainResult(future, 'Domain status updated.');
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showDomainResult(
    Future<bool> operation,
    String successMessage,
  ) async {
    final succeeded = await operation;
    if (!mounted) return;
    final editor = ref.read(onlineStoreDomainEditorProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? successMessage
              : editor.errorMessage ?? 'Domain action could not be completed.',
        ),
      ),
    );
  }
}

class _OnlineStoreBrandingStep extends ConsumerWidget {
  const _OnlineStoreBrandingStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandingState = ref.watch(onlineStoreBrandingProvider);
    return _AsyncSection<OnlineStoreBranding>(
      state: brandingState,
      onRetry: () => ref.invalidate(onlineStoreBrandingProvider),
      builder: (branding) => _OnlineStoreBrandingForm(
        branding: branding,
        readOnly: !access.canManageOnlineStoreBranding(),
      ),
    );
  }
}

class _OnlineStoreBrandingForm extends ConsumerStatefulWidget {
  const _OnlineStoreBrandingForm({
    required this.branding,
    required this.readOnly,
  });

  final OnlineStoreBranding branding;
  final bool readOnly;

  @override
  ConsumerState<_OnlineStoreBrandingForm> createState() =>
      _OnlineStoreBrandingFormState();
}

class _OnlineStoreBrandingFormState
    extends ConsumerState<_OnlineStoreBrandingForm> {
  late final TextEditingController _primaryColorController;
  late final TextEditingController _secondaryColorController;

  @override
  void initState() {
    super.initState();
    _primaryColorController =
        TextEditingController(text: widget.branding.primaryColor);
    _secondaryColorController = TextEditingController(
      text: widget.branding.secondaryColor,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(onlineStoreBrandingEditorProvider.notifier)
          .initialize(widget.branding);
    });
  }

  @override
  void dispose() {
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onlineStoreBrandingEditorProvider);
    final editor = ref.read(onlineStoreBrandingEditorProvider.notifier);
    final bannerMutation = ref.watch(onlineStoreBannerMutationProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackColumns = constraints.maxWidth < 720;
        final assetsCard = _BrandingAssetsCard(
          state: draft,
          primaryColorController: _primaryColorController,
          secondaryColorController: _secondaryColorController,
          readOnly: widget.readOnly,
          onReplaceLogo: () => _pickAndAttachMedia(
            OnlineStoreBrandingEditorController.logoPurpose,
          ),
          onReplaceFavicon: () => _pickAndAttachMedia(
            OnlineStoreBrandingEditorController.faviconPurpose,
          ),
          onRemoveLogo: draft.logoMediaAssetId == null
              ? null
              : () => _confirmRemove(
                    'store logo',
                    OnlineStoreBrandingEditorController.logoPurpose,
                  ),
          onRemoveFavicon: draft.faviconMediaAssetId == null
              ? null
              : () => _confirmRemove(
                    'favicon',
                    OnlineStoreBrandingEditorController.faviconPurpose,
                  ),
          onPrimaryChanged: editor.updatePrimaryColor,
          onSecondaryChanged: editor.updateSecondaryColor,
        );
        final preview = _StorefrontPreviewCard(
          branding: widget.branding,
          primaryColor: _colorFromHex(draft.primaryColor, _onlineStoreOrange),
          secondaryColor: _colorFromHex(draft.secondaryColor, _onlineStoreText),
        );
        final manager = _BannerManagerCard(
          banners: widget.branding.banners,
          readOnly: widget.readOnly,
          isWorking: bannerMutation.isWorking,
          onAdd: () => _showBannerEditor(),
          onManageOrder: _showBannerOrderDialog,
          onAction: _handleBannerAction,
        );

        if (stackColumns) {
          return Column(
            children: [
              assetsCard,
              const SizedBox(height: 16),
              preview,
              const SizedBox(height: 16),
              manager,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 31, child: assetsCard),
            const SizedBox(width: 16),
            Expanded(
              flex: 69,
              child: Column(
                children: [
                  preview,
                  const SizedBox(height: 16),
                  manager,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBannerEditor([OnlineStoreBanner? banner]) async {
    if (widget.readOnly) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _BannerEditorDialog(existing: banner),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(banner == null ? 'Banner added.' : 'Banner updated.')),
    );
  }

  Future<void> _showBannerOrderDialog() async {
    if (widget.readOnly || widget.branding.banners.length < 2) return;
    final ordered = await showDialog<List<OnlineStoreBanner>>(
      context: context,
      builder: (dialogContext) =>
          _BannerOrderDialog(banners: widget.branding.banners),
    );
    if (!mounted || ordered == null) return;
    final succeeded = await ref
        .read(onlineStoreBannerMutationProvider.notifier)
        .reorder(ordered);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(succeeded
              ? 'Banner order saved.'
              : 'Banner order could not be saved.')),
    );
  }

  Future<void> _handleBannerAction(
    OnlineStoreBanner banner,
    String action,
  ) async {
    if (widget.readOnly) return;
    if (action == 'edit') {
      await _showBannerEditor(banner);
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete banner?'),
          content: const Text(
            'This banner will be removed from the storefront banner configuration.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await ref
          .read(onlineStoreBannerMutationProvider.notifier)
          .deleteBanner(banner);
      return;
    }
    await ref
        .read(onlineStoreBannerMutationProvider.notifier)
        .changeStatus(banner, action == 'activate' ? 'ACTIVE' : 'INACTIVE');
  }

  Future<void> _pickAndAttachMedia(String purpose) async {
    if (widget.readOnly) {
      return;
    }

    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (pickedImage == null || !mounted) {
      return;
    }

    final bytes = await pickedImage.readAsBytes();
    if (!mounted) {
      return;
    }

    final mimeType =
        pickedImage.mimeType ?? _inferImageMimeType(pickedImage.name);
    final succeeded = await ref
        .read(onlineStoreBrandingEditorProvider.notifier)
        .uploadAndAttach(
          purpose: purpose,
          bytes: bytes,
          fileName: pickedImage.name,
          mimeType: mimeType,
        );
    if (!mounted) return;
    _showMediaResult(succeeded, succeeded ? 'Image updated.' : null);
  }

  Future<void> _confirmRemove(String assetLabel, String purpose) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $assetLabel?'),
        content: Text(
          'This removes the $assetLabel from your online store branding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final succeeded = await ref
        .read(onlineStoreBrandingEditorProvider.notifier)
        .removeAsset(purpose);
    if (!mounted) return;
    _showMediaResult(succeeded, succeeded ? 'Image removed.' : null);
  }

  void _showMediaResult(bool succeeded, String? successMessage) {
    final error = ref.read(onlineStoreBrandingEditorProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? successMessage! : error ?? 'Branding action failed.',
        ),
      ),
    );
  }
}

class _OnlineStoreSupportStep extends ConsumerWidget {
  const _OnlineStoreSupportStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportState = ref.watch(onlineStoreSupportProvider);
    return _AsyncSection<OnlineStoreSupport>(
      state: supportState,
      onRetry: () => ref.invalidate(onlineStoreSupportProvider),
      loadingBuilder: () => const _OnlineStoreSupportLoading(),
      errorMessage: 'Unable to load contact & support settings.',
      builder: (support) => _OnlineStoreSupportForm(
        support: support,
        readOnly: !access.canManageOnlineStoreSupport(),
      ),
    );
  }
}

class _OnlineStoreSupportLoading extends StatelessWidget {
  const _OnlineStoreSupportLoading();

  @override
  Widget build(BuildContext context) {
    return const _ResponsiveTwoColumn(
      left: _OnlineStoreCard(
        title: 'Customer Contact',
        child: _SupportLoadingLines(),
      ),
      right: _OnlineStoreCard(
        title: 'Support Settings',
        child: _SupportLoadingLines(),
      ),
    );
  }
}

class _SupportLoadingLines extends StatelessWidget {
  const _SupportLoadingLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _OnlineStoreSupportForm extends ConsumerStatefulWidget {
  const _OnlineStoreSupportForm({
    required this.support,
    required this.readOnly,
  });

  final OnlineStoreSupport support;
  final bool readOnly;

  @override
  ConsumerState<_OnlineStoreSupportForm> createState() =>
      _OnlineStoreSupportFormState();
}

class _OnlineStoreSupportFormState
    extends ConsumerState<_OnlineStoreSupportForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _helpUrlController;
  late final TextEditingController _hoursController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.support.email ?? '');
    _phoneController = TextEditingController(text: widget.support.phone ?? '');
    _whatsappController =
        TextEditingController(text: widget.support.whatsapp ?? '');
    _helpUrlController =
        TextEditingController(text: widget.support.helpUrl ?? '');
    _hoursController =
        TextEditingController(text: widget.support.supportHours ?? '');
    _addressController =
        TextEditingController(text: widget.support.businessAddress ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(onlineStoreSupportEditorProvider.notifier)
          .initialize(widget.support);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _helpUrlController.dispose();
    _hoursController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onlineStoreSupportEditorProvider);
    final editor = ref.read(onlineStoreSupportEditorProvider.notifier);
    final customerContact = _OnlineStoreCard(
      title: 'Customer Contact',
      child: Column(
        children: [
          _TextInput(
            label: 'Support Email',
            controller: _emailController,
            readOnly: widget.readOnly,
            required: true,
            helperText:
                'Customers can use this email for store support enquiries.',
            errorText: draft.emailError,
            keyboardType: TextInputType.emailAddress,
            onChanged: editor.updateEmail,
          ),
          _TextInput(
            label: 'Support Phone',
            controller: _phoneController,
            readOnly: widget.readOnly,
            required: true,
            helperText:
                'Required for support readiness; international formats are accepted.',
            errorText: draft.phoneError,
            keyboardType: TextInputType.phone,
            onChanged: editor.updatePhone,
          ),
          _TextInput(
            label: 'WhatsApp Number',
            controller: _whatsappController,
            readOnly: widget.readOnly,
            required: false,
            helperText: 'Number customers can use for WhatsApp support.',
            errorText: draft.whatsappError,
            keyboardType: TextInputType.phone,
            onChanged: editor.updateWhatsapp,
          ),
          _TextInput(
            label: 'Help / Support URL',
            controller: _helpUrlController,
            readOnly: widget.readOnly,
            required: false,
            helperText: 'Optional HTTPS link to your customer help content.',
            errorText: draft.helpUrlError,
            keyboardType: TextInputType.url,
            onChanged: editor.updateHelpUrl,
          ),
        ],
      ),
    );
    final supportSettings = _OnlineStoreCard(
      title: 'Support Settings',
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              value: draft.contactUsEnabled,
              activeThumbColor: _onlineStoreOrange,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Show Contact Us to customers',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Display your support contact information on the storefront.',
              ),
              onChanged: widget.readOnly || draft.isSaving
                  ? null
                  : editor.updateContactUsEnabled,
            ),
          ),
          const SizedBox(height: 8),
          _TextInput(
            label: 'Business Address',
            controller: _addressController,
            readOnly: widget.readOnly,
            required: true,
            maxLines: 3,
            helperText:
                'Customer-facing support address; this is not an outlet address.',
            errorText: draft.businessAddressError,
            onChanged: editor.updateBusinessAddress,
          ),
          _TextInput(
            label: 'Support Hours',
            controller: _hoursController,
            readOnly: widget.readOnly,
            required: true,
            maxLines: 2,
            helperText:
                'Use day and time ranges, for example Mon - Fri: 9:00 AM - 6:00 PM.',
            errorText: draft.supportHoursError,
            onChanged: editor.updateSupportHours,
          ),
          const _PermissionNotice(
            message:
                'Support email, phone, business address and support hours are required by backend publish readiness.',
          ),
          if (widget.readOnly)
            const _PermissionNotice(
              message:
                  '`tenant.online_store.support.manage` is required to edit support.',
            ),
        ],
      ),
    );
    final preview = _OnlineStoreCard(
      title: 'Customer Support Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.email_outlined,
                  value: draft.email,
                ),
              ),
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.phone_outlined,
                  value: draft.phone,
                ),
              ),
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.chat_outlined,
                  value: draft.whatsapp,
                  color: TenantAdminColors.success,
                ),
              ),
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.link,
                  value: draft.helpUrl,
                  color: TenantAdminColors.info,
                ),
              ),
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.location_on_outlined,
                  value: draft.businessAddress,
                ),
              ),
              SizedBox(
                width: 310,
                child: _PreviewContactRow(
                  icon: Icons.schedule,
                  value: draft.supportHours,
                ),
              ),
            ],
          ),
          _PermissionNotice(
            message: draft.contactUsEnabled
                ? 'Contact Us is enabled for customer-facing display.'
                : 'Contact Us is disabled; saved details remain configured.',
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 900;
        if (stack) {
          return Column(
            children: [
              customerContact,
              const SizedBox(height: 16),
              supportSettings,
              const SizedBox(height: 16),
              preview,
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: customerContact),
                const SizedBox(width: 18),
                Expanded(child: supportSettings),
              ],
            ),
            const SizedBox(height: 18),
            preview,
          ],
        );
      },
    );
  }
}

class _OnlineStoreClickCollectStep extends ConsumerWidget {
  const _OnlineStoreClickCollectStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!access.hasFeature('click_collect')) {
      return const _OnlineStoreErrorCard(
        message:
            'The `click_collect` entitlement is not enabled for this tenant.',
      );
    }

    final clickCollectState = ref.watch(onlineStoreClickCollectProvider);
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    final canManage = access.canManageOnlineStoreFulfillment();

    return _AsyncSection<OnlineStoreClickCollect>(
      state: clickCollectState,
      onRetry: () => ref.invalidate(onlineStoreClickCollectProvider),
      builder: (clickCollect) {
        return _ResponsiveTwoColumn(
          leftFlex: 2,
          rightFlex: 1,
          left: Column(
            children: [
              _OnlineStoreCard(
                title: 'Enable Click & Collect',
                trailing: Switch(
                  value: clickCollect.enabled,
                  activeThumbColor: _onlineStoreOrange,
                  onChanged: canManage && !mutationState.isLoading
                      ? (value) async {
                          await _mutate(
                            context,
                            ref
                                .read(onlineStoreMutationControllerProvider
                                    .notifier)
                                .updateClickCollect(value),
                          );
                        }
                      : null,
                ),
                child: const Text(
                  'Allow customers to order online and collect from backend-configured outlets.',
                  style: TextStyle(color: _onlineStoreMuted),
                ),
              ),
              const SizedBox(height: 16),
              _OnlineStoreCard(
                title: 'Collection Outlets & Rules',
                child: clickCollect.outlets.isEmpty
                    ? const _OnlineStoreEmptyState(
                        title: 'No collection outlets',
                        message:
                            'The backend returned no click & collect outlet rules.',
                      )
                    : Column(
                        children: clickCollect.outlets
                            .map((outlet) =>
                                _CollectionOutletRow(outlet: outlet))
                            .toList(growable: false),
                      ),
              ),
            ],
          ),
          right: _OnlineStoreCard(
            title: 'General Rules',
            child: Column(
              children: [
                _InfoRow('Enabled', clickCollect.enabled ? 'Yes' : 'No'),
                _InfoRow('Outlet count', '${clickCollect.outletCount}'),
                if (!canManage)
                  const _PermissionNotice(
                    message:
                        '`tenant.online_store.fulfillment.manage` is required to edit click & collect.',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnlineStoreProductsPoliciesStep extends ConsumerWidget {
  const _OnlineStoreProductsPoliciesStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onlineStoreProductsPoliciesProvider);
    final productsState = ref.watch(onlineStoreCatalogProductsProvider);
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    return _AsyncSection<OnlineStoreProductsPoliciesData>(
      state: state,
      onRetry: () => ref.invalidate(onlineStoreProductsPoliciesProvider),
      builder: (data) {
        return _ResponsiveTwoColumn(
          left: _OnlineStoreCard(
            title: 'Online Product Catalogue',
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricTile(
                      label: 'Total Products',
                      value: '${data.summary.totalProducts}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _MetricTile(
                      label: 'Online Visible',
                      value: '${data.summary.visibleOnline}',
                      icon: Icons.visibility_outlined,
                      color: TenantAdminColors.success,
                    ),
                    _MetricTile(
                      label: 'Hidden',
                      value: '${data.summary.notVisible}',
                      icon: Icons.visibility_off_outlined,
                      color: TenantAdminColors.warning,
                    ),
                    _MetricTile(
                      label: 'Orderable',
                      value: '${data.summary.orderable}',
                      icon: Icons.shopping_bag_outlined,
                      color: TenantAdminColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                productsState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const Text(
                    'Product preview unavailable.',
                    style: TextStyle(color: TenantAdminColors.danger),
                  ),
                  data: (products) => Column(
                    children: products.items
                        .take(5)
                        .map(
                          (product) => _ProductVisibilityRow(
                            product: product,
                            canManage: access.canManageOnlineStoreCatalog() &&
                                !mutationState.isLoading,
                            onChanged: (visible) => _mutate(
                              context,
                              ref
                                  .read(onlineStoreMutationControllerProvider
                                      .notifier)
                                  .updateProductVisibility(
                                    product.productId,
                                    visible,
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                if (!access.canManageOnlineStoreCatalog())
                  const _PermissionNotice(
                    message:
                        '`tenant.online_store.catalog.manage` is required for catalog changes.',
                  ),
              ],
            ),
          ),
          right: _OnlineStoreCard(
            title: 'Customer Policies',
            child: data.policies.isEmpty
                ? const _OnlineStoreEmptyState(
                    title: 'No policies returned',
                    message: 'The backend returned no customer policies.',
                  )
                : Column(
                    children: data.policies
                        .map(
                          (policy) => _PolicyRow(
                            policy: policy,
                            canManage: access.canManageOnlineStorePolicies(),
                            onPublish: () => _mutate(
                              context,
                              ref
                                  .read(onlineStoreMutationControllerProvider
                                      .notifier)
                                  .publishPolicy(policy.policyType),
                            ),
                            onArchive: () => _mutate(
                              context,
                              ref
                                  .read(onlineStoreMutationControllerProvider
                                      .notifier)
                                  .archivePolicy(policy.policyType),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        );
      },
    );
  }
}

class _OnlineStoreReviewStep extends ConsumerWidget {
  const _OnlineStoreReviewStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(onlineStoreOverviewProvider);
    final readinessState = ref.watch(onlineStoreReadinessProvider);
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    final canPublish = access.canPublishOnlineStore();

    return _AsyncSection<OnlineStoreOverview>(
      state: overviewState,
      onRetry: () => ref.invalidate(onlineStoreOverviewProvider),
      builder: (overview) {
        final readiness = readinessState.asData?.value ?? overview.readiness;
        return _ResponsiveTwoColumn(
          leftFlex: 3,
          rightFlex: 2,
          left: _OnlineStoreCard(
            title: 'Review Summary',
            child: overview.steps.isEmpty
                ? const _OnlineStoreEmptyState(
                    title: 'No setup steps',
                    message: 'The backend returned no setup summary rows.',
                  )
                : Column(
                    children: overview.steps
                        .map(
                          (step) => _ReadinessRow(
                            label: step.label,
                            status: step.status,
                            detail: step.blockingReasons.join(', '),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          right: Column(
            children: [
              _OnlineStoreCard(
                title: 'Readiness Checks',
                child: Column(
                  children: [
                    if (readiness.blockingReasons.isEmpty)
                      const _ReadinessCheck(
                        title: 'Final validation',
                        status: 'Ready',
                      )
                    else
                      ...readiness.blockingReasons.map(
                        (reason) => _ReadinessCheck(
                          title: reason,
                          status: 'Blocking',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OnlineStoreCard(
                title: 'Final Validation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      readiness.canPublish
                          ? 'All backend readiness checks passed.'
                          : 'Resolve the backend readiness blockers before publishing.',
                      style: const TextStyle(
                        color: _onlineStoreMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrimaryButton(
                      label: mutationState.isLoading
                          ? 'Publishing...'
                          : 'Save & Publish',
                      icon: Icons.lock_outline,
                      onPressed: canPublish &&
                              readiness.canPublish &&
                              !mutationState.isLoading
                          ? () => _mutate(
                                context,
                                ref
                                    .read(onlineStoreMutationControllerProvider
                                        .notifier)
                                    .publish(),
                              )
                          : null,
                    ),
                    if (!canPublish)
                      const _PermissionNotice(
                        message:
                            '`tenant.online_store.publish` is required to publish.',
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnlineStoreBottomActions extends ConsumerWidget {
  const _OnlineStoreBottomActions({
    required this.activeStep,
    required this.overview,
    required this.access,
  });

  final _OnlineStoreStepConfig activeStep;
  final OnlineStoreOverview? overview;
  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previousStep = activeStep.number > 1
        ? OnlineStoreSetupScreen.steps[activeStep.number - 2]
        : null;
    final nextStep = activeStep.number < OnlineStoreSetupScreen.steps.length
        ? OnlineStoreSetupScreen.steps[activeStep.number]
        : null;
    final backButton = activeStep.number == 1
        ? _SecondaryButton(
            label: 'Preview Storefront',
            icon: Icons.visibility_outlined,
            onPressed: () {
              final hostedUrl = overview?.hostedUrl?.trim();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hostedUrl == null || hostedUrl.isEmpty
                        ? 'Storefront URL is not available yet.'
                        : 'Storefront preview: $hostedUrl',
                  ),
                ),
              );
            },
          )
        : _SecondaryButton(
            label: activeStep.number == 2 ? 'Back to Overview' : 'Back',
            icon: Icons.arrow_back,
            onPressed: () => context.go(previousStep!.route),
          );
    final identityEditor = activeStep.number == 3
        ? ref.watch(onlineStoreIdentityEditorProvider)
        : null;
    final domainEditor = activeStep.number == 4
        ? ref.watch(onlineStoreDomainEditorProvider)
        : null;
    final brandingEditor = activeStep.number == 5
        ? ref.watch(onlineStoreBrandingEditorProvider)
        : null;
    final supportEditor = activeStep.number == 6
        ? ref.watch(onlineStoreSupportEditorProvider)
        : null;
    final isSaving = identityEditor?.isSaving == true ||
        domainEditor?.isSaving == true ||
        brandingEditor?.isWorking == true ||
        supportEditor?.isSaving == true;
    final continueButton = nextStep != null
        ? _PrimaryButton(
            label: isSaving
                ? 'Saving...'
                : activeStep.number == 1
                    ? 'Continue Setup'
                    : activeStep.number == 3 ||
                            activeStep.number == 4 ||
                            activeStep.number == 5 ||
                            activeStep.number == 6
                        ? 'Continue'
                        : 'Save & Continue',
            icon: Icons.arrow_forward,
            onPressed: isSaving
                ? null
                : () async {
                    if (activeStep.number == 3 &&
                        access.canManageOnlineStore()) {
                      final saved = await ref
                          .read(onlineStoreIdentityEditorProvider.notifier)
                          .saveIfNeeded();
                      if (!saved || !context.mounted) return;
                    }
                    if (activeStep.number == 4 &&
                        access.canManageOnlineStore()) {
                      final saved = await ref
                          .read(onlineStoreDomainEditorProvider.notifier)
                          .saveIfNeeded();
                      if (!saved || !context.mounted) return;
                    }
                    if (activeStep.number == 5 &&
                        access.canManageOnlineStoreBranding()) {
                      final saved = await ref
                          .read(onlineStoreBrandingEditorProvider.notifier)
                          .saveIfNeeded();
                      if (!saved || !context.mounted) return;
                    }
                    if (activeStep.number == 6 &&
                        access.canManageOnlineStoreSupport()) {
                      final saved = await ref
                          .read(onlineStoreSupportEditorProvider.notifier)
                          .saveIfNeeded();
                      if (!saved || !context.mounted) return;
                    }
                    if (context.mounted) context.go(nextStep.route);
                  },
          )
        : _PrimaryButton(
            label: 'Back to Overview',
            icon: Icons.check_circle_outline,
            onPressed: () => context.go('/tenant-admin/online-store'),
          );
    final editorError = identityEditor?.errorMessage ??
        domainEditor?.errorMessage ??
        brandingEditor?.errorMessage ??
        supportEditor?.errorMessage;
    final editorDirty = identityEditor?.isDirty == true ||
        domainEditor?.isDirty == true ||
        brandingEditor?.isDirty == true ||
        supportEditor?.isDirty == true;
    final stateColor = editorError != null
        ? TenantAdminColors.danger
        : editorDirty
            ? const Color(0xFFD97706)
            : TenantAdminColors.success;
    final stateIcon = editorError != null
        ? Icons.error_outline
        : editorDirty
            ? Icons.info_outline
            : Icons.check_circle;
    final stateLabel = editorError != null
        ? 'Changes not saved'
        : editorDirty
            ? 'Unsaved changes'
            : 'All changes saved';
    final savedState = Semantics(
      label: stateLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaving)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: stateColor,
              ),
            )
          else
            Icon(stateIcon, color: stateColor, size: 22),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            isSaving ? 'Saving changes...' : stateLabel,
            style: TextStyle(
              color: stateColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1040;
        final useInlineLayout = !isCompact ||
            (activeStep.number == 5 && constraints.maxWidth >= 700);
        return Container(
          key: const ValueKey('online-store-bottom-actions'),
          padding: EdgeInsets.fromLTRB(
            isCompact ? TenantAdminSpacing.lg : TenantAdminSpacing.xxl,
            TenantAdminSpacing.md,
            isCompact ? TenantAdminSpacing.lg : TenantAdminSpacing.xxl,
            TenantAdminSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: TenantAdminColors.surface,
            border: Border(top: BorderSide(color: _onlineStoreBorder)),
          ),
          child: SafeArea(
            top: false,
            child: !useInlineLayout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: savedState),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Row(
                        children: [
                          Expanded(child: backButton),
                          const SizedBox(width: TenantAdminSpacing.md),
                          Expanded(child: continueButton),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      backButton,
                      const Spacer(),
                      savedState,
                      const Spacer(),
                      continueButton,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.state,
    required this.builder,
    required this.onRetry,
    this.loadingBuilder,
    this.errorMessage,
  });

  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final Widget Function()? loadingBuilder;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () =>
          loadingBuilder?.call() ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          ),
      error: (error, stackTrace) {
        String errMsg = errorMessage ?? 'An unexpected error occurred.';
        try {
          if (error.toString().contains('DioException') &&
              error.toString().contains('[403]')) {
            errMsg =
                'Access denied. You lack the necessary permissions or feature entitlement to view this data.';
          } else if (errorMessage == null) {
            errMsg = error.toString();
          }
        } catch (_) {
          errMsg = error.toString();
        }

        return _OnlineStoreErrorCard(
          message: errMsg,
          onRetry: onRetry,
        );
      },
      data: builder,
    );
  }
}

class _OnlineStoreCard extends StatelessWidget {
  const _OnlineStoreCard({
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(24),
    this.titleSize = 22,
    this.headerSpacing = 20,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double titleSize;
  final double headerSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _onlineStoreText,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          SizedBox(height: headerSpacing),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 18),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

class _ResponsiveThreeColumn extends StatelessWidget {
  const _ResponsiveThreeColumn({
    required this.left,
    required this.middle,
    required this.right,
  });

  final Widget left;
  final Widget middle;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1040) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              middle,
              const SizedBox(height: 16),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: middle),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    required this.readOnly,
    required this.required,
    this.maxLines = 1,
    this.onChanged,
    this.helperText,
    this.errorText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final bool required;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, required: required),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            minLines: maxLines,
            onChanged: onChanged,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _onlineStoreBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: _onlineStoreOrange,
                  width: 1.6,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _onlineStoreBorder),
              ),
              errorText: errorText,
            ),
          ),
          if (helperText != null && errorText == null) ...[
            const SizedBox(height: 6),
            Text(
              helperText!,
              style: const TextStyle(
                color: _onlineStoreMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: _display(value));
    return _TextInput(
      label: label,
      controller: controller,
      readOnly: true,
      required: false,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.required,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: _onlineStoreText,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: TenantAdminColors.danger),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _onlineStoreText),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _onlineStoreText),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(child: trailing),
        ],
      ),
    );
  }
}

class _ReadinessCheck extends StatelessWidget {
  const _ReadinessCheck({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(status, style: const TextStyle(color: _onlineStoreMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewContactRow extends StatelessWidget {
  const _PreviewContactRow({
    required this.icon,
    required this.value,
    this.color = _onlineStoreText,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                value.trim().isEmpty ? 'Not provided' : value.trim(),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _onlineStoreText,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _display(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _onlineStoreText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.label,
    required this.status,
    this.detail,
  });

  final String label;
  final String status;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          Icon(
            _statusIcon(status),
            color: color,
            semanticLabel: 'Status $status',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null && detail!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detail!,
                      style: const TextStyle(
                        color: _onlineStoreMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _StatusChip(label: status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? _statusColor(label);
    return Semantics(
      label: 'Status $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final progress = (percent.clamp(0, 100)) / 100;
    return Semantics(
      label: 'Setup progress $percent percent',
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              color: _onlineStoreOrange,
              backgroundColor: const Color(0xFFE5E7EB),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: _onlineStoreText,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _InlineMessageTone { info, danger }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage(
      {required this.icon, required this.message, required this.tone});

  final IconData icon;
  final String message;
  final _InlineMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == _InlineMessageTone.danger;
    final color = danger ? TenantAdminColors.danger : const Color(0xFF2563EB);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFF1F2) : const Color(0xFFEFF6FF),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _CopyableValueField extends StatelessWidget {
  const _CopyableValueField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim().isNotEmpty == true ? value! : 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FieldLabel(label: label, required: false),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: _onlineStoreBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Expanded(
                child: SelectableText(displayValue,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: 'Copy URL',
              onPressed: value == null || value!.trim().isEmpty
                  ? null
                  : () => _copyText(context, value!),
              icon: const Icon(Icons.copy_outlined, size: 19),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DomainSelectionField extends StatelessWidget {
  const _DomainSelectionField({required this.domain, required this.onManage});

  final OnlineStoreDomain? domain;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.language, color: _onlineStoreMuted),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(domain?.domainName ?? 'No custom domain connected',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (domain != null)
            Text(
                domain!.isPrimary
                    ? 'Primary custom domain'
                    : _statusLabel(domain!.status),
                style: const TextStyle(color: _onlineStoreMuted, fontSize: 12)),
        ])),
        TextButton(
            onPressed: onManage,
            child: Text(domain == null ? 'Connect' : 'Manage')),
      ]),
    );
  }
}

class _DomainVerificationContent extends StatelessWidget {
  const _DomainVerificationContent({
    required this.domain,
    required this.verificationToken,
    required this.working,
    required this.canManage,
    required this.onAction,
  });

  final OnlineStoreDomain? domain;
  final String? verificationToken;
  final bool working;
  final bool canManage;
  final ValueChanged<String>? onAction;

  @override
  Widget build(BuildContext context) {
    if (domain == null) {
      return const _OnlineStoreEmptyState(
        title: 'No domain selected',
        message:
            'Connect a custom domain to view DNS verification and SSL status.',
      );
    }
    final verified = domain!.verificationStatus == 'VERIFIED';
    final sslActive = domain!.sslStatus == 'ACTIVE';
    final sslPending = domain!.sslStatus == 'PENDING';
    return Column(children: [
      _DomainStatusLine(
        icon: Icons.dns_outlined,
        title: 'DNS Verification',
        detail: domain!.verifiedAt == null
            ? null
            : 'Verified ${_dateLabel(domain!.verifiedAt!)}',
        status: domain!.verificationStatus,
      ),
      _DomainStatusLine(
        icon: Icons.text_snippet_outlined,
        title: 'TXT Record',
        detail: verificationToken ??
            'Token is returned only after add or rotation.',
        status: verificationToken == null ? 'NOT_SHOWN' : 'AVAILABLE',
        copyValue: verificationToken,
      ),
      _DomainStatusLine(
        icon: Icons.lock_outline,
        title: 'SSL Certificate',
        detail: domain!.sslExpiresAt == null
            ? null
            : 'Expires ${_dateLabel(domain!.sslExpiresAt!)}',
        status: domain!.sslStatus,
      ),
      _DomainStatusLine(
        icon: Icons.star_outline,
        title: 'Primary Domain',
        status: domain!.isPrimary ? 'PRIMARY' : 'NOT_SET',
        showDivider: false,
      ),
      if (canManage) ...[
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: working ? null : () => onAction?.call('refresh'),
            icon: const Icon(Icons.refresh),
            label: Text(working ? 'Working...' : 'Check Status'),
          ),
          if (!verified)
            FilledButton.icon(
              onPressed: working ? null : () => onAction?.call('verify'),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verify Domain'),
            ),
          if (!verified)
            TextButton(
                onPressed: working ? null : () => onAction?.call('rotate'),
                child: const Text('Rotate Token')),
          if (verified && !sslActive && !sslPending)
            FilledButton.icon(
              onPressed: working ? null : () => onAction?.call('ssl'),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Provision SSL'),
            ),
          if (verified && sslActive && !domain!.isPrimary)
            FilledButton.icon(
              onPressed: working ? null : () => onAction?.call('primary'),
              icon: const Icon(Icons.star_outline),
              label: const Text('Set as Primary'),
            ),
        ]),
      ],
    ]);
  }
}

class _DomainStatusLine extends StatelessWidget {
  const _DomainStatusLine(
      {required this.icon,
      required this.title,
      required this.status,
      this.detail,
      this.copyValue,
      this.showDivider = true});

  final IconData icon;
  final String title;
  final String status;
  final String? detail;
  final String? copyValue;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: _onlineStoreBorder))
              : null),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _onlineStoreText),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (detail != null) ...[
            const SizedBox(height: 3),
            SelectableText(detail!,
                maxLines: 2,
                style: const TextStyle(color: _onlineStoreMuted, fontSize: 12)),
          ],
        ])),
        if (copyValue != null)
          IconButton(
              tooltip: 'Copy TXT token',
              onPressed: () => _copyText(context, copyValue!),
              icon: const Icon(Icons.copy_outlined, size: 18)),
        _StatusChip(label: _statusLabel(status)),
      ]),
    );
  }
}

Future<void> _copyText(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Copied')));
}

String _statusLabel(String value) {
  final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
  if (normalized.isEmpty) return 'Not set';
  return normalized
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _dateLabel(DateTime value) {
  final local = value.toLocal().toString();
  return local.length >= 16 ? local.substring(0, 16) : local;
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({
    required this.domain,
    required this.selected,
    required this.canManage,
    required this.onTap,
    required this.onAction,
  });

  final OnlineStoreDomain domain;
  final bool selected;
  final bool canManage;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final verified = domain.verificationStatus == 'VERIFIED';
    final sslActive = domain.sslStatus == 'ACTIVE';
    final sslPending = domain.sslStatus == 'PENDING';
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: const Icon(Icons.language),
      title: Text(domain.domainName),
      onTap: onTap,
      subtitle: Text(
        [
          domain.domainType,
          if (domain.isPrimary) 'Primary',
          domain.sslStatus,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(label: _statusLabel(domain.status)),
          if (canManage)
            PopupMenuButton<String>(
              tooltip: 'Domain actions',
              onSelected: onAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Text('Check status'),
                ),
                if (!verified)
                  const PopupMenuItem(
                    value: 'verify',
                    child: Text('Verify domain'),
                  ),
                if (!verified)
                  const PopupMenuItem(
                    value: 'rotate',
                    child: Text('Rotate verification token'),
                  ),
                if (verified && !sslActive && !sslPending)
                  const PopupMenuItem(
                    value: 'ssl',
                    child: Text('Provision SSL'),
                  ),
                if (verified && sslActive && !domain.isPrimary)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Text('Set as primary'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove domain'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BrandAssetsEditorCard extends StatelessWidget {
  const _BrandAssetsEditorCard({
    required this.state,
    required this.readOnly,
    required this.onReplaceLogo,
    required this.onReplaceFavicon,
    required this.onRemoveLogo,
    required this.onRemoveFavicon,
  });

  final OnlineStoreBrandingEditorState state;
  final bool readOnly;
  final VoidCallback onReplaceLogo;
  final VoidCallback onReplaceFavicon;
  final VoidCallback? onRemoveLogo;
  final VoidCallback? onRemoveFavicon;

  @override
  Widget build(BuildContext context) {
    final logoWorking = state.activeMediaPurpose ==
        OnlineStoreBrandingEditorController.logoPurpose;
    final faviconWorking = state.activeMediaPurpose ==
        OnlineStoreBrandingEditorController.faviconPurpose;
    return _OnlineStoreCard(
      title: 'Brand Assets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload the logo and browser icon shown on your storefront.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _BrandAssetPreview(
            label: 'Store Logo',
            helper: 'JPEG, PNG, WebP, SVG, or ICO. Maximum 5 MB.',
            attached: state.logoMediaAssetId != null ||
                state.pendingLogoBytes != null,
            previewHeight: 112,
            readOnly: readOnly || state.isWorking,
            onReplace: onReplaceLogo,
            onRemove: onRemoveLogo,
            child: _BrandMediaImage(
              bytes: state.pendingLogoBytes,
              url: state.logoImageUrl,
              semanticLabel: 'Store logo preview',
            ),
          ),
          if (logoWorking) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.uploadProgress),
          ],
          const SizedBox(height: 20),
          _BrandAssetPreview(
            label: 'Favicon',
            helper: 'JPEG, PNG, WebP, SVG, or ICO. Maximum 5 MB.',
            attached: state.faviconMediaAssetId != null ||
                state.pendingFaviconBytes != null,
            previewHeight: 72,
            compact: true,
            readOnly: readOnly || state.isWorking,
            onReplace: onReplaceFavicon,
            onRemove: onRemoveFavicon,
            child: _BrandMediaImage(
              bytes: state.pendingFaviconBytes,
              url: state.faviconImageUrl,
              semanticLabel: 'Favicon preview',
              fit: BoxFit.contain,
            ),
          ),
          if (faviconWorking) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.uploadProgress),
          ],
          if (readOnly) ...[
            const SizedBox(height: 18),
            const _PermissionNotice(
              message:
                  '`tenant.online_store.branding.manage` is required to edit branding.',
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandAppearanceEditorCard extends StatelessWidget {
  const _BrandAppearanceEditorCard({
    required this.state,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.readOnly,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  final OnlineStoreBrandingEditorState state;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final bool readOnly;
  final ValueChanged<String> onPrimaryChanged;
  final ValueChanged<String> onSecondaryChanged;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Brand Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose the colours used across your storefront.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _BrandColorField(
            label: 'Primary Brand Color',
            helper: 'Used for primary actions and storefront accents.',
            controller: primaryColorController,
            readOnly: readOnly,
            fallback: _onlineStoreOrange,
            errorText: state.primaryColorError,
            onChanged: onPrimaryChanged,
          ),
          const SizedBox(height: 18),
          _BrandColorField(
            label: 'Secondary Color',
            helper: 'Used for supporting storefront accents.',
            controller: secondaryColorController,
            readOnly: readOnly,
            fallback: _onlineStoreText,
            errorText: state.secondaryColorError,
            onChanged: onSecondaryChanged,
          ),
          const SizedBox(height: 20),
          const _PermissionNotice(
            message:
                'Only brand assets and colours supported by the backend are shown here.',
          ),
        ],
      ),
    );
  }
}

class _BrandStorefrontPreviewCard extends StatelessWidget {
  const _BrandStorefrontPreviewCard({
    required this.branding,
    required this.state,
  });

  final OnlineStoreBranding branding;
  final OnlineStoreBrandingEditorState state;

  @override
  Widget build(BuildContext context) {
    final primary = _colorFromHex(state.primaryColor, _onlineStoreOrange);
    final secondary = _colorFromHex(state.secondaryColor, _onlineStoreText);
    final banner = branding.banners.isEmpty ? null : branding.banners.first;
    return _OnlineStoreCard(
      title: 'Storefront Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview your saved assets and current colour choices.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _onlineStoreBorder),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 170,
                          height: 42,
                          child: state.logoMediaAssetId != null ||
                                  state.pendingLogoBytes != null
                              ? _BrandMediaImage(
                                  bytes: state.pendingLogoBytes,
                                  url: state.logoImageUrl,
                                  semanticLabel: 'Storefront logo',
                                  alignment: Alignment.centerLeft,
                                )
                              : Text(
                                  'STORE PREVIEW',
                                  style: TextStyle(
                                    color: secondary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                        const Spacer(),
                        Icon(Icons.search, color: secondary, size: 20),
                        const SizedBox(width: 14),
                        Icon(Icons.shopping_bag_outlined,
                            color: secondary, size: 20),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 190,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: secondary.withValues(alpha: 0.06),
                    image: banner?.imageUrl == null
                        ? null
                        : DecorationImage(
                            image: NetworkImage(banner!.imageUrl!),
                            fit: BoxFit.cover,
                            opacity: 0.2,
                          ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner?.title ?? 'Your storefront content',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner?.subtitle ??
                                'Brand colours are applied to customer-facing actions.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: secondary),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              banner?.actionText ?? 'Primary action',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(height: 8, color: primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMediaImage extends StatelessWidget {
  const _BrandMediaImage({
    required this.bytes,
    required this.url,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final Uint8List? bytes;
  final String? url;
  final String semanticLabel;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(Icons.image_outlined, color: _onlineStoreMuted, size: 30),
    );
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    final source = url?.trim();
    if (source == null || source.isEmpty) return fallback;
    return Image.network(
      source,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _BrandingAssetsCard extends StatelessWidget {
  const _BrandingAssetsCard({
    required this.state,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.readOnly,
    required this.onReplaceLogo,
    required this.onReplaceFavicon,
    required this.onRemoveLogo,
    required this.onRemoveFavicon,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
  });

  final OnlineStoreBrandingEditorState state;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final bool readOnly;
  final VoidCallback onReplaceLogo;
  final VoidCallback onReplaceFavicon;
  final VoidCallback? onRemoveLogo;
  final VoidCallback? onRemoveFavicon;
  final ValueChanged<String> onPrimaryChanged;
  final ValueChanged<String> onSecondaryChanged;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Branding Assets',
      padding: const EdgeInsets.all(16),
      titleSize: 19,
      headerSpacing: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload your brand assets and choose theme colours.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _BrandAssetPreview(
            label: 'Store Logo',
            helper: 'Recommended: 500x200px, PNG or SVG',
            attached: state.logoMediaAssetId != null ||
                state.pendingLogoBytes != null,
            previewHeight: 96,
            readOnly: readOnly,
            onReplace: onReplaceLogo,
            onRemove: onRemoveLogo,
            child: _BrandMediaImage(
              bytes: state.pendingLogoBytes,
              url: state.logoImageUrl,
              semanticLabel: 'Store logo preview',
            ),
          ),
          const SizedBox(height: 14),
          _BrandAssetPreview(
            label: 'Favicon',
            helper: 'Recommended: 32x32px, PNG or ICO',
            attached: state.faviconMediaAssetId != null ||
                state.pendingFaviconBytes != null,
            previewHeight: 68,
            compact: true,
            readOnly: readOnly,
            onReplace: onReplaceFavicon,
            onRemove: onRemoveFavicon,
            child: _BrandMediaImage(
              bytes: state.pendingFaviconBytes,
              url: state.faviconImageUrl,
              semanticLabel: 'Favicon preview',
            ),
          ),
          const SizedBox(height: 14),
          _BrandColorField(
            label: 'Primary Colour',
            helper: 'Used for buttons, highlights, and accents',
            controller: primaryColorController,
            readOnly: readOnly,
            fallback: _onlineStoreOrange,
            errorText: state.primaryColorError,
            onChanged: onPrimaryChanged,
          ),
          const SizedBox(height: 12),
          _BrandColorField(
            label: 'Secondary Colour',
            helper: 'Used for headers, text, and backgrounds',
            controller: secondaryColorController,
            readOnly: readOnly,
            fallback: _onlineStoreText,
            errorText: state.secondaryColorError,
            onChanged: onSecondaryChanged,
          ),
          if (readOnly)
            const _PermissionNotice(
              message:
                  '`tenant.online_store.branding.manage` is required to edit branding.',
            ),
        ],
      ),
    );
  }
}

class _BrandAssetPreview extends StatelessWidget {
  const _BrandAssetPreview({
    required this.label,
    required this.helper,
    required this.attached,
    required this.previewHeight,
    required this.readOnly,
    required this.onReplace,
    required this.onRemove,
    required this.child,
    this.compact = false,
  });

  final String label;
  final String helper;
  final bool attached;
  final double previewHeight;
  final bool readOnly;
  final VoidCallback onReplace;
  final VoidCallback? onRemove;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _onlineStoreText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          helper,
          style: const TextStyle(color: _onlineStoreMuted, fontSize: 11),
        ),
        const SizedBox(height: 9),
        if (compact)
          Row(
            children: [
              SizedBox(width: 82, child: _preview()),
              const SizedBox(width: 10),
              Expanded(child: _replaceButton()),
              if (onRemove != null) _removeButton(),
            ],
          )
        else ...[
          _preview(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _replaceButton()),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                _removeButton(),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _preview() {
    return Container(
      height: previewHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _onlineStoreBorder),
      ),
      child: attached
          ? child
          : const Icon(
              Icons.add_photo_alternate_outlined,
              color: _onlineStoreMuted,
              size: 30,
            ),
    );
  }

  Widget _replaceButton() {
    return OutlinedButton(
      onPressed: readOnly ? null : onReplace,
      style: OutlinedButton.styleFrom(
        foregroundColor: _onlineStoreText,
        minimumSize: const Size(0, 44),
        side: const BorderSide(color: _onlineStoreBorder),
      ),
      child: Text(attached ? 'Replace' : 'Upload'),
    );
  }

  Widget _removeButton() {
    return IconButton(
      tooltip: 'Remove $label',
      onPressed: readOnly ? null : onRemove,
      color: TenantAdminColors.danger,
      icon: const Icon(Icons.delete_outline, size: 20),
    );
  }
}

class _BrandColorField extends StatefulWidget {
  const _BrandColorField({
    required this.label,
    required this.helper,
    required this.controller,
    required this.readOnly,
    required this.fallback,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String helper;
  final TextEditingController controller;
  final bool readOnly;
  final Color fallback;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<_BrandColorField> createState() => _BrandColorFieldState();
}

class _BrandColorFieldState extends State<_BrandColorField> {
  Future<void> _selectColor() async {
    if (widget.readOnly) return;

    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => _BrandColorPickerDialog(
        selectedColor: _colorFromHex(
          widget.controller.text,
          widget.fallback,
        ),
      ),
    );
    if (selected == null || !mounted) return;

    final value = _hexFromColor(selected);
    setState(() => widget.controller.text = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        _colorFromHex(widget.controller.text, widget.fallback);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: _onlineStoreText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.helper,
          style: const TextStyle(color: _onlineStoreMuted, fontSize: 11),
        ),
        const SizedBox(height: 9),
        Semantics(
          button: !widget.readOnly,
          label: '${widget.label} colour selector',
          child: InkWell(
            key: ValueKey(
              'online-store-${widget.label.toLowerCase().replaceAll(' ', '-')}-picker',
            ),
            onTap: widget.readOnly ? null : _selectColor,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.errorText == null
                      ? _onlineStoreBorder
                      : TenantAdminColors.danger,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _onlineStoreBorder),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.readOnly ? 'Selected colour' : 'Select colour',
                      style: TextStyle(
                        color: widget.readOnly
                            ? _onlineStoreMuted
                            : _onlineStoreText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.readOnly
                        ? const Color(0xFFCBD5E1)
                        : _onlineStoreMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: TenantAdminColors.danger,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _BrandColorPickerDialog extends StatelessWidget {
  const _BrandColorPickerDialog({required this.selectedColor});

  final Color selectedColor;

  static const colors = <Color>[
    Color(0xFFFF6A00),
    Color(0xFFFF3D00),
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFC0CA33),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
    Color(0xFF6D4C41),
    Color(0xFF000000),
    Color(0xFF111827),
    Color(0xFF334155),
    Color(0xFF64748B),
    Color(0xFF94A3B8),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select colour'),
      content: SizedBox(
        width: 360,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: colors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final color = colors[index];
            final isSelected = color.toARGB32() == selectedColor.toARGB32();
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Colour option ${index + 1}',
              child: InkWell(
                onTap: () => Navigator.pop(context, color),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _onlineStoreOrange
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: color.computeLuminance() > .55
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _StorefrontPreviewCard extends StatelessWidget {
  const _StorefrontPreviewCard({
    required this.branding,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final OnlineStoreBranding branding;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final activeBanners = branding.banners
        .where((banner) => banner.status.toUpperCase() == 'ACTIVE')
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    OnlineStoreBanner? heroBanner;
    for (final banner in activeBanners) {
      if (banner.bannerType.toUpperCase() == 'HERO') {
        heroBanner = banner;
        break;
      }
    }
    final secondaryBanners = activeBanners
        .where((banner) => banner.bannerType.toUpperCase() != 'HERO')
        .take(2)
        .toList();
    return _OnlineStoreCard(
      title: 'Storefront Preview',
      padding: const EdgeInsets.all(16),
      titleSize: 20,
      headerSpacing: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'See how your branding and banners appear to customers.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _onlineStoreBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _StorefrontPreviewNav(
                    logoImageUrl: branding.logoImageUrl,
                    primaryColor: primaryColor,
                  ),
                  _StorefrontHeroPreview(
                    banner: heroBanner,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                  if (secondaryBanners.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          for (var index = 0;
                              index < secondaryBanners.length;
                              index++) ...[
                            if (index > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _PromoPreview(
                                banner: secondaryBanners[index],
                                icon: secondaryBanners[index]
                                            .bannerType
                                            .toUpperCase() ==
                                        'ANNOUNCEMENT'
                                    ? Icons.campaign_outlined
                                    : Icons.local_offer_outlined,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorefrontPreviewNav extends StatelessWidget {
  const _StorefrontPreviewNav({
    required this.logoImageUrl,
    required this.primaryColor,
  });

  final String? logoImageUrl;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 34,
            child: logoImageUrl?.trim().isNotEmpty == true
                ? Image.network(
                    logoImageUrl!,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (_, __, ___) => _storeName(),
                  )
                : _storeName(),
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width >= 900) ...[
            const Text('Shop', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 14),
            const Text('Categories', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 14),
            const Text('Collections', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 14),
            const Text('About Us', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 16),
          ],
          const Icon(Icons.search, size: 18),
          const SizedBox(width: 10),
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 10),
          const Icon(Icons.shopping_cart_outlined, size: 18),
        ],
      ),
    );
  }

  Widget _storeName() => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'YOUR STORE',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      );
}

class _StorefrontHeroPreview extends StatelessWidget {
  const _StorefrontHeroPreview({
    required this.banner,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final OnlineStoreBanner? banner;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = constraints.maxWidth >= 600
            ? 240.0
            : constraints.maxWidth >= 450
                ? 210.0
                : 190.0;
        final hasImage = banner?.imageUrl?.trim().isNotEmpty == true;
        return Container(
          height: heroHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFAFAFA), Color(0xFFFFE9DC)],
            ),
            border: Border.symmetric(
              horizontal: BorderSide(color: _onlineStoreBorder),
            ),
          ),
          child: Stack(
            children: [
              if (hasImage)
                Positioned.fill(
                  child: Image.network(
                    banner!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (hasImage)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: .72),
                          Colors.black.withValues(alpha: .18),
                          Colors.transparent,
                        ],
                        stops: const [0, .58, 1],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 28,
                top: 28,
                bottom: 24,
                width: (constraints.maxWidth * .56).clamp(190.0, 330.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner?.title.toUpperCase() ?? 'YOUR STOREFRONT BANNER',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasImage ? Colors.white : secondaryColor,
                        fontSize: constraints.maxWidth >= 520 ? 27 : 23,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      banner?.subtitle ??
                          'Add an active hero banner to introduce your storefront.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasImage
                            ? Colors.white.withValues(alpha: .92)
                            : secondaryColor,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        banner?.actionText ?? 'Learn More',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                top: (heroHeight - 26) / 2,
                child: const _CarouselArrow(icon: Icons.chevron_left),
              ),
              Positioned(
                right: 8,
                top: (heroHeight - 26) / 2,
                child: const _CarouselArrow(icon: Icons.chevron_right),
              ),
              Positioned(
                bottom: 9,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PreviewDot(color: primaryColor),
                    const _PreviewDot(color: Color(0xFFCBD5E1)),
                    const _PreviewDot(color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        shape: BoxShape.circle,
        border: Border.all(color: _onlineStoreBorder),
      ),
      child: Icon(icon, size: 18, color: _onlineStoreText),
    );
  }
}

class _PromoPreview extends StatelessWidget {
  const _PromoPreview({
    required this.banner,
    required this.icon,
    required this.color,
  });

  final OnlineStoreBanner banner;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl?.trim().isNotEmpty == true;
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              banner.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (hasImage)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .72),
                    Colors.black.withValues(alpha: .12),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      if (banner.actionText?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Text(
                          banner.actionText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!hasImage) Icon(icon, color: _onlineStoreOrange, size: 38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerEditorDialog extends ConsumerStatefulWidget {
  const _BannerEditorDialog({this.existing});

  final OnlineStoreBanner? existing;

  @override
  ConsumerState<_BannerEditorDialog> createState() =>
      _BannerEditorDialogState();
}

class _BannerEditorDialogState extends ConsumerState<_BannerEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _actionTextController;
  late final TextEditingController _actionUrlController;
  late String _bannerType;
  late String _status;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageMimeType;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final banner = widget.existing;
    _titleController = TextEditingController(text: banner?.title ?? '');
    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    _actionTextController =
        TextEditingController(text: banner?.actionText ?? '');
    _actionUrlController = TextEditingController(text: banner?.actionUrl ?? '');
    _bannerType = banner?.bannerType.toUpperCase() ?? 'HERO';
    _status = banner?.status.toUpperCase() ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _actionTextController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(onlineStoreBannerMutationProvider);
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Banner' : 'Edit Banner'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _bannerType,
                decoration: const InputDecoration(labelText: 'Banner Type'),
                items: const [
                  DropdownMenuItem(value: 'HERO', child: Text('Hero Banner')),
                  DropdownMenuItem(value: 'PROMO', child: Text('Promo Banner')),
                  DropdownMenuItem(
                    value: 'ANNOUNCEMENT',
                    child: Text('Announcement Banner'),
                  ),
                ],
                onChanged: mutation.isWorking
                    ? null
                    : (value) => setState(() => _bannerType = value ?? 'HERO'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _actionTextController,
                      decoration: const InputDecoration(labelText: 'CTA Text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _actionUrlController,
                      decoration: const InputDecoration(labelText: 'CTA URL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                ],
                onChanged: mutation.isWorking
                    ? null
                    : (value) => setState(() => _status = value ?? 'ACTIVE'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: mutation.isWorking ? null : _pickImage,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  _imageFileName ??
                      (widget.existing?.imageMediaAssetId == null
                          ? 'Choose image'
                          : 'Replace image'),
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _validationError!,
                  style: const TextStyle(color: TenantAdminColors.danger),
                ),
              ],
              if (mutation.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  mutation.errorMessage!,
                  style: const TextStyle(color: TenantAdminColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: mutation.isWorking ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: mutation.isWorking ? null : _save,
          child: Text(mutation.isWorking ? 'Saving...' : 'Save Banner'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageFileName = picked.name;
      _imageMimeType = picked.mimeType ?? _inferImageMimeType(picked.name);
      _validationError = null;
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _validationError = 'Title is required.');
      return;
    }
    final existing = widget.existing;
    final succeeded =
        await ref.read(onlineStoreBannerMutationProvider.notifier).saveBanner(
              existing: existing,
              bannerType: _bannerType,
              title: _titleController.text,
              subtitle: _subtitleController.text,
              actionText: _actionTextController.text,
              actionUrl: _actionUrlController.text,
              sortOrder: existing?.sortOrder ?? 0,
              status: _status,
              imageBytes: _imageBytes,
              imageFileName: _imageFileName,
              imageMimeType: _imageMimeType,
            );
    if (mounted && succeeded) Navigator.pop(context, true);
  }
}

class _BannerOrderDialog extends StatefulWidget {
  const _BannerOrderDialog({required this.banners});

  final List<OnlineStoreBanner> banners;

  @override
  State<_BannerOrderDialog> createState() => _BannerOrderDialogState();
}

class _BannerOrderDialogState extends State<_BannerOrderDialog> {
  late final List<OnlineStoreBanner> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = [...widget.banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Banner Order'),
      content: SizedBox(
        width: 480,
        height: 360,
        child: ReorderableListView.builder(
          itemCount: _ordered.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              _ordered.insert(newIndex, _ordered.removeAt(oldIndex));
            });
          },
          itemBuilder: (context, index) {
            final banner = _ordered[index];
            return ListTile(
              key: ValueKey(banner.id),
              leading: const Icon(Icons.drag_indicator),
              title: Text(_bannerTypeLabel(banner.bannerType)),
              subtitle: Text(banner.title),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ordered),
          child: const Text('Save Order'),
        ),
      ],
    );
  }
}

class _BannerManagerCard extends StatelessWidget {
  const _BannerManagerCard({
    required this.banners,
    required this.readOnly,
    required this.isWorking,
    required this.onAdd,
    required this.onManageOrder,
    required this.onAction,
  });

  final List<OnlineStoreBanner> banners;
  final bool readOnly;
  final bool isWorking;
  final VoidCallback onAdd;
  final VoidCallback onManageOrder;
  final Future<void> Function(OnlineStoreBanner banner, String action) onAction;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Banner Manager',
      padding: const EdgeInsets.all(16),
      titleSize: 18,
      headerSpacing: 6,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BannerActionButton(
            label: 'Add Banner',
            icon: Icons.add,
            compact: true,
            onPressed: readOnly || isWorking ? null : onAdd,
          ),
          const SizedBox(width: 8),
          _BannerActionButton(
            label: 'Manage Order',
            icon: Icons.sort,
            compact: true,
            onPressed: readOnly || isWorking || banners.length < 2
                ? null
                : onManageOrder,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your storefront banners and their display order.',
            style: TextStyle(color: _onlineStoreMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _onlineStoreBorder),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.view_carousel_outlined,
                    color: _onlineStoreOrange,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No storefront banners yet',
                    style: TextStyle(
                      color: _onlineStoreText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a hero, promotion, or announcement banner to customise your storefront.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _onlineStoreMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _BannerActionButton(
                    label: 'Add Banner',
                    icon: Icons.add,
                    onPressed: readOnly || isWorking ? null : onAdd,
                  ),
                ],
              ),
            )
          else
            ...banners.map(
              (banner) => _BannerRow(
                banner: banner,
                readOnly: readOnly,
                isWorking: isWorking,
                onAction: (action) => onAction(banner, action),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerActionButton extends StatelessWidget {
  const _BannerActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 15 : 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _onlineStoreText,
        side: const BorderSide(color: _onlineStoreBorder),
        minimumSize: Size(0, compact ? 36 : 40),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        textStyle: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.banner,
    required this.readOnly,
    required this.isWorking,
    required this.onAction,
  });

  final OnlineStoreBanner banner;
  final bool readOnly;
  final bool isWorking;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final isActive = banner.status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: _onlineStoreMuted, size: 20),
          const SizedBox(width: 8),
          Container(
            width: 64,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: banner.imageUrl == null
                ? const Icon(Icons.image_outlined, color: _onlineStoreMuted)
                : Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: _onlineStoreMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bannerTypeLabel(banner.bannerType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  banner.subtitle?.trim().isNotEmpty == true
                      ? '${banner.title} · ${banner.subtitle}'
                      : banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: _onlineStoreMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusChip(label: banner.status),
          PopupMenuButton<String>(
            tooltip: 'Banner actions',
            enabled: !readOnly && !isWorking,
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: isActive ? 'deactivate' : 'activate',
                child: Text(isActive ? 'Deactivate' : 'Activate'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionOutletRow extends StatelessWidget {
  const _CollectionOutletRow({required this.outlet});

  final OnlineStoreCollectionOutlet outlet;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.storefront_outlined,
      title: outlet.outletName,
      subtitle:
          '${outlet.outletStatus} • Lead ${outlet.preparationLeadMinutes} min • Window ${outlet.pickupWindowMinutes} min',
      trailing: _StatusChip(label: outlet.status),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.policy,
    required this.canManage,
    required this.onPublish,
    required this.onArchive,
  });

  final OnlineStorePolicy policy;
  final bool canManage;
  final VoidCallback onPublish;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.policy_outlined,
      title: policy.title,
      subtitle: '${policy.policyType} • ${policy.version}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(label: policy.status),
          if (canManage)
            PopupMenuButton<String>(
              tooltip: 'Policy actions',
              onSelected: (value) {
                if (value == 'publish') onPublish();
                if (value == 'archive') onArchive();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'publish', child: Text('Publish')),
                PopupMenuItem(value: 'archive', child: Text('Archive')),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductVisibilityRow extends StatelessWidget {
  const _ProductVisibilityRow({
    required this.product,
    required this.canManage,
    required this.onChanged,
  });

  final OnlineStoreCatalogProduct product;
  final bool canManage;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.inventory_2_outlined,
      title: product.productName,
      subtitle: product.variantName ?? product.status,
      trailing: Switch.adaptive(
        value: product.isVisible,
        activeThumbColor: _onlineStoreOrange,
        onChanged: canManage ? onChanged : null,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = _onlineStoreText,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _onlineStoreBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: _onlineStoreMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompactListRow extends StatelessWidget {
  const _CompactListRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _onlineStoreBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leading, color: _onlineStoreOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _onlineStoreMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.label,
    required this.mediaAssetId,
    required this.imageUrl,
    required this.readOnly,
    required this.onUpload,
    required this.onRemove,
  });

  final String label;
  final String? mediaAssetId;
  final String? imageUrl;
  final bool readOnly;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 84,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _onlineStoreBorder),
          ),
          child: imageUrl == null
              ? const Icon(Icons.image_outlined, color: _onlineStoreMuted)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl!, fit: BoxFit.cover),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _onlineStoreText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mediaAssetId == null
                    ? 'No media asset attached'
                    : 'Media asset $mediaAssetId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _onlineStoreMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: readOnly ? null : onUpload,
          style: TextButton.styleFrom(foregroundColor: TenantAdminColors.info),
          child: const Text('Change'),
        ),
        IconButton(
          tooltip: 'Remove $label',
          onPressed: readOnly ? null : onRemove,
          color: TenantAdminColors.danger,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.readOnly,
    required this.saving,
    required this.onSave,
    required this.permissionMessage,
  });

  final bool readOnly;
  final bool saving;
  final Future<void> Function() onSave;
  final String permissionMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly)
          _PermissionNotice(message: permissionMessage)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: _PrimaryButton(
              label: saving ? 'Saving...' : 'Save Changes',
              onPressed: saving ? null : onSave,
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _onlineStoreOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: _onlineStoreMuted,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          minimumSize: const Size(160, 52),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _onlineStoreText,
          side: const BorderSide(color: Color(0xFF94A3B8)),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          minimumSize: const Size(140, 52),
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TenantAdminColors.info.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: TenantAdminColors.info.withValues(alpha: .35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TenantAdminColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: TenantAdminColors.info,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStoreEmptyState extends StatelessWidget {
  const _OnlineStoreEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _onlineStoreBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _onlineStoreText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: _onlineStoreMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _OnlineStoreLoadingCard extends StatelessWidget {
  const _OnlineStoreLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _OnlineStoreCard(
      title: 'Loading Online Store data',
      child: SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _OnlineStoreErrorCard extends StatelessWidget {
  const _OnlineStoreErrorCard({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _OnlineStoreCard(
      title: 'Online Store data unavailable',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: TenantAdminColors.danger,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            _SecondaryButton(
              label: 'Retry',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }
}

List<OnlineStoreStep> _prioritizedOverviewSteps(
  List<OnlineStoreStep> steps,
) {
  final incomplete =
      steps.where((step) => !_isStepComplete(step)).toList(growable: false);
  final prioritized = <OnlineStoreStep>[];

  for (final stepNumber in const [7, 4, 8, 9]) {
    final step = _findOnlineStoreStep(incomplete, stepNumber);
    if (step != null) {
      prioritized.add(step);
    }
  }

  for (final step in incomplete) {
    if (!prioritized.contains(step)) {
      prioritized.add(step);
    }
  }

  return prioritized.take(4).toList(growable: false);
}

OnlineStoreStep? _findOnlineStoreStep(
  List<OnlineStoreStep> steps,
  int stepNumber,
) {
  for (final step in steps) {
    if (step.stepNumber == stepNumber) {
      return step;
    }
  }
  return null;
}

IconData _overviewActionIcon(int stepNumber) {
  return switch (stepNumber) {
    4 => Icons.public_outlined,
    7 => Icons.location_on_outlined,
    8 => Icons.policy_outlined,
    9 => Icons.rocket_launch_outlined,
    _ => Icons.settings_outlined,
  };
}

String _overviewActionTitle(OnlineStoreStep step) {
  return switch (step.stepNumber) {
    4 => 'Set Primary Domain',
    7 => 'Configure Click & Collect',
    8 => 'Publish Collection Policy',
    9 => 'Review & Publish',
    _ => step.label,
  };
}

String _overviewActionSubtitle(OnlineStoreStep step) {
  return switch (step.stepNumber) {
    4 => 'Choose the domain customers will see',
    7 => 'Set locations, availability and pickup rules',
    8 => 'Complete and publish your policy',
    9 => 'Review all settings and publish your store',
    _ => step.blockingReasons.isNotEmpty
        ? step.blockingReasons.first
        : 'Continue this setup step',
  };
}

String _display(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Not provided by backend';
  }
  return trimmed;
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _inferImageMimeType(String fileName) {
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return 'image/png';
}

Color _colorFromHex(String value, Color fallback) {
  final normalized = value.trim().replaceFirst('#', '');
  if (normalized.length != 6) {
    return fallback;
  }

  final parsed = int.tryParse('FF$normalized', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

String _hexFromColor(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _bannerDescription(String bannerType) {
  return switch (bannerType.toUpperCase()) {
    'HERO' => 'Main homepage hero banner',
    'PROMO' => 'Promotional banner module',
    'ANNOUNCEMENT' => 'Top announcement strip',
    _ => 'Storefront promotional content',
  };
}

String _bannerTypeLabel(String bannerType) {
  return switch (bannerType.trim().toUpperCase()) {
    'HERO' => 'Hero Banner',
    'PROMO' => 'Promo Banner',
    'ANNOUNCEMENT' => 'Announcement Banner',
    _ => bannerType.trim().isEmpty ? 'Banner' : bannerType.trim(),
  };
}

bool _isStepComplete(OnlineStoreStep? step) {
  final status = step?.status.toLowerCase() ?? '';
  return status.contains('complete') ||
      status.contains('published') ||
      status == 'done';
}

bool _isStepBlocked(OnlineStoreStep? step) {
  if (step == null) {
    return false;
  }
  final status = step.status.toLowerCase();
  return status.contains('block') ||
      status.contains('missing') ||
      step.blockingReasons.isNotEmpty;
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('complete') ||
      normalized.contains('enabled') ||
      normalized.contains('published') ||
      normalized.contains('active') ||
      normalized.contains('verified') ||
      normalized.contains('ready') ||
      normalized.contains('granted')) {
    return TenantAdminColors.success;
  }

  if (normalized.contains('block') ||
      normalized.contains('missing') ||
      normalized.contains('disabled') ||
      normalized.contains('failed') ||
      normalized.contains('inactive')) {
    return TenantAdminColors.danger;
  }

  if (normalized.contains('pending') ||
      normalized.contains('draft') ||
      normalized.contains('setup')) {
    return TenantAdminColors.warning;
  }

  return TenantAdminColors.info;
}

IconData _statusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('complete') ||
      normalized.contains('enabled') ||
      normalized.contains('published') ||
      normalized.contains('verified') ||
      normalized.contains('ready')) {
    return Icons.check_circle;
  }

  if (normalized.contains('block') ||
      normalized.contains('failed') ||
      normalized.contains('missing')) {
    return Icons.warning_amber_rounded;
  }

  return Icons.info_outline;
}

String _nextIncompleteRoute(OnlineStoreOverview overview) {
  for (final backendStep in overview.steps) {
    if (!_isStepComplete(backendStep)) {
      final matchingStep = OnlineStoreSetupScreen.steps.firstWhere(
        (step) => step.number == backendStep.stepNumber,
        orElse: () => OnlineStoreSetupScreen.steps.last,
      );
      return matchingStep.route;
    }
  }

  return '/tenant-admin/online-store/review';
}

Future<void> _mutate(BuildContext context, Future<void> action) async {
  try {
    await action;
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Online Store changes saved.')),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Online Store action failed: $error')),
    );
  }
}

Future<T?> _mutateWithResult<T>(BuildContext context, Future<T?> action) async {
  try {
    final result = await action;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Online Store changes saved.')),
      );
    }
    return result;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Online Store action failed: $error')),
      );
    }
    return null;
  }
}
