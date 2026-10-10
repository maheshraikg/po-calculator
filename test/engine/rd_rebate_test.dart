import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/rd_rebate.dart';

void main() {
  test('rebate per ₹100: ₹10 for 6, ₹40 for 12, nothing below 6', () {
    expect(rdRebatePer100(5), 0);
    expect(rdRebatePer100(6), 10);
    expect(rdRebatePer100(11), 10);
    expect(rdRebatePer100(12), 40);
    expect(rdRebatePer100(18), 50);
    expect(rdRebatePer100(24), 80);
    expect(rdRebatePer100(60), 200);
  });

  test('rebate scales with the instalment', () {
    expect(rdRebate(Decimal.fromInt(1000), 12), Decimal.fromInt(400));
    expect(rdRebate(Decimal.fromInt(500), 6), Decimal.fromInt(50));
    expect(rdRebate(Decimal.fromInt(150), 6), Decimal.fromInt(15));
  });
}
