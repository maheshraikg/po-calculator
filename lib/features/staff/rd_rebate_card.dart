import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/rd_rebate.dart';
import '../../widgets/common.dart';

/// Advance RD deposit: how much to pay after the rebate.
class RdRebateCard extends StatefulWidget {
  const RdRebateCard({super.key, required this.color});
  final Color color;

  @override
  State<RdRebateCard> createState() => _RdRebateCardState();
}

class _RdRebateCardState extends State<RdRebateCard> {
  final _amount = TextEditingController(text: '1000');
  var _n = 12;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, c = widget.color;
    final inst = Decimal.tryParse(_amount.text);
    final ok = inst != null && inst >= Decimal.fromInt(100);
    final total = ok ? inst * Decimal.fromInt(_n) : null;
    final rebate = ok ? rdRebate(inst, _n) : null;
    return SectionCard(
      icon: Icons.savings_rounded,
      title: s.rdRebate,
      color: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.rdInstalment,
              prefixIcon: Icon(Icons.currency_rupee_rounded, color: c),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(s.instalmentsInAdvance(_n)),
          Slider(
            value: _n.toDouble(),
            min: 1,
            max: kRdMaxAdvance.toDouble(),
            divisions: kRdMaxAdvance - 1,
            label: '$_n',
            activeColor: c,
            onChanged: (v) => setState(() => _n = v.round()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in const [6, 12, 24, 36, 60])
                ChoiceChip(
                  label: Text('$n'),
                  selected: _n == n,
                  selectedColor: c.withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _n = n),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!ok)
            Text(s.rdMinInstalment)
          else ...[
            ValueTile(s.amountDue, rupee(total!)),
            ValueTile(
              s.rebate,
              rebate! > Decimal.zero ? '− ${rupee(rebate)}' : rupee(rebate),
            ),
            ValueTile(s.payNow, rupee(total - rebate), emphasis: true),
          ],
          Note(s.rdRebateNote),
        ],
      ),
    );
  }
}
