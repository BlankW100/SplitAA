import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _colorKey = 'seed_color';

  ThemeMode _mode = ThemeMode.system;
  Color _seedColor = const Color(0xFF009688); // teal

  ThemeMode get themeMode => _mode;
  Color get seedColor => _seedColor;

  static const presets = <_ColorPreset>[
    _ColorPreset('Teal', Color(0xFF009688)),
    _ColorPreset('Blue', Color(0xFF1565C0)),
    _ColorPreset('Indigo', Color(0xFF3949AB)),
    _ColorPreset('Purple', Color(0xFF7B1FA2)),
    _ColorPreset('Pink', Color(0xFFAD1457)),
    _ColorPreset('Orange', Color(0xFFE65100)),
    _ColorPreset('Green', Color(0xFF2E7D32)),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_modeKey) ?? 0;
    final colorValue = prefs.getInt(_colorKey);
    _mode = ThemeMode.values[modeIndex.clamp(0, 2)];
    if (colorValue != null) _seedColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    if (_seedColor == color) return;
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
  }
}

class _ColorPreset {
  final String label;
  final Color color;
  const _ColorPreset(this.label, this.color);
}
