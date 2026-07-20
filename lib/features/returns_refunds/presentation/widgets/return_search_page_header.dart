import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';

class ReturnSearchPageHeader extends ConsumerWidget {
  const ReturnSearchPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tillState = ref.watch(tillProvider);
    final session = tillState.session;
    final isOpen = tillState.hasOpenSession;
    final tillLabel = (session?.tillName.trim().isNotEmpty ?? false)
        ? session!.tillName.trim()
        : (session?.tillCode.trim().isNotEmpty ?? false)
            ? session!.tillCode.trim()
            : 'Till';
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        final title = _TitleBlock(compact: compact);
        final status = _HeaderStatus(
          tillLabel: tillLabel,
          isOpen: isOpen,
          now: now,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: TenantAdminSpacing.lg),
              Align(alignment: Alignment.centerLeft, child: status),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: TenantAdminSpacing.xl),
            status,
          ],
        );
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final numberSize = compact ? 36.0 : 42.0;
    final titleSize = compact ? 30.0 : 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '01',
              style: TextStyle(
                color: TenantAdminColors.primary,
                fontSize: numberSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Container(
              width: 1,
              height: compact ? 34 : 40,
              color: TenantAdminColors.border,
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Flexible(
              child: Text(
                'SEARCH SALE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Text(
          'Find the original sale before starting the return or exchange process.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({
    required this.tillLabel,
    required this.isOpen,
    required this.now,
  });

  final String tillLabel;
  final bool isOpen;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          padding:
              const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: isOpen
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
                size: 28,
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tillLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOpen ? 'Open' : 'Closed',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isOpen
                              ? TenantAdminColors.success
                              : TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 34),
        SizedBox(
          width: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                _formatDate(now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}
