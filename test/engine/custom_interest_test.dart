import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/custom_interest.dart';

Decimal d(String v) => Decimal.parse(v);

void main() {
  test('simple interest', () {
    // 1,00,000 × 7% × 3 years = 21,000.
    expect(customInterest(d('100000'), d('7'), 36), d('21000'));
    // 6 months: 3,500.
    expect(customInterest(d('100000'), d('7'), 6), d('3500'));
  });

  test('compound interest', () {
    // Yearly: 100000 × 1.1^2 − 100000 = 21,000.
    expect(
      customInterest(d('100000'), d('10'), 24, compounding: Compounding.yearly),
      d('21000'),
    );
    // Quarterly, 1 year at 8%: 100000 × 1.02^4 − 100000 = 8,243.216 → 8,243.
    expect(
      customInterest(
        d('100000'),
        d('8'),
        12,
        compounding: Compounding.quarterly,
      ),
      d('8243'),
    );
    // Monthly, 1 year at 12%: 1.01^12 → 12,682.50 → 12,683.
    expect(
      customInterest(
        d('100000'),
        d('12'),
        12,
        compounding: Compounding.monthly,
      ),
      d('12683'),
    );
  });

  test('a part period earns simple interest on the compounded amount', () {
    // Yearly at 10% for 18 months: 110000, then 6 months simple = 5,500.
    expect(
      customInterest(d('100000'), d('10'), 18, compounding: Compounding.yearly),
      d('15500'),
    );
  });
}
