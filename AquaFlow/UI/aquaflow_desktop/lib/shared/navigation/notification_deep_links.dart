import 'package:flutter/widgets.dart';

/// Opens the record a system notification is about. Throws (any
/// [Exception], typically the role service's own exception type) when the
/// record can't be loaded - e.g. a 404 because it no longer exists or is no
/// longer visible to the caller; the caller turns that into a SnackBar.
/// Should complete once the target is shown, not when it is popped again.
typedef NotificationDeepLinkHandler =
    Future<void> Function(BuildContext context, int id);

/// Registry mapping a notification's `relatedEntityType` (a backend
/// `RelatedEntityTypes` value: `Invoice`, `FaultReport`,
/// `WaterMeterRequest`, `SupportTicket`) to the screen that opens it.
///
/// `lib/shared/` must not import role code, so - like
/// `AccountScreen.extraEntries` - each project's own shell registers the
/// handlers it can serve (`register` in `initState`, `unregister` in
/// `dispose`), and shared screens (`NotificationDetailScreen`, via
/// `PushMessageHandler` too) only ask [canOpen]/[open]. A type no handler is
/// registered for simply has no "Otvori" button.
///
/// A [ChangeNotifier] so a screen built before the shell registered (a cold
/// start from a tapped push) picks the handlers up once they arrive.
class NotificationDeepLinks extends ChangeNotifier {
  NotificationDeepLinks();

  /// The app-wide registry the shells register into.
  static final NotificationDeepLinks instance = NotificationDeepLinks();

  final Map<String, NotificationDeepLinkHandler> _handlers = {};

  void register(String type, NotificationDeepLinkHandler handler) {
    _handlers[_key(type)] = handler;
    notifyListeners();
  }

  void registerAll(Map<String, NotificationDeepLinkHandler> handlers) {
    handlers.forEach((type, handler) => _handlers[_key(type)] = handler);
    notifyListeners();
  }

  /// Removes the given handlers, but only where they are still the ones
  /// registered (a newer shell may already have replaced them).
  void unregisterAll(Map<String, NotificationDeepLinkHandler> handlers) {
    var changed = false;
    handlers.forEach((type, handler) {
      final key = _key(type);
      if (identical(_handlers[key], handler)) {
        _handlers.remove(key);
        changed = true;
      }
    });
    if (changed) notifyListeners();
  }

  bool canOpen(String? type, int? id) =>
      type != null && id != null && _handlers.containsKey(_key(type));

  /// Opens [id] of [type]; null when no handler is registered for [type].
  Future<void>? open(BuildContext context, String type, int id) =>
      _handlers[_key(type)]?.call(context, id);

  static String _key(String type) => type.trim().toLowerCase();
}
