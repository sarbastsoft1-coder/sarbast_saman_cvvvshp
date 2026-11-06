import 'package:flutter/material.dart';
import 'translations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static bool isSupportedLanguage(String languageCode) =>
      Translations.supportedLanguages.contains(languageCode);

  bool get isRtl => Translations.isRtl(locale.languageCode);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  String translate(String key, {Map<String, Object?>? params}) {
    final dict = Translations.dictionary[locale.languageCode];
    var value = dict != null && dict.containsKey(key) ? dict[key] : null;

    if (value == null) {
      final fallback = Translations.dictionary['en'];
      value = fallback != null && fallback.containsKey(key) ? fallback[key] : key;
    }

    return _applyParams(value!, params);
  }

  static String _applyParams(String value, Map<String, Object?>? params) {
    if (params == null || params.isEmpty || !value.contains('{')) {
      return value;
    }
    var result = value;
    params.forEach((name, replacement) {
      result = result.replaceAll('{$name}', '${replacement ?? ''}');
    });
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      Translations.supportedLanguages.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
