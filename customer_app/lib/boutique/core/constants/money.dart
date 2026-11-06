/// Canonical money formatting for the Roni storefront.
///
/// The app used to format prices in two unrelated ways: a global
/// `formatPrice()` that produced Iraqi Dinar strings ("35,000 د.ع") and a
/// per-product `formatAmount()` that produced bare dollar strings ("$78.00").
/// The same number could therefore render two different ways depending on
/// which screen it appeared on.
///
/// Every price in the app now goes through [Money.format], so a customer sees
/// one price language everywhere: thousands separators, a currency marker, and
/// the same weight and size regardless of screen.
class Money {
  Money._();

  static const String iqd = 'IQD';
  static const String usd = 'USD';

  /// Iraqi Dinar marker.
  static const String iqdMarker = 'د.ع';

  /// Formats [value] for the given [currency].
  ///
  /// Iraqi Dinar is never shown with decimals — dinar amounts are whole
  /// numbers. Fiat keeps two decimals because the seeded catalog carries
  /// fractional prices.
  static String format(num value, {String currency = iqd}) {
    if (currency.toUpperCase() == usd) return formatUsd(value);
    return formatIqd(value);
  }

  /// "35,000 د.ع"
  static String formatIqd(num value) =>
      '${group(value.toStringAsFixed(0))} $iqdMarker';

  /// "$78.00"
  static String formatUsd(num value) => '\$${group(value.toStringAsFixed(2))}';

  /// Inserts thousands separators into an already-formatted numeric string.
  ///
  /// Only the integer part is grouped — the fractional part is left alone, so
  /// "75.00" becomes "75.00" and "1250.50" becomes "1,250.50" rather than
  /// "75,.00".
  static String group(String value) {
    final negative = value.startsWith('-');
    final bare = negative ? value.substring(1) : value;
    final dot = bare.indexOf('.');
    final whole = dot == -1 ? bare : bare.substring(0, dot);
    final fraction = dot == -1 ? '' : bare.substring(dot);

    final buffer = StringBuffer();
    var count = 0;
    for (var i = whole.length - 1; i >= 0; i--) {
      buffer.write(whole[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }
    final grouped = buffer.toString().split('').reversed.join();
    return '${negative ? '-' : ''}$grouped$fraction';
  }
}
