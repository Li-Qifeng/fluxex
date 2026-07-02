import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;
  final bool skipExternalLinkConfirm;
  final List<String> blockedKeywords;
  final int accentColorValue;
  final String imageQuality;
  final String proxyHost;
  final int proxyPort;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.skipExternalLinkConfirm = false,
    this.blockedKeywords = const [],
    this.accentColorValue = 0xFF446CB3,
    this.imageQuality = 'high',
    this.proxyHost = '',
    this.proxyPort = 0,
  });

  Color get accentColor => Color(accentColorValue);

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? skipExternalLinkConfirm,
    List<String>? blockedKeywords,
    int? accentColorValue,
    String? imageQuality,
    String? proxyHost,
    int? proxyPort,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      skipExternalLinkConfirm:
          skipExternalLinkConfirm ?? this.skipExternalLinkConfirm,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      imageQuality: imageQuality ?? this.imageQuality,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _themeKey = 'app_theme_mode';
  static const _scaleKey = 'app_text_scale';
  static const _skipExternalConfirmKey = 'skip_external_link_confirm';
  static const _blockedKeywordsKey = 'blocked_keywords';
  static const _accentColorKey = 'app_accent_color';
  static const _imageQualityKey = 'app_image_quality';
  static const _proxyHostKey = 'app_proxy_host';
  static const _proxyPortKey = 'app_proxy_port';

  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      themeMode: _parseThemeMode(prefs.getString(_themeKey) ?? 'system'),
      textScale: prefs.getDouble(_scaleKey) ?? 1.0,
      skipExternalLinkConfirm:
          prefs.getBool(_skipExternalConfirmKey) ?? false,
      blockedKeywords: _parseKeywords(prefs.getString(_blockedKeywordsKey)),
      accentColorValue: prefs.getInt(_accentColorKey) ?? 0xFF446CB3,
      imageQuality: prefs.getString(_imageQualityKey) ?? 'high',
      proxyHost: prefs.getString(_proxyHostKey) ?? '',
      proxyPort: prefs.getInt(_proxyPortKey) ?? 0,
    );
    // Apply saved proxy on startup
    if (state.proxyHost.isNotEmpty && state.proxyPort > 0) {
      ApiClient().configureProxy(state.proxyHost, state.proxyPort);
    }
  }

  List<String> _parseKeywords(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((k) => k.isNotEmpty).toList();
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
    final updated = state.blockedKeywords.where((k) => k != keyword).toList();
    await setBlockedKeywords(updated);
  }

  Future<void> setAccentColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, colorValue);
    state = state.copyWith(accentColorValue: colorValue);
  }

  Future<void> setImageQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageQualityKey, quality);
    state = state.copyWith(imageQuality: quality);
  }

  Future<void> setProxy(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proxyHostKey, host);
    await prefs.setInt(_proxyPortKey, port);
    state = state.copyWith(proxyHost: host, proxyPort: port);
    ApiClient().configureProxy(host, port);
  }

  Future<void> clearProxy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proxyHostKey);
    await prefs.remove(_proxyPortKey);
    state = state.copyWith(proxyHost: '', proxyPort: 0);
    ApiClient().configureProxy('', 0);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
