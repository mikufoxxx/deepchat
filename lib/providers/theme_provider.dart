import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _followSystem = true;
  Color _themeColor = Colors.blue;
  
  bool get isDarkMode => _isDarkMode;
  bool get followSystem => _followSystem;
  Color get themeColor => _themeColor;

  ThemeProvider() {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _followSystem = prefs.getBool('followSystem') ?? true;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeColor = Color(prefs.getInt('themeColor') ?? Colors.blue.value);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFollowSystem(bool value) async {
    _followSystem = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('followSystem', value);
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
    notifyListeners();
  }
} 