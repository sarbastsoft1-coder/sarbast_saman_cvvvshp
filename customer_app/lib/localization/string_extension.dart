import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension StringLocalization on String {
  /// Translates this string (used as the lookup key) into the active language.
  ///
  ///     Text('Add to Cart'.tr(context))
  ///     Text('{name} added to cart!'.tr(context, params: {'name': product.name}))
  String tr(BuildContext context, {Map<String, Object?>? params}) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return params == null || params.isEmpty ? this : _fill(this, params);
    }
    return localizations.translate(this, params: params);
  }

  static String _fill(String value, Map<String, Object?> params) {
    var result = value;
    params.forEach((name, replacement) {
      result = result.replaceAll('{$name}', '${replacement ?? ''}');
    });
    return result;
  }
}

extension LocalizationContext on BuildContext {
  /// True when the active language is written right-to-left (Kurdish Sorani, Arabic).
  bool get isRtl => AppLocalizations.of(this)?.isRtl ?? false;

  TextDirection get localeDirection =>
      AppLocalizations.of(this)?.textDirection ?? TextDirection.ltr;
}
