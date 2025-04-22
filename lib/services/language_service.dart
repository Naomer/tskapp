import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _setupCompletedKey = 'language_setup_completed';
  static const String _hasSeenLanguageScreenKey = 'has_seen_language_screen';
  final SharedPreferences _prefs;

  LanguageService(this._prefs);

  // Common translations
  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'notifications': 'Notifications',
      'payment_method': 'Payment Method',
      'help_support': 'Help & Support',
      'language': 'Language',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'no': 'No',
      'cancel': 'Cancel',
      'save': 'Save',
    },
    'ar': {
      'my_profile': 'ملفي الشخصي',
      'edit_profile': 'تعديل الملف الشخصي',
      'notifications': 'الإشعارات',
      'payment_method': 'طريقة الدفع',
      'help_support': 'المساعدة والدعم',
      'language': 'اللغة',
      'logout': 'تسجيل خروج',
      'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
      'yes': 'نعم',
      'no': 'لا',
      'cancel': 'إلغاء',
      'save': 'حفظ',
    },
  };

  Future<void> setLanguageAndComplete(String language) async {
    await _prefs.setString(_languageKey, language);
    await _prefs.setBool(_setupCompletedKey, true);
    await _prefs.setBool(_hasSeenLanguageScreenKey, true);
  }

  /// Mark the language screen as seen
  Future<void> markLanguageScreenAsSeen() async {
    await _prefs.setBool(_hasSeenLanguageScreenKey, true);
  }

  /// Whether the initial language setup has been completed
  bool get isSetupCompleted => _prefs.getBool(_setupCompletedKey) ?? false;

  /// The currently selected language code (defaults to 'en')
  String get selectedLanguage => _prefs.getString(_languageKey) ?? 'en';

  /// Whether the current language is a Right-to-Left (RTL) language
  bool get isRTL => selectedLanguage == 'ar';

  /// Whether the user has seen the language selection screen
  bool hasSeenLanguageScreen() =>
      _prefs.getBool(_hasSeenLanguageScreenKey) ?? false;

  /// Get the current locale based on selected language
  Locale get currentLocale => Locale(selectedLanguage);

  /// List of supported locales in the app
  List<Locale> get supportedLocales => const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ];

  // Get translation for a key
  String translate(String key) {
    return _translations[selectedLanguage]?[key] ?? key;
  }

  // Get language name
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return code;
    }
  }
}
