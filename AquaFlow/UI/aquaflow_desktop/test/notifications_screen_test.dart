// NotificationsScreen reacting to NotificationBadgeProvider's
// new-notification signal: silent reload on page 1, a banner (and no
// reload) on a later page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaflow_desktop/shared/models/notification_page.dart';
import 'package:aquaflow_desktop/shared/models/user_notification_item.dart';
import 'package:aquaflow_desktop/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_desktop/shared/screens/notifications_screen.dart';

import 'support/notification_fakes.dart';

const _bannerKey = ValueKey('notifications-new-banner');

void main() {
  late FakeNotificationService badgeService;
  late NotificationBadgeProvider badge;
  late FakeNotificationService screenService;

  setUp(() {
    badgeService = FakeNotificationService();
    // Long interval: the tests fire the signal through refresh() themselves.
    badge = NotificationBadgeProvider(
      service: badgeService,
      pollInterval: const Duration(hours: 1),
    );
    screenService = FakeNotificationService();
  });

  tearDown(() => badge.dispose());

  /// Mounts the screen with polling started and the baseline probe done.
  Future<void> pumpInbox(WidgetTester tester) async {
    badgeService.summary = unreadSummary(1, inboxItem(5));
    badge.start();
    await tester.pumpWidget(
      notificationTestApp(
        badge: badge,
        child: NotificationsScreen(service: screenService),
      ),
    );
    await tester.pump();
  }

  /// A new notification (id 100) arrives and the provider picks it up.
  Future<void> deliverNewNotification(WidgetTester tester) async {
    badgeService.summary = unreadSummary(2, inboxItem(100));
    await badge.refresh();
    await tester.pump();
  }

  NotificationPage pageOf(List<UserNotificationItem> items, int total) =>
      NotificationPage(items: items, totalCount: total);

  testWidgets('on page 1 the signal reloads the list silently', (tester) async {
    screenService.pages = (_) => pageOf([inboxItem(5)], 1);
    await pumpInbox(tester);
    expect(screenService.fetchMinePages, [1]);
    expect(find.text('Notification 5'), findsOneWidget);

    screenService.pages = (_) =>
        pageOf([inboxItem(100, title: 'Fresh one'), inboxItem(5)], 2);
    screenService.fetchMineGate = Completer<void>();
    await deliverNewNotification(tester);

    // Reload in flight: silent - the list stays, no loader of either kind.
    expect(screenService.fetchMinePages, [1, 1]);
    expect(find.text('Notification 5'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    screenService.fetchMineGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Fresh one'), findsOneWidget);
    expect(find.byKey(_bannerKey), findsNothing);

    badge.stop();
  });

  testWidgets('on page 2 the signal shows the banner instead of reloading', (
    tester,
  ) async {
    screenService.pages = (page) => page == 1
        ? pageOf([for (var i = 30; i > 20; i--) inboxItem(i)], 25)
        : pageOf([inboxItem(7, title: 'Older one')], 25);
    await pumpInbox(tester);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pump();
    expect(screenService.fetchMinePages, [1, 2]);
    expect(find.text('Older one'), findsOneWidget);

    await deliverNewNotification(tester);

    expect(screenService.fetchMinePages, [1, 2], reason: 'user not moved');
    expect(find.text('Older one'), findsOneWidget);
    expect(find.byKey(_bannerKey), findsOneWidget);
    expect(find.text('You have new notifications'), findsOneWidget);

    // "Refresh" on the banner jumps back to page 1 and clears it.
    await tester.tap(
      find.descendant(
        of: find.byKey(_bannerKey),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pump();

    expect(screenService.fetchMinePages, [1, 2, 1]);
    expect(find.byKey(_bannerKey), findsNothing);

    badge.stop();
  });
}
