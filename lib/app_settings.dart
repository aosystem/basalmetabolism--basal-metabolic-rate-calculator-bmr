import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeChoice { system, light, dark }

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'valueTheme';
  static const _localeKey = 'valueLocale';
  static const _heightKey = 'valueHeight';
  static const _weightKey = 'valueWeight';
  static const _ageKey = 'valueAge';
  static const _genderKey = 'valueGender';
  static const _showBackgroundImageKey = 'valueShowBackgroundImage';

  late final SharedPreferences _prefs;
  bool _isReady = false;
  ThemeChoice _themeChoice = ThemeChoice.system;
  Locale? _locale;
  bool _showBackgroundImage = true;

  ThemeChoice get themeChoice => _themeChoice;
  Locale? get locale => _locale;
  bool get showBackgroundImage => _showBackgroundImage;
  bool get isReady => _isReady;

  ThemeMode get themeMode {
    switch (_themeChoice) {
      case ThemeChoice.light:
        return ThemeMode.light;
      case ThemeChoice.dark:
        return ThemeMode.dark;
      case ThemeChoice.system:
        return ThemeMode.system;
    }
  }

  SharedPreferences get prefs {
    if (!_isReady) {
      throw StateError(
        'AppSettings.load must complete before accessing prefs.',
      );
    }
    return _prefs;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _themeChoice = _decodeThemeChoice(_prefs.getString(_themeKey));
    final storedLocale = _prefs.getString(_localeKey) ?? '';
    _locale = storedLocale.isEmpty ? null : Locale(storedLocale);
    _showBackgroundImage = _prefs.getBool(_showBackgroundImageKey) ?? true;
    _isReady = true;
  }

  ThemeChoice _decodeThemeChoice(String? value) {
    switch (value) {
      case '0':
      case 'light':
        return ThemeChoice.light;
      case '1':
      case 'dark':
        return ThemeChoice.dark;
      case '2':
      case 'system':
        return ThemeChoice.system;
    }
    return ThemeChoice.system;
  }

  String _encodeThemeChoice(ThemeChoice choice) {
    switch (choice) {
      case ThemeChoice.light:
        return 'light';
      case ThemeChoice.dark:
        return 'dark';
      case ThemeChoice.system:
        return 'system';
    }
  }

  Future<void> updateTheme(ThemeChoice choice) async {
    if (_themeChoice == choice) {
      return;
    }
    _themeChoice = choice;
    notifyListeners();
    await _prefs.setString(_themeKey, _encodeThemeChoice(choice));
  }

  Future<void> updateLocale(String? languageCode) async {
    final normalized = languageCode?.trim() ?? '';
    final newLocale = normalized.isEmpty ? null : Locale(normalized);
    final changed =
        !(_locale == null && newLocale == null) &&
        _locale?.languageCode != newLocale?.languageCode;
    if (changed) {
      _locale = newLocale;
      notifyListeners();
    }
    if (newLocale == null) {
      await _prefs.remove(_localeKey);
    } else {
      await _prefs.setString(_localeKey, newLocale.languageCode);
    }
  }

  Future<void> updateShowBackgroundImage(bool value) async {
    if (_showBackgroundImage == value) {
      return;
    }
    _showBackgroundImage = value;
    notifyListeners();
    await _prefs.setBool(_showBackgroundImageKey, value);
  }

  Future<void> saveUserInputs({
    required String height,
    required String weight,
    required String age,
    required int gender,
  }) async {
    final futures = <Future<bool>>[
      _prefs.setString(_heightKey, height),
      _prefs.setString(_weightKey, weight),
      _prefs.setString(_ageKey, age),
      _prefs.setString(_genderKey, gender.toString()),
    ];
    await Future.wait(futures);
  }
}
