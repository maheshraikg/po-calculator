import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/result.dart';
import '../models/scheme.dart';
import 'calculators.dart';
import 'dates.dart';
import 'money.dart';

/// MIS or 5-year TD with its interest moved into an RD (by standing
/// instruction from the savings account).
///
/// MIS: each month's interest pays that month's RD instalment, so the RD
/// starts a month after the MIS and matures a month after it.
/// TD 5: each year's interest pays the next 12 instalments, so the RD starts
/// a year after the TD (after the first interest) and matures a year after
/// it. Instalments are the interest rounded down to ₹10; the few rupees
/// left over each time stay in the savings account and are counted as cash.
class ComboPlan {
  const ComboPlan({
    required this.base,
    required this.instalment,
    required this.rd,
    required this.leftover,
  });

  final CalcResult base;
  final Decimal instalment;
  final CalcResult rd;

  /// Interest not used for the RD (the rounding), kept as cash.
  final Decimal leftover;

  Decimal get deposit => base.input.amount;

  /// Deposit back + RD maturity + leftover, when the RD matures.
  Decimal get total => deposit + rd.maturityValue + leftover;

  /// The scheme alone: deposit back + interest received as cash.
  Decimal get alone => base.maturityValue;

  Decimal get extra => total - alone;

  /// Months from opening the deposit to the RD's maturity.
  int get months =>
      (rd.maturityDate.year - base.input.opening.year) * 12 +
      rd.maturityDate.month -
      base.input.opening.month;

  /// Yearly rate that turns [deposit] into [total] over [months], compounded
  /// yearly (for comparison with other schemes; shown, not used in money).
  double get effectiveRate =>
      (math.pow((total / deposit).toDouble(), 12 / months) - 1) * 100;
}

/// The combo for an MIS or TD 5 result, or null for other schemes or when
/// the interest is below the smallest RD instalment.
ComboPlan? comboFor(CalcResult r, Decimal rdRate) {
  final payout = r.periodicPayout;
  if (payout == null) return null;
  final Decimal perMonth;
  final int startMonths;
  final int rdInstalments;
  switch (r.scheme) {
    case Scheme.mis:
      perMonth = payout;
      startMonths = 1;
      rdInstalments = r.scheme.tenureMonths;
    case Scheme.td5:
      perMonth = div(payout, Decimal.fromInt(12));
      startMonths = 12;
      rdInstalments = r.scheme.tenureMonths;
    default:
      return null;
  }
  final ten = Decimal.fromInt(10);
  final inst = (perMonth / ten).floor().toDecimal() * ten;
  if (inst < Scheme.rd.min) return null;
  final rd = calculate(
    CalcInput(
      scheme: Scheme.rd,
      amount: inst,
      opening: addMonths(r.input.opening, startMonths),
      rate: rdRate,
    ),
  );
  final leftover = rupees((perMonth - inst) * Decimal.fromInt(rdInstalments));
  return ComboPlan(base: r, instalment: inst, rd: rd, leftover: leftover);
}
