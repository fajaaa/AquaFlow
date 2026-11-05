import 'package:flutter/material.dart';

import 'package:aquaflow_desktop/l10n/app_localizations.dart';

/// Holds the app's current [Locale]. Defaults to Bosnian; `main.dart` wires
/// `MaterialApp.locale` to [locale] so changing it here swaps the whole app's
/// language immediately.
class LocaleProvider extends ChangeNotifier {
  static const Locale _fallback = Locale('bs');

  Locale _locale = _fallback;

  Locale get locale => _locale;

  /// Accepts only locales listed in [AppLocalizations.supportedLocales]
  /// ('bs'/'de'/'en'); anything else falls back to Bosnian.
  void setLocale(Locale locale) {
    final supported = AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
    final next = supported ? Locale(locale.languageCode) : _fallback;
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
  }

  /// Convenience for callers that only have the backend's `'bs'`/`'de'`/`'en'`
  /// language code (`UserPreference.Language`), not a [Locale] object.
  void setLanguageCode(String code) => setLocale(Locale(code));
}
