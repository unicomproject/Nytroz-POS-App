class PosHomeAction {
  const PosHomeAction({
    required this.key,
    required this.label,
    required this.description,
    required this.iconKey,
    this.buttonLabel = '',
    this.isFutureFeature = false,
    this.isEnabled = true,
    this.routeExists = true,
    this.targetRoute,
    this.onTapActionKey,
    this.featureKey,
    this.permissionKey,
    this.metricValue,
    this.metricLabel,
  }) : assert(
          targetRoute != null || onTapActionKey != null,
          'An action must define a target route or an onTap action key.',
        );

  final String key;
  final String label;
  final String description;
  final String iconKey;
  final String buttonLabel;
  final bool isFutureFeature;
  final bool isEnabled;
  final bool routeExists;
  final String? targetRoute;
  final String? onTapActionKey;
  final String? featureKey;
  final String? permissionKey;

  // Mock/view-only dashboard display values.
  final String? metricValue;
  final String? metricLabel;
}
