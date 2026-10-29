import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/engine/combo.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

CalcResult calcAt(Scheme s, int amount, String rate) => calculate(
  CalcInput(
    scheme: s,
    amount: Decimal.fromInt(amount),
    opening: DateTime(2026, 10, 15),
    rate: Decimal.parse(rate),
  ),
);

void main() {
  final rd = Decimal.parse('6.7');

  test('MIS + RD: interest into RD every month', () {
    final mis = calcAt(Scheme.mis, 500000, '7.4');
    final c = comboFor(mis, rd)!;
    // ₹3,083 a month: ₹3,080 into the RD, ₹3 a month kept.
    expect(c.instalment, Decimal.fromInt(3080));
    expect(c.leftover, Decimal.fromInt(180));
    expect(c.rd.input.opening, DateTime(2026, 11, 15));
    expect(c.months, 61);
    expect(c.total, Decimal.fromInt(500000) + c.rd.maturityValue + c.leftover);
    expect(c.total > c.alone, isTrue);
    expect(c.effectiveRate, inInclusiveRange(7.0, 8.0));
  });

  test('TD 5 + RD: each year pays the next 12 instalments', () {
    final td = calcAt(Scheme.td5, 500000, '7.5');
    final c = comboFor(td, rd)!;
    // Yearly interest ₹38,568 / 12 = ₹3,214: ₹3,210 a month.
    expect(c.instalment, Decimal.fromInt(3210));
    expect(c.rd.input.opening, DateTime(2027, 10, 15));
    expect(c.months, 72);
    expect(c.total > c.alone, isTrue);
  });

  test('no combo for small amounts or other schemes', () {
    expect(comboFor(calcAt(Scheme.mis, 10000, '7.4'), rd), isNull);
    expect(comboFor(calcAt(Scheme.nsc, 500000, '7.7'), rd), isNull);
  });

  test('SCSS + RD: each quarter pays the next 3 instalments', () {
    final scss = calcAt(Scheme.scss, 1500000, '8.2');
    final c = comboFor(scss, rd)!;
    // Quarterly interest ₹30,750 / 3 = ₹10,250 a month.
    expect(c.instalment, Decimal.fromInt(10250));
    expect(c.rd.input.opening, DateTime(2027, 1, 15));
    expect(c.months, 63);
    expect(c.total > c.alone, isTrue);
  });

  test('compare: combos ranked by total, within scheme limits', () {
    Decimal rateOf(Scheme s) => Decimal.parse(switch (s) {
      Scheme.mis => '7.4',
      Scheme.scss => '8.2',
      Scheme.td5 => '7.5',
      _ => '6.7',
    });
    final at = DateTime(2026, 10, 15);
    final five = compareCombos(Decimal.fromInt(500000), at, rateOf);
    expect(five.map((p) => p.base.scheme).toSet(), {
      Scheme.mis,
      Scheme.scss,
      Scheme.td5,
    });
    for (var i = 1; i < five.length; i++) {
      expect(five[i - 1].total >= five[i].total, isTrue);
    }
    // Above the joint MIS limit (₹15 lakh): no MIS.
    final big = compareCombos(Decimal.fromInt(2000000), at, rateOf);
    expect(big.map((p) => p.base.scheme), isNot(contains(Scheme.mis)));
  });
}
