import 'package:flutter/material.dart';

class MuraThemeController extends ChangeNotifier {
  // Singleton pattern so we can access it anywhere
  static final MuraThemeController _instance = MuraThemeController._internal();
  factory MuraThemeController() => _instance;
  MuraThemeController._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // This function will be called by your InterfaceView cards
  void toggleTheme(String themeName) {
    if (themeName == "CYBER_ONYX") {
      _isDarkMode = true;
    } else {
      _isDarkMode = false;
    }
    notifyListeners(); // This tells the app to rebuild
  }
}
