import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;
  final bool skipExternalLinkConfirm;
  final List<String> blockedKeywords;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.skipExternalLinkConfirm = false,
    this.blockedKeywords = const [],
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? skipExternalLinkConfirm,
    List<String>? blockedKeywords,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      skipExternalLinkConfirm:
          skipExternalLinkConfirm ?? this.skipExternalLinkConfirm,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _themeKey = 'app_theme_mode';
  static const _scaleKey = 'app_text_scale';
  static const _skipExternalConfirmKey = 'skip_external_link_confirm';
  static const _blockedKeywordsKey = 'blocked_keywords';

  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey) ?? 'system';
    final scale = prefs.getDouble(_scaleKey) ?? 1.0;
    final skipConfirm = prefs.getBool(_skipExternalConfirmKey) ?? false;
    final keywordsStr = prefs.getString(_blockedKeywordsKey) ?? '';
    final keywords = keywordsStr.isEmpty
        ? <String>[]
        : keywordsStr.split(',').where((k) => k.isNotEmpty).toList();
    state = AppSettings(
      themeMode: _parseThemeMode(themeStr),
      textScale: scale,
      skipExternalLinkConfirm: skipConfirm,
      blockedKeywords: keywords,
    );
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scaleKey, scale);
    state = state.copyWith(textScale: scale);
  }

  Future<void> setSkipExternalLinkConfirm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipExternalConfirmKey, value);
    state = state.copyWith(skipExternalLinkConfirm: value);
  }

  Future<void> setBlockedKeywords(List<String> keywords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blockedKeywordsKey, keywords.join(','));
    state = state.copyWith(blockedKeywords: keywords);
  }

  Future<void> addBlockedKeyword(String keyword) async {
    final updated = [...state.blockedKeywords, keyword];
    await setBlockedKeywords(updated);
  }

  Future<void> removeBlockedKeyword(String keyword) async {
    final updated =
        state.blockedKeywords.where((k) => k != keyword).toList();
    await setBlockedKeywords(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
