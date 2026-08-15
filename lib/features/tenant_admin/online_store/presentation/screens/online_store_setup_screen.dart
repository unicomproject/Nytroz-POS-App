import 'package:flutter/material.dart';
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
      subtitle: 'Manage your online store integration and view setup progress.',
      route: '/tenant-admin/online-store',
    ),
    _OnlineStoreStepConfig(
      number: 2,
      label: 'Activation',
      title: 'Activation & Access',
      subtitle: 'Enable the online store and verify access readiness.',
      route: '/tenant-admin/online-store/activation',
    ),
    _OnlineStoreStepConfig(
      number: 3,
      label: 'Identity',
      title: 'Store Identity',
      subtitle: 'Provide the basic identity details for your online store.',
      route: '/tenant-admin/online-store/identity',
    ),
    _OnlineStoreStepConfig(
      number: 4,
      label: 'Domain',
      title: 'Storefront URL & Domain',
      subtitle: 'Choose your storefront URL and review custom domains.',
      route: '/tenant-admin/online-store/domain',
    ),
    _OnlineStoreStepConfig(
      number: 5,
      label: 'Branding',
      title: 'Branding & Appearance',
      subtitle: 'Upload brand assets, set colours, and manage banners.',
      route: '/tenant-admin/online-store/branding',
    ),
    _OnlineStoreStepConfig(
      number: 6,
      label: 'Support',
      title: 'Contact & Support',
      subtitle:
          'Add customer support contact details and business information.',
      route: '/tenant-admin/online-store/support',
    ),
    _OnlineStoreStepConfig(
      number: 7,
      label: 'Click & Collect',
      title: 'Click & Collect Configuration',
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

            return ColoredBox(
              color: TenantAdminColors.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: TenantAdminShadows.card,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isNarrow ? 18 : 28,
                            isNarrow ? 18 : 26,
                            isNarrow ? 18 : 28,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OnlineStoreHeader(
                                activeStep: activeStep,
                              ),
                              const SizedBox(height: 26),
                              _OnlineStoreStepper(
                                currentStep: activeStep,
                                overview: overviewState.asData?.value,
                              ),
                              const SizedBox(height: 28),
                              _OnlineStoreStepBody(
                                stepNumber: activeStep.number,
                                access: access,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _OnlineStoreBottomActions(
                        activeStep: activeStep,
                        overview: overviewState.asData?.value,
                        access: access,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
  const _OnlineStoreHeader({required this.activeStep});

  final _OnlineStoreStepConfig activeStep;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width <
        TenantAdminBreakpoints.tabletLandscape;

    final codeChip = Semantics(
      label: 'Online store journey code EC-TA-UJ-02',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: _onlineStoreOrange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'EC-TA-UJ-02',
          style: TextStyle(
            color: _onlineStoreOrange,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: .4,
          ),
        ),
      ),
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeStep.title.toUpperCase(),
          style: TextStyle(
            color: _onlineStoreText,
            fontWeight: FontWeight.w900,
            fontSize: isNarrow ? 22 : 28,
            letterSpacing: .2,
          ),
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
    final stepCount = Text(
      '${activeStep.number}/9',
      semanticsLabel: 'Step ${activeStep.number} of 9',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 30,
        fontWeight: FontWeight.w900,
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              codeChip,
              const Spacer(),
              stepCount,
            ],
          ),
          const SizedBox(height: 12),
          titleBlock,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        codeChip,
        const SizedBox(width: 18),
        Expanded(child: titleBlock),
        const SizedBox(width: 18),
        stepCount,
      ],
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 980;
            final children = [
              _OnlineStoreCard(
                title: 'Store Status',
                child: Column(
                  children: [
                    _InfoRow('Store status', overview.storeStatus),
                    _InfoRow('Channel status', overview.channelStatus),
                    _InfoRow('Visibility', overview.visibility),
                    _InfoRow('Store slug', overview.storeSlug),
                    _InfoRow('Hosted URL', overview.hostedUrl),
                    _InfoRow(
                      'Setup enabled',
                      overview.setupEnabled ? 'Enabled' : 'Disabled',
                    ),
                  ],
                ),
              ),
              _OnlineStoreCard(
                title: 'Take Your Store Online',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: _onlineStoreOrange,
                      size: 96,
                      semanticLabel: 'Online storefront',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      overview.storeStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _onlineStoreText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview.readiness.canPublish
                          ? 'Backend readiness allows publishing.'
                          : 'Backend readiness has blocking items.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _onlineStoreMuted,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrimaryButton(
                      label: overview.readiness.canPublish
                          ? 'Review & Publish'
                          : 'Continue Setup',
                      onPressed: () => context.go(
                        overview.readiness.canPublish
                            ? '/tenant-admin/online-store/review'
                            : _nextIncompleteRoute(overview),
                      ),
                    ),
                  ],
                ),
              ),
              _OnlineStoreCard(
                title: 'Access & Readiness',
                child: overview.readiness.steps.isEmpty
                    ? const _OnlineStoreEmptyState(
                        title: 'No readiness rows',
                        message: 'The backend returned no readiness preview.',
                      )
                    : Column(
                        children: overview.readiness.steps
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
              _OnlineStoreCard(
                title: 'Setup Progress',
                child: Row(
                  children: [
                    _ProgressRing(percent: overview.setupProgressPercent),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        '${overview.completedSteps} of ${overview.totalSteps} steps completed',
                        style: const TextStyle(
                          color: _onlineStoreText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];

            if (isNarrow) {
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: child,
                      ),
                    )
                    .toList(growable: false),
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: 18),
                    Expanded(child: children[1]),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[2]),
                    const SizedBox(width: 18),
                    Expanded(child: children[3]),
                  ],
                ),
              ],
            );
          },
        );
      },
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
        return Column(
          children: [
            _OnlineStoreCard(
              title: 'Enable Online Store',
              trailing: Switch(
                value: activation.setupEnabled,
                activeThumbColor: _onlineStoreOrange,
                onChanged: canManage && !mutationState.isLoading
                    ? (value) async {
                        await _mutate(
                          context,
                          ref
                              .read(onlineStoreMutationControllerProvider
                                  .notifier)
                              .updateActivation(value),
                        );
                      }
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable the setup flag from the backend. Public visibility remains backend-controlled.',
                    style: TextStyle(color: _onlineStoreMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  _InfoRow('Current status', activation.storeStatus),
                  _InfoRow('Channel status', activation.channelStatus),
                  _InfoRow('Visibility', activation.visibility),
                  if (!canManage)
                    const _PermissionNotice(
                      message:
                          'Read-only view. `tenant.online_store.manage` is required to change activation.',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _OnlineStoreCard(
              title: 'Access & Entitlements',
              child: activation.entitlements.isEmpty
                  ? const _OnlineStoreEmptyState(
                      title: 'No entitlements returned',
                      message: 'The backend did not return entitlement rows.',
                    )
                  : Column(
                      children: activation.entitlements
                          .map(
                            (entitlement) => _ReadinessRow(
                              label: entitlement.featureCode,
                              status: entitlement.status,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _OnlineStoreIdentityStep extends ConsumerWidget {
  const _OnlineStoreIdentityStep({required this.access});

  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityState = ref.watch(onlineStoreIdentityProvider);
    return _AsyncSection<OnlineStoreIdentity>(
      state: identityState,
      onRetry: () => ref.invalidate(onlineStoreIdentityProvider),
      builder: (identity) => _OnlineStoreIdentityForm(
        identity: identity,
        readOnly: !access.canManageOnlineStore(),
      ),
    );
  }
}

class _OnlineStoreIdentityForm extends ConsumerStatefulWidget {
  const _OnlineStoreIdentityForm({
    required this.identity,
    required this.readOnly,
  });

  final OnlineStoreIdentity identity;
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
  late final TextEditingController _phoneController;
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
    _phoneController =
        TextEditingController(text: widget.identity.storePhone ?? '');
    _taglineController =
        TextEditingController(text: widget.identity.supportTagline ?? '');
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);

    return _OnlineStoreCard(
      title: 'Store Identity',
      child: Column(
        children: [
          _ResponsiveTwoColumn(
            left: Column(
              children: [
                _TextInput(
                  label: 'Store Name',
                  controller: _storeNameController,
                  readOnly: widget.readOnly,
                  required: true,
                ),
                _TextInput(
                  label: 'Business Display Name',
                  controller: _displayNameController,
                  readOnly: widget.readOnly,
                  required: true,
                ),
                _TextInput(
                  label: 'Store Description',
                  controller: _descriptionController,
                  readOnly: widget.readOnly,
                  required: false,
                  maxLines: 3,
                ),
                _TextInput(
                  label: 'Support Tagline',
                  controller: _taglineController,
                  readOnly: widget.readOnly,
                  required: false,
                ),
              ],
            ),
            right: Column(
              children: [
                _TextInput(
                  label: 'Store Email',
                  controller: _emailController,
                  readOnly: widget.readOnly,
                  required: false,
                ),
                _TextInput(
                  label: 'Store Phone',
                  controller: _phoneController,
                  readOnly: widget.readOnly,
                  required: false,
                ),
                _ReadOnlyField(
                  label: 'Default Timezone',
                  value: widget.identity.timezone,
                ),
                _ReadOnlyField(
                  label: 'Store Currency',
                  value: widget.identity.currencyCode,
                ),
              ],
            ),
          ),
          _FormFooter(
            readOnly: widget.readOnly,
            saving: mutationState.isLoading,
            onSave: () async {
              await _mutate(
                context,
                ref
                    .read(onlineStoreMutationControllerProvider.notifier)
                    .updateIdentity(
                      storeName: _storeNameController.text.trim(),
                      businessDisplayName: _displayNameController.text.trim(),
                      storeDescription: _nullable(_descriptionController.text),
                      storeEmail: _nullable(_emailController.text),
                      storePhone: _nullable(_phoneController.text),
                      supportTagline: _nullable(_taglineController.text),
                    ),
              );
            },
            permissionMessage:
                '`tenant.online_store.manage` is required to edit identity.',
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
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    return Column(
      children: [
        _ResponsiveTwoColumn(
          left: _OnlineStoreCard(
            title: 'Store URL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TextInput(
                  label: 'Store Slug',
                  controller: _slugController,
                  readOnly: !widget.canManageUrl,
                  required: true,
                ),
                _ReadOnlyField(
                  label: 'Hosted URL',
                  value: widget.urlDomain.hostedUrl,
                ),
                _FormFooter(
                  readOnly: !widget.canManageUrl,
                  saving: mutationState.isLoading,
                  onSave: () async {
                    await _mutate(
                      context,
                      ref
                          .read(onlineStoreMutationControllerProvider.notifier)
                          .updateUrl(_slugController.text.trim()),
                    );
                  },
                  permissionMessage:
                      '`tenant.online_store.manage` is required to update the storefront URL.',
                ),
              ],
            ),
          ),
          right: _OnlineStoreCard(
            title: 'Custom Domains',
            child: widget.urlDomain.domains.isEmpty
                ? const _OnlineStoreEmptyState(
                    title: 'No custom domains',
                    message: 'No custom domains were returned by the backend.',
                  )
                : Column(
                    children: widget.urlDomain.domains
                        .map(
                          (domain) => _DomainRow(
                            domain: domain,
                            canManage: widget.canManageDomains,
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ),
      ],
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
  }

  @override
  void dispose() {
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    return _ResponsiveTwoColumn(
      left: _OnlineStoreCard(
        title: 'Brand Assets',
        child: Column(
          children: [
            _AssetRow(
              label: 'Store Logo',
              mediaAssetId: widget.branding.logoMediaAssetId,
              imageUrl: null,
              readOnly: widget.readOnly,
              onUpload: () => _pickAndAttachMedia(
                purpose: 'logo',
                currentLogoMediaAssetId: widget.branding.logoMediaAssetId,
                currentFaviconMediaAssetId: widget.branding.faviconMediaAssetId,
                attachLogo: true,
              ),
              onRemove: widget.branding.logoMediaAssetId == null
                  ? null
                  : () => _removeMedia(widget.branding.logoMediaAssetId!),
            ),
            const Divider(height: 28),
            _AssetRow(
              label: 'Favicon',
              mediaAssetId: widget.branding.faviconMediaAssetId,
              imageUrl: null,
              readOnly: widget.readOnly,
              onUpload: () => _pickAndAttachMedia(
                purpose: 'favicon',
                currentLogoMediaAssetId: widget.branding.logoMediaAssetId,
                currentFaviconMediaAssetId: widget.branding.faviconMediaAssetId,
                attachLogo: false,
              ),
              onRemove: widget.branding.faviconMediaAssetId == null
                  ? null
                  : () => _removeMedia(widget.branding.faviconMediaAssetId!),
            ),
            const Divider(height: 28),
            _TextInput(
              label: 'Primary Color',
              controller: _primaryColorController,
              readOnly: widget.readOnly,
              required: true,
            ),
            _TextInput(
              label: 'Secondary Color',
              controller: _secondaryColorController,
              readOnly: widget.readOnly,
              required: true,
            ),
            _FormFooter(
              readOnly: widget.readOnly,
              saving: mutationState.isLoading,
              onSave: () async {
                await _mutate(
                  context,
                  ref
                      .read(onlineStoreMutationControllerProvider.notifier)
                      .updateBranding(
                        logoMediaAssetId: widget.branding.logoMediaAssetId,
                        faviconMediaAssetId:
                            widget.branding.faviconMediaAssetId,
                        primaryColor: _primaryColorController.text.trim(),
                        secondaryColor: _secondaryColorController.text.trim(),
                      ),
                );
              },
              permissionMessage:
                  '`tenant.online_store.branding.manage` is required to edit branding.',
            ),
          ],
        ),
      ),
      right: _OnlineStoreCard(
        title: 'Homepage Banners',
        child: widget.branding.banners.isEmpty
            ? const _OnlineStoreEmptyState(
                title: 'No banners returned',
                message: 'Create banners only through approved backend routes.',
              )
            : Column(
                children: widget.branding.banners
                    .map((banner) => _BannerRow(banner: banner))
                    .toList(growable: false),
              ),
      ),
    );
  }

  Future<void> _pickAndAttachMedia({
    required String purpose,
    required String? currentLogoMediaAssetId,
    required String? currentFaviconMediaAssetId,
    required bool attachLogo,
  }) async {
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
    final controller = ref.read(onlineStoreMutationControllerProvider.notifier);
    final uploaded = await _mutateWithResult(
      context,
      controller.uploadMedia(
        purpose: purpose,
        bytes: bytes,
        fileName: pickedImage.name,
        mimeType: mimeType,
      ),
    );

    if (uploaded == null || !mounted) {
      return;
    }

    await _mutate(
      context,
      controller.updateBranding(
        logoMediaAssetId:
            attachLogo ? uploaded.mediaAssetId : currentLogoMediaAssetId,
        faviconMediaAssetId:
            attachLogo ? currentFaviconMediaAssetId : uploaded.mediaAssetId,
        primaryColor: _primaryColorController.text.trim(),
        secondaryColor: _secondaryColorController.text.trim(),
      ),
    );
  }

  Future<void> _removeMedia(String mediaAssetId) async {
    await _mutate(
      context,
      ref
          .read(onlineStoreMutationControllerProvider.notifier)
          .deleteMedia(mediaAssetId),
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
      builder: (support) => _OnlineStoreSupportForm(
        support: support,
        readOnly: !access.canManageOnlineStoreSupport(),
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
  late bool _contactUsEnabled;

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
    _contactUsEnabled = widget.support.contactUsEnabled;
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
    final mutationState = ref.watch(onlineStoreMutationControllerProvider);
    return _ResponsiveThreeColumn(
      left: _OnlineStoreCard(
        title: 'Support Contact',
        child: Column(
          children: [
            _TextInput(
              label: 'Support Email',
              controller: _emailController,
              readOnly: widget.readOnly,
              required: false,
            ),
            _TextInput(
              label: 'Support Phone',
              controller: _phoneController,
              readOnly: widget.readOnly,
              required: false,
            ),
            _TextInput(
              label: 'WhatsApp Contact',
              controller: _whatsappController,
              readOnly: widget.readOnly,
              required: false,
            ),
            _TextInput(
              label: 'Live Chat / Help Link',
              controller: _helpUrlController,
              readOnly: widget.readOnly,
              required: false,
            ),
          ],
        ),
      ),
      middle: _OnlineStoreCard(
        title: 'Business Information',
        child: Column(
          children: [
            _TextInput(
              label: 'Business Address',
              controller: _addressController,
              readOnly: widget.readOnly,
              required: false,
              maxLines: 3,
            ),
            _TextInput(
              label: 'Support Hours',
              controller: _hoursController,
              readOnly: widget.readOnly,
              required: false,
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                value: _contactUsEnabled,
                activeThumbColor: _onlineStoreOrange,
                contentPadding: EdgeInsets.zero,
                title: const Text('Contact Us Page'),
                subtitle: const Text('Backend controls storefront visibility.'),
                onChanged: widget.readOnly
                    ? null
                    : (value) => setState(() => _contactUsEnabled = value),
              ),
            ),
            _FormFooter(
              readOnly: widget.readOnly,
              saving: mutationState.isLoading,
              onSave: () async {
                await _mutate(
                  context,
                  ref
                      .read(onlineStoreMutationControllerProvider.notifier)
                      .updateSupport(
                        email: _nullable(_emailController.text),
                        phone: _nullable(_phoneController.text),
                        whatsapp: _nullable(_whatsappController.text),
                        helpUrl: _nullable(_helpUrlController.text),
                        contactUsEnabled: _contactUsEnabled,
                        supportHours: _nullable(_hoursController.text),
                        businessAddress: _nullable(_addressController.text),
                      ),
                );
              },
              permissionMessage:
                  '`tenant.online_store.support.manage` is required to edit support.',
            ),
          ],
        ),
      ),
      right: _OnlineStoreCard(
        title: 'Support Preview',
        child: Column(
          children: [
            _InfoRow('Email', widget.support.email),
            _InfoRow('Phone', widget.support.phone),
            _InfoRow('WhatsApp', widget.support.whatsapp),
            _InfoRow('Help URL', widget.support.helpUrl),
            _InfoRow('Hours', widget.support.supportHours),
            _InfoRow('Address', widget.support.businessAddress),
          ],
        ),
      ),
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
    return _AsyncSection<OnlineStoreProductsPoliciesData>(
      state: state,
      onRetry: () => ref.invalidate(onlineStoreProductsPoliciesProvider),
      builder: (data) {
        return _ResponsiveTwoColumn(
          left: _OnlineStoreCard(
            title: 'Online Products',
            child: Column(
              children: [
                _InfoRow('Total products', '${data.summary.totalProducts}'),
                _InfoRow('Visible online', '${data.summary.visibleOnline}'),
                _InfoRow('Not visible', '${data.summary.notVisible}'),
                _InfoRow('Orderable', '${data.summary.orderable}'),
                _InfoRow(
                  'Low stock products',
                  '${data.summary.lowStockProducts}',
                ),
                _InfoRow(
                  'Out of stock products',
                  '${data.summary.outOfStockProducts}',
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
        return _ResponsiveThreeColumn(
          left: _OnlineStoreCard(
            title: 'Setup Summary',
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
          middle: _OnlineStoreCard(
            title: 'Store Readiness',
            child: Column(
              children: [
                if (readiness.blockingReasons.isEmpty)
                  const _PermissionNotice(
                    icon: Icons.check_circle,
                    color: TenantAdminColors.success,
                    message:
                        'The backend reports no blocking readiness reasons.',
                  )
                else
                  ...readiness.blockingReasons.map(
                    (reason) => _PermissionNotice(
                      icon: Icons.warning_amber_rounded,
                      color: TenantAdminColors.warning,
                      message: reason,
                    ),
                  ),
              ],
            ),
          ),
          right: _OnlineStoreCard(
            title: 'Publish Store',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  readiness.canPublish
                      ? 'Backend readiness allows publishing.'
                      : 'Resolve backend readiness blockers before publishing.',
                  style: const TextStyle(
                    color: _onlineStoreMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                  label: mutationState.isLoading
                      ? 'Publishing...'
                      : 'Publish Store',
                  onPressed: canPublish &&
                          readiness.canPublish &&
                          !mutationState.isLoading
                      ? () async {
                          await _mutate(
                            context,
                            ref
                                .read(onlineStoreMutationControllerProvider
                                    .notifier)
                                .publish(),
                          );
                        }
                      : null,
                ),
                if (!canPublish)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: _PermissionNotice(
                      message:
                          '`tenant.online_store.publish` is required to publish.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnlineStoreBottomActions extends StatelessWidget {
  const _OnlineStoreBottomActions({
    required this.activeStep,
    required this.overview,
    required this.access,
  });

  final _OnlineStoreStepConfig activeStep;
  final OnlineStoreOverview? overview;
  final TenantAdminAccessChecker access;

  @override
  Widget build(BuildContext context) {
    final previousStep = activeStep.number > 1
        ? OnlineStoreSetupScreen.steps[activeStep.number - 2]
        : null;
    final nextStep = activeStep.number < OnlineStoreSetupScreen.steps.length
        ? OnlineStoreSetupScreen.steps[activeStep.number]
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border(top: BorderSide(color: _onlineStoreBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _SecondaryButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onPressed: previousStep == null
                  ? null
                  : () => context.go(previousStep.route),
            ),
            const Spacer(),
            if (nextStep != null)
              _PrimaryButton(
                label: 'Save & Continue',
                icon: Icons.arrow_forward,
                onPressed: () => context.go(nextStep.route),
              )
            else
              _PrimaryButton(
                label: 'Review Complete',
                onPressed: () => context.go('/tenant-admin/online-store'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.state,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const _OnlineStoreLoadingCard(),
      error: (error, stackTrace) => _OnlineStoreErrorCard(
        message: error.toString(),
        onRetry: onRetry,
      ),
      data: builder,
    );
  }
}

class _OnlineStoreCard extends StatelessWidget {
  const _OnlineStoreCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                  style: const TextStyle(
                    color: _onlineStoreText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
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
  });

  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final bool required;
  final int maxLines;

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
            ),
          ),
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
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return Semantics(
      label: 'Status $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
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

class _DomainRow extends StatelessWidget {
  const _DomainRow({
    required this.domain,
    required this.canManage,
  });

  final OnlineStoreDomain domain;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.language,
      title: domain.domainName,
      subtitle: [
        domain.domainType,
        if (domain.isPrimary) 'Primary',
        domain.sslStatus,
      ].join(' • '),
      trailing: _StatusChip(label: domain.verificationStatus),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.banner});

  final OnlineStoreBanner banner;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.image_outlined,
      title: banner.title,
      subtitle: _display(banner.subtitle ?? banner.actionText),
      trailing: _StatusChip(label: banner.status),
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
  });

  final OnlineStorePolicy policy;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return _CompactListRow(
      leading: Icons.policy_outlined,
      title: policy.title,
      subtitle: '${policy.policyType} • ${policy.version}',
      trailing: _StatusChip(label: policy.status),
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
          child: const Text('Change'),
        ),
        IconButton(
          tooltip: 'Remove $label',
          onPressed: readOnly ? null : onRemove,
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
    this.icon = Icons.info_outline,
    this.color = TenantAdminColors.info,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
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
