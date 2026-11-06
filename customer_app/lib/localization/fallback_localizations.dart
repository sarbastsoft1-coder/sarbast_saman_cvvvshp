import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter's bundled `GlobalMaterialLocalizations` only know standard shipped language codes.
/// Kurdish Sorani (`ckb`) maps to `ar` for material widgets to ensure authentic RTL direction
/// and native Arabic-script digit and widget handling.
const Map<String, String> kFrameworkLocaleFallbacks = <String, String>{
  'ckb': 'ar',
  'ku': 'ar',
};

Locale? _fallbackFor(Locale locale) {
  final code = kFrameworkLocaleFallbacks[locale.languageCode];
  return code == null ? null : Locale(code);
}

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _fallbackFor(locale) != null;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallbackFor(locale)!);

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _fallbackFor(locale) != null;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_fallbackFor(locale)!);

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _fallbackFor(locale) != null;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallbackFor(locale)!);

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
