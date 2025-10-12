import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    final String jsonString = await rootBundle.loadString(
      'lib/core/localizations/l10n/${locale.languageCode}.json',
    );

    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Static list of supported locales
  static const supportedLocales = [Locale('en'), Locale('pl')];

  static String getLocaleName(String localeCode) {
    const localeNames = {'en': 'English', 'pl': 'Polski'};
    return localeNames[localeCode] ?? localeCode;
  }
}
