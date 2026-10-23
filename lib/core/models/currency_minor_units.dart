/// Currencies whose minor units carry no fractional digits.
const Set<String> _zeroDecimalCurrencies = <String>{'JPY', 'KRW', 'VND', 'CLP'};

/// Currencies whose minor units carry three fractional digits.
const Set<String> _threeDecimalCurrencies = <String>{
  'BHD',
  'KWD',
  'OMR',
  'TND',
};

/// Returns the number of fractional digits [currency] uses in its minor
/// units.
///
/// Amounts are stored as minor units (for example cents). Most currencies
/// split one unit into one hundred minor units, so the default is two
/// fractional digits. A few currencies differ: the Japanese yen and
/// similar currencies have no fractional part, while the Bahraini dinar
/// and similar currencies split one unit into one thousand minor units.
/// A null currency falls back to the two-digit default.
int minorUnitsFractionDigits(String? currency) {
  if (currency == null) {
    return 2;
  }
  if (_zeroDecimalCurrencies.contains(currency)) {
    return 0;
  }
  if (_threeDecimalCurrencies.contains(currency)) {
    return 3;
  }
  return 2;
}

/// Formats [amountMinorUnits] as a decimal string for [currency].
///
/// The output keeps the raw number shape used across FinEcho cards: a
/// leading minus sign for negative amounts, no grouping separators, and no
/// currency symbol. Callers combine the result with the currency code as
/// they see fit.
String formatMinorUnits(int amountMinorUnits, String? currency) {
  final sign = amountMinorUnits.isNegative ? '-' : '';
  final absolute = amountMinorUnits.abs();
  final fractionDigits = minorUnitsFractionDigits(currency);
  final fractionScale = _pow10(fractionDigits);
  final units = absolute ~/ fractionScale;
  if (fractionDigits == 0) {
    return '$sign$units';
  }
  final fraction = (absolute % fractionScale).toString().padLeft(
    fractionDigits,
    '0',
  );
  return '$sign$units.$fraction';
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
