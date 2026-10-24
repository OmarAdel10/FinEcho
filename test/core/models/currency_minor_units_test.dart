import 'package:finecho/core/models/currency_minor_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('minorUnitsFractionDigits', () {
    test('returns zero for zero-decimal currencies', () {
      expect(minorUnitsFractionDigits('JPY'), 0);
      expect(minorUnitsFractionDigits('KRW'), 0);
      expect(minorUnitsFractionDigits('VND'), 0);
      expect(minorUnitsFractionDigits('CLP'), 0);
    });

    test('returns three for three-decimal currencies', () {
      expect(minorUnitsFractionDigits('BHD'), 3);
      expect(minorUnitsFractionDigits('KWD'), 3);
      expect(minorUnitsFractionDigits('OMR'), 3);
      expect(minorUnitsFractionDigits('TND'), 3);
    });

    test('returns two for two-decimal, unknown, and null currencies', () {
      expect(minorUnitsFractionDigits('EGP'), 2);
      expect(minorUnitsFractionDigits('USD'), 2);
      expect(minorUnitsFractionDigits('XYZ'), 2);
      expect(minorUnitsFractionDigits(null), 2);
    });
  });

  group('formatMinorUnits', () {
    test('drops the fraction for a zero-decimal currency', () {
      expect(formatMinorUnits(1234, 'JPY'), '1234');
      expect(formatMinorUnits(-1234, 'JPY'), '-1234');
    });

    test('formats three fraction digits for a three-decimal currency', () {
      expect(formatMinorUnits(123456, 'BHD'), '123.456');
      expect(formatMinorUnits(-123456, 'KWD'), '-123.456');
    });

    test('formats two fraction digits by default', () {
      expect(formatMinorUnits(1250, 'EGP'), '12.50');
      expect(formatMinorUnits(1250, null), '12.50');
      expect(formatMinorUnits(500, 'USD'), '5.00');
    });

    test('prefixes only negative amounts with a sign', () {
      expect(formatMinorUnits(-1250, 'EGP'), '-12.50');
      expect(formatMinorUnits(1250, 'EGP'), '12.50');
    });

    test('formats zero without a sign', () {
      expect(formatMinorUnits(0, 'EGP'), '0.00');
      expect(formatMinorUnits(0, 'JPY'), '0');
    });

    test('pads a short fraction to the currency digits', () {
      expect(formatMinorUnits(1005, 'EGP'), '10.05');
      expect(formatMinorUnits(5, 'BHD'), '0.005');
    });
  });
}
