import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the application's [ThemeMode] preference on-device.
///
/// Implements `PRD.md` §3.8 (A-42) and `TASKS.md` Task 5A-2:
/// - Three options: [ThemeMode.light], [ThemeMode.dark], [ThemeMode.system]
/// - Default is **[ThemeMode.light]** (not system — deliberate product decision)
/// - Persists selection to [SharedPreferences] under key `'app_theme_mode'`
/// - Loaded before the first frame renders to avoid theme flash/flicker
/// - Instantly notifies listeners so [MaterialApp] updates immediately
class ThemeController extends ChangeNotifier {
  static const String prefKey = 'app_theme_mode';

  static final ThemeController instance = ThemeController._();

  ThemeController._();

  ThemeMode _themeMode = ThemeMode.light;
  SharedPreferences? _prefs;

  /// Current active [ThemeMode].
  ThemeMode get themeMode => _themeMode;

  /// Initializes the controller by reading the stored preference from [SharedPreferences].
  ///
  /// If no preference has been saved yet (first launch), defaults to [ThemeMode.light].
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final savedMode = _prefs?.getString(prefKey);
    if (savedMode != null) {
      _themeMode = themeModeFromString(savedMode);
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Sets the active [ThemeMode], notifies listeners, and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(prefKey, themeModeToString(mode));
    } catch (_) {
      // Gracefully ignore storage exceptions (e.g. unit test environments)
    }
  }

  /// Toggles between light and dark modes based on current active brightness.
  Future<void> toggleTheme(Brightness platformBrightness) async {
    final isCurrentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    await setThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Parses string representation to [ThemeMode]. Defaults to [ThemeMode.light].
  static ThemeMode themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  /// Converts [ThemeMode] to string representation for persistence.
  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  /// Creates a scoped instance for testing.
  @visibleForTesting
  factory ThemeController.scoped({
    ThemeMode initialMode = ThemeMode.light,
    SharedPreferences? prefs,
  }) {
    final controller = ThemeController._();
    controller._themeMode = initialMode;
    controller._prefs = prefs;
    return controller;
  }

  /// Resets the singleton instance state (useful between tests).
  @visibleForTesting
  void resetForTesting({
    ThemeMode mode = ThemeMode.light,
    SharedPreferences? prefs,
  }) {
    _themeMode = mode;
    _prefs = prefs;
    notifyListeners();
  }
}
