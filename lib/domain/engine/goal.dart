import 'package:decimal/decimal.dart';

import '../models/result.dart';
import '../models/scheme.dart';
import 'calculators.dart';
import 'money.dart';

/// Schemes that grow a deposit to a goal, in the order shown.
const kGoalSchemes = [
  Scheme.nsc,
  Scheme.td5,
  Scheme.kvp,
  Scheme.td3,
  Scheme.td2,
  Scheme.td1,
  Scheme.rd,
  Scheme.ppf,
  Scheme.ssy,
];

/// The smallest deposit in [scheme] that pays at least [target]: one
/// deposit, a monthly instalment or a yearly deposit (see
/// [Scheme.amountKind]), rounded up to what the scheme accepts.
class GoalPlan {
  const GoalPlan(this.result, {required this.reached});

  /// At the needed amount, or at the scheme's maximum if [reached] is false.
  final CalcResult result;
  final bool reached;
}

GoalPlan goalPlan(
  Scheme scheme,
  Decimal target,
  DateTime opening,
  Decimal rate,
) {
  CalcResult at(Decimal a) => calculate(
    CalcInput(scheme: scheme, amount: a, opening: opening, rate: rate),
  );
  final step = Decimal.fromInt(scheme.multipleOf);
  Decimal roundUp(Decimal a) {
    final r = (a / step).ceil().toDecimal() * step;
    return r < scheme.min ? scheme.min : r;
  }

  final max = scheme.maxAmount == null
      ? null
      : Decimal.fromInt(scheme.maxAmount!);
  if (max != null) {
    final top = at(max);
    if (top.maturityValue < target) return GoalPlan(top, reached: false);
  }
  // Maturity grows in proportion to the deposit (apart from rounding), so
  // scale from the minimum, then step to the exact smallest amount.
  final base = at(scheme.min);
  var a = roundUp(div(target * scheme.min, base.maturityValue));
  if (max != null && a > max) a = max;
  var r = at(a);
  while (r.maturityValue < target && (max == null || a + step <= max)) {
    a += step;
    r = at(a);
  }
  while (a - step >= scheme.min) {
    final lower = at(a - step);
    if (lower.maturityValue < target) break;
    a -= step;
    r = lower;
  }
  return GoalPlan(r, reached: r.maturityValue >= target);
}
