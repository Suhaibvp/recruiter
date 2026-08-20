import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // TODO: Load from SharedPreferences if persistent
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    // TODO: Save to SharedPreferences
  }

  void setLight() => setTheme(ThemeMode.light);
  void setDark() => setTheme(ThemeMode.dark);
  void setSystem() => setTheme(ThemeMode.system);
}
