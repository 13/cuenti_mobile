/// Remembers, for a short while, that the server could not be reached.
///
/// Without this every request made offline found out for itself, and paid
/// a full connection timeout to do it -- so every screen opened with the
/// server down sat on a spinner before it was allowed to show the figures
/// already on the device. After one such failure, requests are answered
/// straight away for [initialWindow]: from cache where there is a copy,
/// with the same offline failure otherwise.
///
/// When the window runs out the next request is let through to the
/// network, alone, as a probe; everything asked meanwhile is still answered
/// at once. The probe getting any answer at all closes the breaker. Failing,
/// it reopens it for twice as long, up to [maxWindow] -- a server that is
/// down for the evening is not asked every fifteen seconds.
///
/// Only a failure to connect opens it. A slow answer, an error status or a
/// certificate this install does not trust are all a server that is there.
class Reachability {
  Reachability({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const initialWindow = Duration(seconds: 15);
  static const maxWindow = Duration(minutes: 2);

  final DateTime Function() _clock;

  /// How long a probe may go unanswered before another is let through. A
  /// probe that never reports back -- cancelled, or lost to a bug -- must
  /// not leave every request answered from cache for good.
  static const probeTimeout = Duration(seconds: 45);

  DateTime? _openUntil;
  Duration _window = initialWindow;
  DateTime? _probeStartedAt;

  /// Whether the last word on the server was that it could not be reached,
  /// and the window that buys has not run out.
  bool get isOpen {
    final until = _openUntil;
    return until != null && _clock().isBefore(until);
  }

  /// Whether a request may go to the network: the breaker is closed, or its
  /// window is over and no other request is already finding out.
  ///
  /// A true answer while the breaker has tripped makes the caller the probe,
  /// and it must report back through [recordReachable] or [recordOffline].
  bool admit() {
    if (_openUntil == null) return true;
    if (isOpen) return false;
    final probe = _probeStartedAt;
    final now = _clock();
    if (probe != null && now.difference(probe) < probeTimeout) return false;
    _probeStartedAt = now;
    return true;
  }

  /// The server could not be connected to.
  void recordOffline() {
    if (_probeStartedAt != null) {
      // The probe failed: still down, so wait longer before asking again.
      final doubled = _window * 2;
      _window = doubled > maxWindow ? maxWindow : doubled;
    } else if (isOpen) {
      // Already known. A request that was in flight when the breaker
      // tripped must not stretch the window it is already inside.
      return;
    }
    _openUntil = _clock().add(_window);
    _probeStartedAt = null;
  }

  /// A request admitted by [admit] ended with no word either way --
  /// cancelled, say. Lets the next one probe instead.
  void release() => _probeStartedAt = null;

  /// The server answered something, which is all reachable means.
  void recordReachable() => reset();

  /// Forgets any failure: the next request goes to the network. For a
  /// person asking for fresh figures, a different server, or a different
  /// account, none of which the last failure says anything about.
  void reset() {
    _openUntil = null;
    _window = initialWindow;
    _probeStartedAt = null;
  }
}
