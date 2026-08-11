import 'dart:async';

/// Generic connectivity wake-up for the durable outbox.
///
/// Call [reportOnline] / [reportOffline] from network edges (API success,
/// network failures, app resume). After connectivity becomes stably online for
/// [stableOnlineWindow], registered listeners run once (single-flight friendly
/// with [OfflineOutbox.sync]).
class OfflineConnectivityMonitor {
  OfflineConnectivityMonitor({
    this.stableOnlineWindow = const Duration(seconds: 2),
  });

  final Duration stableOnlineWindow;

  final List<Future<void> Function()> _listeners = [];
  Timer? _stableTimer;
  bool _isOnline = true;
  bool _wakeInFlight = false;
  int _generation = 0;

  bool get isOnline => _isOnline;

  void addListener(Future<void> Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Future<void> Function() listener) {
    _listeners.remove(listener);
  }

  void reportOffline() {
    _isOnline = false;
    _stableTimer?.cancel();
    _stableTimer = null;
    _generation++;
  }

  void reportOnline() {
    if (_isOnline && _stableTimer == null && !_wakeInFlight) {
      // Already considered stably online — do not re-fire on every request.
      return;
    }
    _isOnline = true;
    final generation = ++_generation;
    _stableTimer?.cancel();
    _stableTimer = Timer(stableOnlineWindow, () {
      _stableTimer = null;
      if (generation != _generation || !_isOnline) return;
      unawaited(_wakeListeners());
    });
  }

  /// Forces a wake attempt after the stable window, used by tests and
  /// explicit reconnect hooks.
  void requestSyncWake({Duration? delay}) {
    _isOnline = true;
    final generation = ++_generation;
    _stableTimer?.cancel();
    _stableTimer = Timer(delay ?? stableOnlineWindow, () {
      _stableTimer = null;
      if (generation != _generation || !_isOnline) return;
      unawaited(_wakeListeners());
    });
  }

  Future<void> _wakeListeners() async {
    if (_wakeInFlight || _listeners.isEmpty) return;
    _wakeInFlight = true;
    try {
      for (final listener in List<Future<void> Function()>.from(_listeners)) {
        await listener();
      }
    } finally {
      _wakeInFlight = false;
    }
  }

  void dispose() {
    _stableTimer?.cancel();
    _listeners.clear();
  }
}
