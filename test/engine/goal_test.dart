import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/goal.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

final opening = DateTime(2026, 10, 10);
final target = Decimal.fromInt(500000);

void main() {
  test('smallest deposit that reaches the goal, in the scheme multiple', () {
    for (final (s, rate) in [
      (Scheme.nsc, '7.7'),
      (Scheme.td5, '7.5'),
      (Scheme.kvp, '7.5'),
      (Scheme.td1, '6.9'),
      (Scheme.rd, '6.7'),
      (Scheme.ppf, '7.1'),
      (Scheme.ssy, '8.2'),
    ]) {
      final p = goalPlan(s, target, opening, Decimal.parse(rate));
      final a = p.result.input.amount;
      expect(p.reached, isTrue, reason: s.code);
      expect(p.result.maturityValue >= target, isTrue, reason: s.code);
      expect(
        (a / Decimal.fromInt(s.multipleOf)).isInteger,
        isTrue,
        reason: s.code,
      );
      // One step less falls short.
      final less = goalPlan(
        s,
        p.result.maturityValue + Decimal.one,
        opening,
        Decimal.parse(rate),
      ).result.input.amount;
      expect(less > a, isTrue, reason: s.code);
    }
  });

  test('KVP doubles: ₹2,50,000 gives ₹5,00,000', () {
    final p = goalPlan(Scheme.kvp, target, opening, Decimal.parse('7.5'));
    expect(p.result.input.amount, Decimal.fromInt(250000));
  });

  test('PPF beyond ₹1.5 lakh a year is not reachable', () {
    final p = goalPlan(
      Scheme.ppf,
      Decimal.fromInt(100000000),
      opening,
      Decimal.parse('7.1'),
    );
    expect(p.reached, isFalse);
    expect(p.result.input.amount, Decimal.fromInt(150000));
  });

  test('a small goal needs at least the minimum', () {
    final p = goalPlan(
      Scheme.rd,
      Decimal.fromInt(10),
      opening,
      Decimal.parse('6.7'),
    );
    expect(p.result.input.amount, Scheme.rd.min);
  });
}
