import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in the app
enum AppLanguage {
  english('en', 'us', 'English', 'English', 'EN'),
  chinese('zh', 'cn', '中文', 'Chinese', '简'),
  italian('it', 'it', 'Italiano', 'Italian', 'IT'),
  french('fr', 'fr', 'Français', 'French', 'FR'),
  spanish('es', 'es', 'Español', 'Spanish', 'ES'),
  german('de', 'de', 'Deutsch', 'German', 'DE'),
  arabic('ar', 'sa', 'العربية', 'Arabic', 'AR'),
  korean('ko', 'kr', '한국어', 'Korean', 'KR'),
  japanese('ja', 'jp', '日本語', 'Japanese', 'JP');

  const AppLanguage(this.code, this.countryCode, this.nativeName, this.englishName, this.shortName);

  final String code;
  final String countryCode;
  final String nativeName;
  final String englishName;
  final String shortName;

  Locale get locale => Locale(code);
}

/// Locale provider for managing app language
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const String _localeKey = 'app_locale';

  @override
  Locale build() {
    // Start with English, then load from prefs
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
  }

  /// Set the app language from Locale
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    state = locale;
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Set the app language from AppLanguage enum
  Future<void> setLanguage(AppLanguage language) async {
    await setLocale(language.locale);
  }

  /// Get current language enum
  AppLanguage get currentLanguage {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == state.languageCode,
      orElse: () => AppLanguage.english,
    );
  }
}
