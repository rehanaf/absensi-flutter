import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorPreference {
  dynamic,
  monochrome,
  blue,
  red,
  green,
  purple,
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  AppColorPreference _colorPreference = AppColorPreference.monochrome;

  ThemeMode get themeMode => _themeMode;
  AppColorPreference get colorPreference => _colorPreference;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final modeIndex = prefs.getInt('theme_mode');
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    final colorIndex = prefs.getInt('color_preference');
    if (colorIndex != null && colorIndex >= 0 && colorIndex < AppColorPreference.values.length) {
      _colorPreference = AppColorPreference.values[colorIndex];
    } else {
      // Default to monochrome
      _colorPreference = AppColorPreference.monochrome;
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setColorPreference(AppColorPreference pref) async {
    _colorPreference = pref;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_preference', pref.index);
  }

  void cycleTheme() {
    if (_themeMode == ThemeMode.system) {
      setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.system);
    }
  }
}
