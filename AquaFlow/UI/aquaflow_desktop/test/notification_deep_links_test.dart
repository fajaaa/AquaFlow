// NotificationDeepLinks registry and the "Otvori" button it drives on
// NotificationDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaflow_desktop/shared/navigation/notification_deep_links.dart';
import 'package:aquaflow_desktop/shared/providers/notification_badge_provider.dart';
import 'package:aquaflow_desktop/shared/screens/notification_detail_screen.dart';

import 'support/notification_fakes.dart';

const _openButton = ValueKey('notification-open-related');

void main() {
  group('NotificationDeepLinks', () {
    test(
      'a registered type opens with the right id, case-insensitively',
      () async {
        final links = NotificationDeepLinks();
        int? openedId;
        links.register('Invoice', (context, id) async => openedId = id);

        expect(links.canOpen('invoice', 7), isTrue);
        expect(links.canOpen('Invoice', null), isFalse);
        expect(links.canOpen('SupportTicket', 7), isFalse);
        expect(links.canOpen(null, 7), isFalse);

        final context = _FakeContext();
        expect(links.open(context, 'SupportTicket', 7), isNull);
        await links.open(context, 'INVOICE', 7);
        expect(openedId, 7);
      },
    );

    test('unregisterAll only removes the handlers it registered', () {
      final links = NotificationDeepLinks();
      Future<void> first(BuildContext context, int id) async {}
      Future<void> second(BuildContext context, int id) async {}

      links.registerAll({'FaultReport': first});
      links.registerAll({'FaultReport': second}); // a newer shell took over
      links.unregisterAll({'FaultReport': first});
      expect(links.canOpen('FaultReport', 1), isTrue);

      links.unregisterAll({'FaultReport': second});
      expect(links.canOpen('FaultReport', 1), isFalse);
    });
  });

  group('NotificationDetailScreen "Otvori"', () {
    late NotificationBadgeProvider badge;
    late NotificationDeepLinks links;

    setUp(() {
      badge = NotificationBadgeProvider(service: FakeNotificationService());
      links = NotificationDeepLinks();
    });

    tearDown(() => badge.dispose());

    Future<void> pumpDetail(
      WidgetTester tester, {
      String? type,
      int? id,
      bool openRelatedOnStart = false,
    }) async {
      await tester.pumpWidget(
        notificationTestApp(
          badge: badge,
          child: NotificationDetailScreen(
            // Already read, so the screen doesn't send a read receipt.
            item: inboxItem(
              1,
              read: true,
              relatedEntityType: type,
              relatedEntityId: id,
            ),
            service: FakeNotificationService(),
            deepLinks: links,
            openRelatedOnStart: openRelatedOnStart,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('known type: the button calls the handler with the id', (
      tester,
    ) async {
      final opened = <int>[];
      links.register('Invoice', (context, id) async => opened.add(id));

      await pumpDetail(tester, type: 'Invoice', id: 42);
      expect(find.byKey(_openButton), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.byKey(_openButton));
      await tester.pump();

      expect(opened, [42]);
    });

    testWidgets('unknown type: no button', (tester) async {
      links.register('Invoice', (context, id) async {});

      await pumpDetail(tester, type: 'Payment', id: 42);

      expect(find.byKey(_openButton), findsNothing);
    });

    testWidgets('no related record: no button', (tester) async {
      links.register('Invoice', (context, id) async {});

      await pumpDetail(tester);

      expect(find.byKey(_openButton), findsNothing);
    });

    testWidgets('a record that is gone shows a SnackBar instead of crashing', (
      tester,
    ) async {
      links.register(
        'FaultReport',
        (context, id) async => throw Exception('404'),
      );

      await pumpDetail(tester, type: 'FaultReport', id: 9);
      await tester.tap(find.byKey(_openButton));
      await tester.pump();

      expect(
        find.text(
          "The related item couldn't be opened. It may no longer be available.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('a push tap opens the record once the shell registers it', (
      tester,
    ) async {
      final opened = <int>[];

      // Cold start: the detail screen is up before any handler exists.
      await pumpDetail(
        tester,
        type: 'SupportTicket',
        id: 3,
        openRelatedOnStart: true,
      );
      expect(find.byKey(_openButton), findsNothing);
      expect(opened, isEmpty);

      links.register('SupportTicket', (context, id) async => opened.add(id));
      await tester.pump();

      expect(opened, [3]);
      expect(find.byKey(_openButton), findsOneWidget);
    });
  });
}

/// [NotificationDeepLinks.open] only hands the context to the handler.
class _FakeContext extends Fake implements BuildContext {}
