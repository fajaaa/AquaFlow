import 'package:flutter/material.dart';

/// Holds the app's current [Locale]. Defaults to Bosnian; `main.dart` wires
/// `MaterialApp.locale` to [locale] so changing it here swaps the whole app's
/// language immediately.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('bs');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  /// Convenience for callers that only have the backend's `'bs'`/`'en'`
  /// language code (`UserPreference.Language`), not a [Locale] object.
  void setLanguageCode(String code) => setLocale(Locale(code));
}
