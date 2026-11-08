import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/unread_notification_summary.dart';
import '../models/user_notification_item.dart';
import '../services/notification_exception.dart';
import '../services/notification_service.dart';

/// Backs the unread badge on the "Obavijesti" tab/sidebar item and tells an
/// open inbox (`NotificationsScreen`) when a new notification has arrived.
///
/// While [start]ed (the role shell calls it on mount, i.e. once the user is
/// signed in, and [stop] on dispose, i.e. on logout) it polls
/// `NotificationService.fetchUnreadSummary` every [pollInterval], but only
/// while the app is in the foreground: `paused`/`hidden`/`inactive` cancel
/// the timer, `resumed` refreshes once immediately and restarts it. A
/// foreground FCM push calls [refresh] directly so the same signal fires
/// without waiting for the next tick.
///
/// A new notification is detected from the newest unread row (by
/// `CreatedAt`, then id), never from the count alone - the count stays the
/// same when the user read one and a new one arrived in the same interval.
/// Each detection bumps [inboxVersion], which screens compare against the
/// value they last handled.
///
/// [unreadCount] is the server's unread count, except that [markSeen] (the
/// inbox list just loaded) hides it until something newer than what was on
/// screen arrives, so polling doesn't bring the badge back while the user
/// is looking at the very notifications it counts.
class NotificationBadgeProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationBadgeProvider({
    NotificationService? service,
    this.pollInterval = const Duration(seconds: 30),
  }) : _service = service ?? NotificationService();

  final NotificationService _service;

  /// Time between two background probes; injectable so tests can run a
  /// short interval.
  final Duration pollInterval;

  int _unreadCount = 0;
  int _inboxVersion = 0;

  /// Newest unread row ever observed (a high-water mark - reading rows
  /// never lowers it, so a later arrival is always compared against the
  /// newest thing already known).
  _InboxMarker? _newest;

  /// [_newest] as of the last [markSeen]; the badge shows only once
  /// something newer than this arrives.
  _InboxMarker? _seen;
  bool _everSeen = false;

  /// [markSeen] came before the first probe of this session finished, so
  /// that probe's result is what the user has already seen.
  bool _seenBeforeBaseline = false;

  bool _baselineReady = false;
  bool _started = false;
  bool _foreground = true;
  bool _disposed = false;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _rerunRequested = false;

  /// Bumped by every [stop], so a probe that outlives its session is dropped.
  int _session = 0;

  int get unreadCount => _hasUnseen ? _unreadCount : 0;

  /// Bumped once per detected new notification. Starts at 0 for every
  /// session; the first probe after [start] only establishes the baseline.
  int get inboxVersion => _inboxVersion;

  /// Whether the poll timer is currently running.
  @visibleForTesting
  bool get isPolling => _timer?.isActive ?? false;

  bool get _hasUnseen {
    if (!_everSeen) return true;
    final newest = _newest;
    if (newest == null) return false;
    final seen = _seen;
    return seen == null || newest.isNewerThan(seen);
  }

  /// Begins polling for the signed-in user. Idempotent.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    if (_foreground) {
      _startTimer();
      unawaited(refresh());
    }
  }

  /// Stops polling and forgets the session's state (count, markers,
  /// version), so the next user starts from a clean baseline. Deliberately
  /// does not notify: it runs from a shell's `dispose`, when the listening
  /// widgets are being torn down too, and the next [start] notifies anyway.
  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    // Orphans any probe still in flight (see [_probeOnce]).
    _session++;
    _inFlight = null;
    _rerunRequested = false;
    _unreadCount = 0;
    _inboxVersion = 0;
    _newest = null;
    _seen = null;
    _everSeen = false;
    _seenBeforeBaseline = false;
    _baselineReady = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_foreground) return;
        _foreground = true;
        _startTimer();
        unawaited(refresh());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _cancelTimer();
    }
  }

  /// Probes the backend once. Never overlaps with itself: a call while a
  /// probe is in flight returns that probe's future and schedules exactly one
  /// more probe right after it, so a trigger that arrives mid-request (an FCM
  /// push for a row the running request may have missed) is never lost.
  /// No-op while not [start]ed.
  Future<void> refresh() {
    if (!_started) return Future<void>.value();
    final inFlight = _inFlight;
    if (inFlight != null) {
      _rerunRequested = true;
      return inFlight;
    }
    return _inFlight = _runProbes();
  }

  Future<void> _runProbes() async {
    final session = _session;
    try {
      do {
        _rerunRequested = false;
        await _probeOnce(session);
      } while (_rerunRequested && session == _session && !_disposed);
    } finally {
      if (session == _session) _inFlight = null;
    }
  }

  Future<void> _probeOnce(int session) async {
    final UnreadNotificationSummary summary;
    try {
      summary = await _service.fetchUnreadSummary();
    } on NotificationException {
      // Best-effort: keep the last known count/markers on a transient error
      // (no SnackBar - this runs in the background every few seconds).
      return;
    }
    // Logged out (or out and back in) while the request was in flight - the
    // answer belongs to a session that no longer exists.
    if (session != _session || _disposed) return;

    final before = (unreadCount, _inboxVersion);
    final latest = _InboxMarker.of(summary.latest);
    final previous = _newest;
    final isNew =
        _baselineReady &&
        latest != null &&
        (previous == null || latest.isNewerThan(previous));
    if (latest != null && (previous == null || latest.isNewerThan(previous))) {
      _newest = latest;
    }
    if (!_baselineReady) {
      _baselineReady = true;
      if (_seenBeforeBaseline) {
        _seenBeforeBaseline = false;
        _seen = _newest;
      }
    }
    _unreadCount = summary.unreadCount;
    if (isNew) _inboxVersion++;
    // Most ticks change nothing - don't rebuild the shell every interval.
    if ((unreadCount, _inboxVersion) != before) notifyListeners();
  }

  /// Called once a single notification has been persisted as read (see
  /// `NotificationDetailScreen`), so the badge reflects it immediately
  /// without waiting for the next probe.
  void decrement() {
    if (_unreadCount <= 0) return;
    _unreadCount--;
    notifyListeners();
  }

  /// Called once `NotificationsScreen` has loaded its list, i.e. the user has
  /// just seen their inbox: hides the badge until something newer arrives.
  void markSeen() {
    final wasVisible = unreadCount > 0;
    _everSeen = true;
    _seen = _newest;
    _seenBeforeBaseline = !_baselineReady;
    if (wasVisible) notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _cancelTimer();
    _service.dispose();
    super.dispose();
  }
}

/// Position of one inbox row in the list's newest-first order.
class _InboxMarker {
  const _InboxMarker(this.createdAt, this.id);

  final DateTime? createdAt;
  final int id;

  static _InboxMarker? of(UserNotificationItem? item) {
    if (item == null) return null;
    return _InboxMarker(item.createdAt, item.id);
  }

  bool isNewerThan(_InboxMarker other) {
    final mine = createdAt;
    final theirs = other.createdAt;
    if (mine != null && theirs != null && mine != theirs) {
      return mine.isAfter(theirs);
    }
    return id > other.id;
  }
}
