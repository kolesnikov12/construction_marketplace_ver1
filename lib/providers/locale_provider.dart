import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:construction_marketplace/utils/constants.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = Locale('en', '');

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  void setLocale(Locale locale) async {
    if (!['en', 'fr'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.prefsLanguage, locale.languageCode);
  }

  void _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(Constants.prefsLanguage)) {
      final languageCode = prefs.getString(Constants.prefsLanguage) ?? Constants.defaultLocale;
      _locale = Locale(languageCode, '');
      notifyListeners();
    }
  }
}