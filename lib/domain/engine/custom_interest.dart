import 'package:decimal/decimal.dart';

import 'money.dart';

/// How often interest is added for compound interest (null: simple).
enum Compounding { yearly, halfYearly, quarterly, monthly }

extension CompoundingX on Compounding {
  int get perYear => switch (this) {
    Compounding.yearly => 1,
    Compounding.halfYearly => 2,
    Compounding.quarterly => 4,
    Compounding.monthly => 12,
  };
}

/// Interest on [principal] at [rate]% a year for [months] months.
/// Simple when [compounding] is null. With compounding, whole periods are
/// compounded and a part period left over earns simple interest (the usual
/// bank practice). Returned in rupees, rounded half up.
Decimal customInterest(
  Decimal principal,
  Decimal rate,
  int months, {
  Compounding? compounding,
}) {
  if (compounding == null) {
    return rupees(div(principal * rate * Decimal.fromInt(months), k1200));
  }
  final n = compounding.perYear;
  final periodMonths = 12 ~/ n;
  final periods = months ~/ periodMonths;
  final rest = months % periodMonths;
  final perPeriod = div(rate, Decimal.fromInt(100 * n));
  var amount = principal * pw(Decimal.one + perPeriod, periods);
  amount += div(amount * rate * Decimal.fromInt(rest), k1200);
  return rupees(amount - principal);
}
