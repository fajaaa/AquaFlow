// NotificationBadgeProvider polling: new-notification detection by the
// newest unread row (not the count), stop on logout/background, and no
// overlapping probes. Runs under testWidgets so the poll timer uses the
// fake clock and app lifecycle changes go through the real binding.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaflow_collector/shared/providers/notification_badge_provider.dart';

import 'support/notification_fakes.dart';

const _interval = Duration(seconds: 1);

void main() {
  late FakeNotificationService service;
  late NotificationBadgeProvider provider;

  setUp(() {
    service = FakeNotificationService();
    provider = NotificationBadgeProvider(
      service: service,
      pollInterval: _interval,
    );
  });

  tearDown(() => provider.dispose());

  /// testWidgets that always stops polling (and returns the app to the
  /// foreground) before the binding checks for leftover timers.
  void pollingTest(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        provider.stop();
        if (tester.binding.lifecycleState != AppLifecycleState.resumed) {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
      }
    });
  }

  /// Starts polling and lets the baseline probe finish.
  Future<void> startWithBaseline(WidgetTester tester) async {
    provider.start();
    await tester.pump();
  }

  pollingTest(
    'a new newest row bumps inboxVersion even when the unread count is unchanged',
    (tester) async {
      service.summary = unreadSummary(3, inboxItem(10));
      await startWithBaseline(tester);
      expect(provider.inboxVersion, 0, reason: 'baseline is not "new"');
      expect(provider.unreadCount, 3);

      // One read, one new arrival: still 3 unread, but a newer newest row.
      service.summary = unreadSummary(3, inboxItem(11));
      await tester.pump(_interval);

      expect(service.summaryCalls, 2);
      expect(provider.inboxVersion, 1);
      expect(provider.unreadCount, 3);
    },
  );

  pollingTest('the same newest row does not fire the signal', (tester) async {
    service.summary = unreadSummary(2, inboxItem(10));
    await startWithBaseline(tester);

    await tester.pump(_interval);
    await tester.pump(_interval);

    expect(service.summaryCalls, 3);
    expect(provider.inboxVersion, 0);
  });

  pollingTest('reading the newest row is not a new notification', (
    tester,
  ) async {
    service.summary = unreadSummary(2, inboxItem(11));
    await startWithBaseline(tester);

    // Row 11 read: the newest unread row is now the older row 10.
    service.summary = unreadSummary(1, inboxItem(10));
    await tester.pump(_interval);

    expect(provider.inboxVersion, 0);
    expect(provider.unreadCount, 1);
  });

  pollingTest('the first arrival into an empty inbox fires the signal', (
    tester,
  ) async {
    service.summary = unreadSummary(0, null);
    await startWithBaseline(tester);

    service.summary = unreadSummary(1, inboxItem(1));
    await tester.pump(_interval);

    expect(provider.inboxVersion, 1);
  });

  pollingTest('stop (logout) cancels polling and clears the session state', (
    tester,
  ) async {
    service.summary = unreadSummary(4, inboxItem(10));
    await startWithBaseline(tester);
    expect(provider.isPolling, isTrue);

    provider.stop();
    final callsAtStop = service.summaryCalls;
    await tester.pump(_interval * 5);

    expect(provider.isPolling, isFalse);
    expect(service.summaryCalls, callsAtStop);
    expect(provider.unreadCount, 0);
    expect(provider.inboxVersion, 0);

    // A trigger after logout (e.g. a late push) is ignored too.
    await provider.refresh();
    expect(service.summaryCalls, callsAtStop);
  });

  pollingTest('a probe still in flight at logout is discarded', (tester) async {
    service.summary = unreadSummary(0, null);
    await startWithBaseline(tester);

    service.summaryGate = Completer<void>();
    service.summary = unreadSummary(7, inboxItem(1));
    unawaited(provider.refresh());
    await tester.pump();
    provider.stop();
    service.summaryGate!.complete();
    await tester.pump();

    expect(provider.unreadCount, 0);
    expect(provider.inboxVersion, 0);
  });

  pollingTest('pauses in the background and refreshes at once on resume', (
    tester,
  ) async {
    service.summary = unreadSummary(1, inboxItem(10));
    await startWithBaseline(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final callsAtPause = service.summaryCalls;
    await tester.pump(_interval * 5);

    expect(provider.isPolling, isFalse);
    expect(service.summaryCalls, callsAtPause);

    service.summary = unreadSummary(2, inboxItem(11));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(service.summaryCalls, callsAtPause + 1, reason: 'immediate probe');
    expect(provider.isPolling, isTrue);
    expect(provider.inboxVersion, 1);
  });

  pollingTest('inactive also pauses polling', (tester) async {
    await startWithBaseline(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final callsAtInactive = service.summaryCalls;
    await tester.pump(_interval * 3);

    expect(provider.isPolling, isFalse);
    expect(service.summaryCalls, callsAtInactive);
  });

  pollingTest('parallel refreshes never overlap and collapse into one rerun', (
    tester,
  ) async {
    service.summaryGate = Completer<void>();
    service.summary = unreadSummary(1, inboxItem(10));
    provider.start(); // baseline probe, held at the gate
    await tester.pump();

    // A poll tick and two pushes arrive while the baseline is in flight.
    final pending = [provider.refresh(), provider.refresh()];
    await tester.pump(_interval);
    expect(service.summaryCalls, 1);

    service.summaryGate!.complete();
    service.summaryGate = null;
    await Future.wait(pending);
    await tester.pump();

    expect(service.maxConcurrentSummaries, 1);
    expect(service.summaryCalls, 2, reason: 'one rerun for all the triggers');
  });

  pollingTest('markSeen hides the badge until something newer arrives', (
    tester,
  ) async {
    service.summary = unreadSummary(3, inboxItem(10));
    await startWithBaseline(tester);
    expect(provider.unreadCount, 3);

    provider.markSeen();
    expect(provider.unreadCount, 0);

    // Polling the same state doesn't bring the badge back...
    await tester.pump(_interval);
    expect(provider.unreadCount, 0);

    // ...a new arrival does, with the real unread count.
    service.summary = unreadSummary(4, inboxItem(11));
    await tester.pump(_interval);
    expect(provider.unreadCount, 4);
  });

  pollingTest('markSeen before the baseline probe treats it as seen', (
    tester,
  ) async {
    service.summaryGate = Completer<void>();
    service.summary = unreadSummary(3, inboxItem(10));
    provider.start();
    provider.markSeen(); // the inbox list loaded first
    service.summaryGate!.complete();
    service.summaryGate = null;
    await tester.pump();

    expect(provider.unreadCount, 0);
  });
}
