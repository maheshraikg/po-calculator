import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/features/result/suggestions.dart';

Decimal rate(Scheme s) => Decimal.parse(switch (s) {
  Scheme.sb => '4',
  Scheme.rd => '6.7',
  Scheme.td5 => '7.5',
  Scheme.mis => '7.4',
  Scheme.scss => '8.2',
  Scheme.nsc => '7.7',
  Scheme.kvp => '7.5',
  Scheme.ppf => '7.1',
  Scheme.ssy => '8.2',
  _ => '7',
});

CalcResult calcAt(Scheme s, int amount) => calculate(
  CalcInput(
    scheme: s,
    amount: Decimal.fromInt(amount),
    opening: DateTime(2026, 10, 10),
    rate: rate(s),
  ),
);

void main() {
  test('MIS interest into an RD beats leaving it in savings', () {
    final sug = suggestFor(calcAt(Scheme.mis, 100000), rate);
    // ₹617 a month: ₹610 into the RD.
    expect(sug.rd!.instalment, Decimal.fromInt(610));
    expect(sug.rd!.extra, greaterThan(Decimal.zero));
    expect(sug.better!.scheme, Scheme.nsc);
    expect(sug.senior!.scheme, Scheme.scss);
  });

  test('small MIS interest is too little for an RD', () {
    expect(suggestFor(calcAt(Scheme.mis, 1000), rate).rd, isNull);
  });

  test('NSC is already the best; SCSS, paid out, totals less', () {
    final sug = suggestFor(calcAt(Scheme.nsc, 100000), rate);
    expect(sug.isBest, isTrue);
    expect(sug.better, isNull);
    expect(sug.senior, isNull);
  });

  test('TD 5 years: NSC gives more for everyone', () {
    final sug = suggestFor(calcAt(Scheme.td5, 100000), rate);
    expect(sug.better!.scheme, Scheme.nsc);
    expect(sug.rd, isNull);
  });

  test('no suggestions for PPF', () {
    expect(suggestFor(calcAt(Scheme.ppf, 100000), rate).isEmpty, isTrue);
  });

  test('savings account: ₹100 a month for a year at 4%', () {
    // Interest on 100, 200, … 1200 for a month each = 7800 × 4 / 1200 = 26.
    expect(
      savingsValue(Decimal.fromInt(100), 12, Decimal.fromInt(4)),
      Decimal.fromInt(1226),
    );
  });
}
