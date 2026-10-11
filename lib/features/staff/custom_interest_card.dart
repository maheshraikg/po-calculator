import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/custom_interest.dart';
import '../../widgets/common.dart';

/// Simple or compound interest at any rate and period.
class CustomInterestCard extends StatefulWidget {
  const CustomInterestCard({super.key, required this.color});
  final Color color;

  @override
  State<CustomInterestCard> createState() => _CustomInterestCardState();
}

class _CustomInterestCardState extends State<CustomInterestCard> {
  final _amount = TextEditingController(text: '100000');
  final _rate = TextEditingController(text: '7');
  final _years = TextEditingController(text: '5');
  final _months = TextEditingController(text: '0');

  /// null: simple interest.
  Compounding? _comp = Compounding.quarterly;

  @override
  void dispose() {
    for (final c in [_amount, _rate, _years, _months]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool decimal = false,
    IconData? icon,
  }) => TextField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      decimal
          ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: widget.color),
    ),
    onChanged: (_) => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.s, c = widget.color;
    final p = Decimal.tryParse(_amount.text);
    final r = Decimal.tryParse(_rate.text);
    final months =
        (int.tryParse(_years.text) ?? 0) * 12 +
        (int.tryParse(_months.text) ?? 0);
    final ok =
        p != null &&
        p > Decimal.zero &&
        r != null &&
        r > Decimal.zero &&
        months > 0 &&
        months <= 1200;
    final interest = ok
        ? customInterest(p, r, months, compounding: _comp)
        : null;
    return SectionCard(
      icon: Icons.calculate_rounded,
      title: s.customCalc,
      color: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _field(_amount, s.principal, icon: Icons.currency_rupee_rounded),
          const SizedBox(height: 10),
          _field(_rate, s.ratePa, decimal: true, icon: Icons.percent_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field(_years, s.yearsLabel)),
              const SizedBox(width: 10),
              Expanded(child: _field(_months, s.monthsLabel)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in <Compounding?>[null, ...Compounding.values])
                ChoiceChip(
                  label: Text(s.compounding(k)),
                  selected: _comp == k,
                  selectedColor: c.withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _comp = k),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (interest == null)
            Text(s.customCalcHint)
          else ...[
            ValueTile(s.interest, rupee(interest)),
            ValueTile(s.totalAmount, rupee(p! + interest), emphasis: true),
          ],
          Note(s.customCalcNote),
        ],
      ),
    );
  }
}
