import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the currently selected outlet ID for the Tenant Admin Outlets screen.
///
/// The ID is a GUID string returned by the backend. It can be null when no
/// outlet is selected (e.g., on initial load or after clearing the selection).
final selectedOutletIdProvider = StateProvider<String?>((ref) => null);
