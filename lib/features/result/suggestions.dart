import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/combo.dart';
import '../../domain/engine/dates.dart';
import '../../domain/engine/money.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../compare/compare_screen.dart';
import 'result_screen.dart';

/// Monthly interest from MIS or SCSS put into an RD, against leaving it in
/// the savings account.
class RdReinvest {
  const RdReinvest(this.instalment, this.rd, this.sb);
  final Decimal instalment;
  final CalcResult rd;

  /// Same instalments left in the savings account.
  final Decimal sb;

  Decimal get extra => rd.maturityValue - sb;
}

/// What the customer could do better with the same money.
class Suggestions {
  const Suggestions({this.rd, this.better, this.senior, this.isBest = false});
  final RdReinvest? rd;

  /// Higher 5-year return, open to everyone.
  final CalcResult? better;

  /// SCSS, if it pays more than this scheme (age 60+ only).
  final CalcResult? senior;

  /// This scheme already gives the highest 5-year return for everyone.
  final bool isBest;

  bool get isEmpty => rd == null && better == null && senior == null && !isBest;
}

/// [inst] every month for [months] months in a savings account at [rate]%:
/// interest on the balance each month, credited every 12 months.
Decimal savingsValue(Decimal inst, int months, Decimal rate) {
  var bal = Decimal.zero, accrued = Decimal.zero;
  for (var m = 1; m <= months; m++) {
    bal += inst;
    accrued += div(bal * rate, Decimal.fromInt(1200));
    if (m % 12 == 0 || m == months) {
      bal += rupees(accrued);
      accrued = Decimal.zero;
    }
  }
  return bal;
}

Suggestions suggestFor(CalcResult r, Decimal Function(Scheme) rateOf) {
  final scheme = r.scheme;

  RdReinvest? rd;
  final payout = r.periodicPayout;
  if (payout != null && (scheme == Scheme.mis || scheme == Scheme.scss)) {
    final monthly = scheme == Scheme.scss
        ? div(payout, Decimal.fromInt(3))
        : payout;
    final inst =
        (monthly / Decimal.fromInt(10)).floor().toDecimal() *
        Decimal.fromInt(10);
    if (inst >= Scheme.rd.min) {
      final res = calculate(
        CalcInput(
          scheme: Scheme.rd,
          amount: inst,
          opening: addMonths(r.input.opening, 1),
          rate: rateOf(Scheme.rd),
        ),
      );
      rd = RdReinvest(
        inst,
        res,
        savingsValue(inst, Scheme.rd.tenureMonths, rateOf(Scheme.sb)),
      );
    }
  }

  CalcResult? better, senior;
  var isBest = false;
  const fiveYear = [Scheme.td5, Scheme.nsc, Scheme.mis, Scheme.scss];
  if (fiveYear.contains(scheme)) {
    final group = compareAll(
      r.input.amount,
      r.input.opening,
      rateOf,
    ).firstWhere((g) => g.$1 == CompareGroup.fiveYears).$2;
    final others = group
        .where((o) => fiveYear.contains(o.scheme) && o.scheme != scheme)
        .toList();
    final open = others.where((o) => openToAll(o.scheme));
    final top = open.isEmpty ? null : open.first;
    if (top != null && top.maturityValue > r.maturityValue) {
      better = top;
    } else if (openToAll(scheme)) {
      isBest = true;
    }
    for (final o in others) {
      if (o.scheme == Scheme.scss && o.maturityValue > r.maturityValue) {
        senior = o;
      }
    }
  }
  return Suggestions(rd: rd, better: better, senior: senior, isBest: isBest);
}

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final sug = suggestFor(result, (sc) => rates.current(sc).rate);
    if (sug.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rd = sug.rd;
    return SectionCard(
      icon: Icons.lightbulb_rounded,
      title: s.suggestions,
      color: Brand.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rd != null) ...[
            const SizedBox(height: 12),
            Text(
              s.rdReinvestTitle(rupee(rd.instalment)),
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _ValueRow(
              label: s.inRd,
              value: rupee(rd.rd.maturityValue),
              highlight: true,
            ),
            _ValueRow(label: s.leftInSb, value: rupee(rd.sb)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Pill(
                s.moreBy(rupee(rd.extra)),
                icon: Icons.trending_up_rounded,
                background: Colors.green.withValues(alpha: 0.15),
                foreground: dark ? Colors.white : Colors.green.shade800,
              ),
            ),
            Note(s.rdReinvestNote, icon: Icons.sync_alt_rounded),
          ],
          if (sug.better != null)
            _SchemeOption(
              base: result,
              other: sug.better!,
              note:
                  result.scheme.payout != null &&
                      sug.better!.scheme.payout == null
                  ? s.noRegularIncome
                  : null,
            ),
          if (sug.senior != null)
            _SchemeOption(base: result, other: sug.senior!, tag: s.seniorsOnly),
          if (sug.isBest)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Brand.yellow),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.alreadyBest)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// MIS or TD 5 with its interest put into an RD: what the customer has when
/// the RD matures.
class ComboCard extends StatelessWidget {
  const ComboCard({super.key, required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final plan = comboFor(result, context.rates.current(Scheme.rd).rate);
    if (plan == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final code = result.scheme.code;
    final rdColor = Scheme.rd.color;
    return SectionCard(
      icon: Icons.account_tree_rounded,
      title: s.comboTitle(code),
      color: rdColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            s.comboIntro(rupee(plan.instalment), dmy(plan.rd.input.opening)),
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _ValueRow(label: s.depositBack, value: rupee(plan.deposit)),
          _ValueRow(
            label: s.rdMaturityOn(dmy(plan.rd.maturityDate)),
            value: rupee(plan.rd.maturityValue),
          ),
          if (plan.leftover > Decimal.zero)
            _ValueRow(label: s.leftoverInterest, value: rupee(plan.leftover)),
          _ValueRow(
            label: s.totalOn(dmy(plan.rd.maturityDate)),
            value: rupee(plan.total),
            highlight: true,
          ),
          _ValueRow(label: s.schemeAlone(code), value: rupee(plan.alone)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                s.moreBy(rupee(plan.extra)),
                icon: Icons.trending_up_rounded,
                background: Colors.green.withValues(alpha: 0.15),
                foreground: dark ? Colors.white : Colors.green.shade800,
              ),
              Pill(
                s.effectiveReturn(plan.effectiveRate.toStringAsFixed(2)),
                icon: Icons.percent_rounded,
                background: rdColor.withValues(alpha: 0.12),
                foreground: Scheme.rd.textColor(context),
              ),
            ],
          ),
          Note(s.comboNote(code), icon: Icons.sync_alt_rounded),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResultScreen(result: plan.rd),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(s.openRd),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label, value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? Brand.yellow : null,
        border: highlight ? null : Border.all(color: Brand.yellow),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(
                color: highlight ? Brand.ink : null,
                fontWeight: highlight ? FontWeight.w700 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: t.titleMedium?.copyWith(
              color: highlight ? Brand.ink : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeOption extends StatelessWidget {
  const _SchemeOption({
    required this.base,
    required this.other,
    this.note,
    this.tag,
  });
  final CalcResult base, other;
  final String? note, tag;

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final sc = other.scheme, c = sc.color;
    final extra = other.maturityValue - base.maturityValue;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResultScreen(result: other),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(sc.icon, c, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.betterOption(s.schemeName(sc)),
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.betterValue(
                          pct(other.input.rate),
                          rupee(other.maturityValue),
                          rupee(extra),
                        ),
                        style: t.bodyMedium,
                      ),
                      if (tag != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Pill(
                            tag!,
                            icon: Icons.info_outline_rounded,
                            background: c.withValues(alpha: 0.12),
                            foreground: sc.textColor(context),
                          ),
                        ),
                      if (note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(note!, style: t.bodySmall),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
