import 'package:flutter/material.dart';

import '../../app/scope.dart';
import '../../domain/models/service_fee.dart';
import '../../widgets/common.dart';

class ServiceCharges extends StatelessWidget {
  const ServiceCharges({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SectionCard(
      icon: Icons.request_quote_rounded,
      title: s.serviceCharges,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          for (final (i, MapEntry(key: f, value: fee))
              in kServiceFees.entries.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ValueTile(
              s.serviceFee(f),
              f == ServiceFee.chequeBook ? s.chequeLeafFee(fee) : '₹$fee',
            ),
          ],
          Note(s.serviceChargesNote, icon: Icons.receipt_long_outlined),
        ],
      ),
    );
  }
}
