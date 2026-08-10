import 'package:flutter/material.dart';

/// Holds the app's current [ThemeMode]. Defaults to light; `main.dart` wires
/// `MaterialApp.themeMode` to [themeMode] so toggling here swaps the whole
/// app's theme immediately.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggle() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
