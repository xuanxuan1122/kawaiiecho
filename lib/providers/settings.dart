// providers/settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ ColorConfig 必须在 SettingsProvider 之前定义
class ColorConfig {
  final Color searchBarColor;
  final Color textButtonColor;
  final Color buttonBgColor;
  final Color listBgColor;
  final Color controlBarColor;

  const ColorConfig({
    this.searchBarColor = const Color(0xFFb0e8b8),
    this.textButtonColor = const Color(0xFF386b42),
    this.buttonBgColor = const Color(0xFFb0e8b8),
    this.listBgColor = const Color(0xFFe898d9),
    this.controlBarColor = const Color(0xFF46c9cc),
  });

  ColorConfig copyWith({
    Color? searchBarColor,
    Color? textButtonColor,
    Color? buttonBgColor,
    Color? listBgColor,
    Color? controlBarColor,
  }) {
    return ColorConfig(
      searchBarColor: searchBarColor ?? this.searchBarColor,
      textButtonColor: textButtonColor ?? this.textButtonColor,
      buttonBgColor: buttonBgColor ?? this.buttonBgColor,
      listBgColor: listBgColor ?? this.listBgColor,
      controlBarColor: controlBarColor ?? this.controlBarColor,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  String? _backgroundImagePath;
  ColorConfig _colors = const ColorConfig();
  double _searchBarBlur = 0.0;
  double _panelBlur = 15.0;
  int _bgVersion = 0;

  String? get backgroundImagePath => _backgroundImagePath;
  ColorConfig get colors => _colors;
  double get searchBarBlur => _searchBarBlur;
  double get panelBlur => _panelBlur;
  int get bgVersion => _bgVersion;

  SettingsProvider() {
    _loadFromPreferences();
  }

  void updateBackgroundImage(String? path) {
    _backgroundImagePath = path;
    _bgVersion++;
    _saveToPreferences();
    notifyListeners();
  }

  void updateSearchBarColor(Color color) {
    _colors = _colors.copyWith(searchBarColor: color);
    _saveToPreferences();
    notifyListeners();
  }

  void updateTextButtonColor(Color color) {
    _colors = _colors.copyWith(textButtonColor: color);
    _saveToPreferences();
    notifyListeners();
  }

  void updateButtonBgColor(Color color) {
    _colors = _colors.copyWith(buttonBgColor: color);
    _saveToPreferences();
    notifyListeners();
  }

  void updateListBgColor(Color color) {
    _colors = _colors.copyWith(listBgColor: color);
    _saveToPreferences();
    notifyListeners();
  }

  void updateControlBarColor(Color color) {
    _colors = _colors.copyWith(controlBarColor: color);
    _saveToPreferences();
    notifyListeners();
  }

  void updateSearchBarBlur(double blur) {
    _searchBarBlur = blur;
    _saveToPreferences();
    notifyListeners();
  }

  void updatePanelBlur(double blur) {
    _panelBlur = blur;
    _saveToPreferences();
    notifyListeners();
  }

  void resetToDefault() {
    _colors = const ColorConfig();
    _searchBarBlur = 0.0;
    _panelBlur = 15.0;
    _backgroundImagePath = null;
    _bgVersion++;
    _saveToPreferences();
    notifyListeners();
  }

  // ========== 持久化 ==========
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_backgroundImagePath != null) {
      prefs.setString('backgroundImagePath', _backgroundImagePath!);
    } else {
      prefs.remove('backgroundImagePath');
    }
    prefs.setString('searchBarColor', _colorToHex(_colors.searchBarColor));
    prefs.setString('textButtonColor', _colorToHex(_colors.textButtonColor));
    prefs.setString('buttonBgColor', _colorToHex(_colors.buttonBgColor));
    prefs.setString('listBgColor', _colorToHex(_colors.listBgColor));
    prefs.setString('controlBarColor', _colorToHex(_colors.controlBarColor));
    prefs.setDouble('searchBarBlur', _searchBarBlur);
    prefs.setDouble('panelBlur', _panelBlur);
  }

  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _backgroundImagePath = prefs.getString('backgroundImagePath');
    _colors = ColorConfig(
      searchBarColor: _hexToColor(prefs.getString('searchBarColor')) ?? const ColorConfig().searchBarColor,
      textButtonColor: _hexToColor(prefs.getString('textButtonColor')) ?? const ColorConfig().textButtonColor,
      buttonBgColor: _hexToColor(prefs.getString('buttonBgColor')) ?? const ColorConfig().buttonBgColor,
      listBgColor: _hexToColor(prefs.getString('listBgColor')) ?? const ColorConfig().listBgColor,
      controlBarColor: _hexToColor(prefs.getString('controlBarColor')) ?? const ColorConfig().controlBarColor,
    );
    _searchBarBlur = prefs.getDouble('searchBarBlur') ?? 0.0;
    _panelBlur = prefs.getDouble('panelBlur') ?? 15.0;
    notifyListeners();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      var str = hex.startsWith('#') ? hex.substring(1) : hex;
      if (str.length == 6) str = 'FF$str';
      return Color(int.parse(str, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
