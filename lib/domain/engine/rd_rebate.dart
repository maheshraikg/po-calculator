import 'package:decimal/decimal.dart';

import 'money.dart';

/// Most instalments an RD can be paid in advance (5 years).
const kRdMaxAdvance = 60;

/// Rebate in rupees per ₹100 of instalment when [n] instalments (including
/// this month's) are paid at once: ₹10 for 6, ₹40 for 12, for each block.
int rdRebatePer100(int n) => n ~/ 12 * 40 + (n % 12 >= 6 ? 10 : 0);

/// Rebate on paying [n] instalments of [instalment] in advance.
Decimal rdRebate(Decimal instalment, int n) =>
    rupees(div(instalment * Decimal.fromInt(rdRebatePer100(n)), kHundred));
