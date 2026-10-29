import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/combo.dart';
import '../../domain/engine/eligibility.dart';
import '../../domain/engine/goal.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../result/result_screen.dart';

/// Schemes open to everyone; the "highest return" badge only goes to these.
bool openToAll(Scheme s) => s != Scheme.scss && s != Scheme.ssy;

/// Results for the same amount across every open scheme, at today's rates,
/// grouped by how long the money is kept. Within a group, highest value
/// first (KVP, at about 115 months, last in the 5-year group).
List<(CompareGroup, List<CalcResult>)> compareAll(
  Decimal amount,
  DateTime opening,
  Decimal Function(Scheme) rateOf,
) {
  CalcResult? calc(Scheme s, Decimal a) {
    if (a < s.min) return null;
    if (s.maxAmount != null && s.amountKind == AmountKind.lumpSum) {
      final max = s == Scheme.mis ? Scheme.misJointMax : s.maxAmount!;
      if (a > Decimal.fromInt(max)) return null;
    }
    return calculate(
      CalcInput(scheme: s, amount: a, opening: opening, rate: rateOf(s)),
    );
  }

  // RD: the amount spread over 60 instalments, in multiples of ₹10.
  final rdInstalment =
      (amount / Decimal.fromInt(600)).floor().toDecimal() * Decimal.fromInt(10);
  // PPF and SSY: the amount each year, up to the yearly limit.
  final yearly = amount > Decimal.fromInt(Scheme.ppf.maxAmount!)
      ? Decimal.fromInt(Scheme.ppf.maxAmount!)
      : amount;

  List<CalcResult> ranked(Iterable<CalcResult?> rs) {
    final out = rs.whereType<CalcResult>().toList()
      ..sort((a, b) {
        final ka = a.scheme == Scheme.kvp ? 1 : 0;
        final kb = b.scheme == Scheme.kvp ? 1 : 0;
        if (ka != kb) return ka - kb;
        return b.maturityValue.compareTo(a.maturityValue);
      });
    return out;
  }

  return [
    (
      CompareGroup.fiveYears,
      ranked([
        for (final s in [Scheme.td5, Scheme.nsc, Scheme.scss, Scheme.mis])
          calc(s, amount),
        calc(Scheme.rd, rdInstalment),
        calc(Scheme.kvp, amount),
      ]),
    ),
    (
      CompareGroup.shorter,
      ranked([
        for (final s in [Scheme.td3, Scheme.td2, Scheme.td1, Scheme.sb])
          calc(s, amount),
      ]),
    ),
    (
      CompareGroup.longTerm,
      ranked([calc(Scheme.ppf, yearly), calc(Scheme.ssy, yearly)]),
    ),
  ].where((g) => g.$2.isNotEmpty).toList();
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _amount = TextEditingController(text: '100000');

  /// "I want ₹" mode: the deposit needed in each scheme to reach the amount.
  var _goal = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  List<Widget> _goalCards(BuildContext context, Decimal target) {
    final s = context.s, rates = context.rates;
    final opening = DateUtils.dateOnly(DateTime.now());
    final plans = [
      for (final sc in kGoalSchemes)
        goalPlan(sc, target, opening, rates.current(sc).rate),
    ];
    var i = 0;
    return [
      for (final kind in const [
        AmountKind.lumpSum,
        AmountKind.monthly,
        AmountKind.yearly,
      ]) ...[
        _GroupTitle(s.goalGroup(kind)),
        for (final p in plans.where((p) => p.result.scheme.amountKind == kind))
          Appear(
            key: ValueKey('goal-${p.result.scheme.code}-$target'),
            delay: Appear.step(i++, ms: 60),
            child: _GoalCard(plan: p, target: target),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final t = Theme.of(context).textTheme;
    final amount = Decimal.tryParse(_amount.text);
    final groups = amount == null || amount < Decimal.fromInt(1000)
        ? <(CompareGroup, List<CalcResult>)>[]
        : compareAll(
            amount,
            DateUtils.dateOnly(DateTime.now()),
            (sc) => rates.current(sc).rate,
          );
    final combos = amount == null || amount < Decimal.fromInt(1000)
        ? <ComboPlan>[]
        : compareCombos(
            amount,
            DateUtils.dateOnly(DateTime.now()),
            (sc) => rates.current(sc).rate,
          );
    var i = 0;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.compare,
                          style: t.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const LanguageToggle(onDark: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ModeSwitch(
                    goal: _goal,
                    onChanged: (g) => setState(() => _goal = g),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _goal ? s.goalTitle : s.compareTitle,
                    style: t.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: s.amount,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.currency_rupee_rounded,
                        color: Brand.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in const [50000, 100000, 500000, 1000000])
                        ActionChip(
                          label: Text(rupee(Decimal.fromInt(a))),
                          backgroundColor: amount == Decimal.fromInt(a)
                              ? Brand.yellow
                              : Colors.white.withValues(alpha: 0.9),
                          labelStyle: const TextStyle(
                            color: Brand.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                          onPressed: () =>
                              setState(() => _amount.text = a.toString()),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_goal && amount != null && amount >= Decimal.fromInt(1000))
                  ..._goalCards(context, amount)
                else if (!_goal)
                  for (final (g, rs) in groups) ...[
                    _GroupTitle(s.compareGroup(g)),
                    for (final r in rs)
                      Appear(
                        key: ValueKey('${r.scheme.code}-${amount ?? ''}'),
                        delay: Appear.step(i++, ms: 60),
                        child: _CompareCard(
                          result: r,
                          best: rs
                              .map((r) => r.maturityValue)
                              .reduce((a, b) => a > b ? a : b),
                          isBest:
                              g == CompareGroup.fiveYears &&
                              r == rs.firstWhere((r) => openToAll(r.scheme)),
                        ),
                      ),
                    if (g == CompareGroup.fiveYears && combos.isNotEmpty) ...[
                      _GroupTitle(s.withRdGroup),
                      for (final p in combos)
                        Appear(
                          key: ValueKey(
                            'combo-${p.base.scheme.code}-${amount ?? ''}',
                          ),
                          delay: Appear.step(i++, ms: 60),
                          child: _ComboCompareCard(
                            plan: p,
                            best: combos.first.total,
                          ),
                        ),
                    ],
                  ],
                const SizedBox(height: 8),
                if (_goal)
                  Note(s.goalNote)
                else ...[
                  Note(s.compareNote),
                  Note(
                    s.compareLongNote(
                      rupee(Decimal.fromInt(Scheme.ppf.maxAmount!)),
                    ),
                  ),
                  Note(s.issue(Issue.msscClosed, Scheme.mssc)),
                ],
                Note(s.estimateOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.result,
    required this.best,
    required this.isBest,
  });

  final CalcResult result;
  final Decimal best;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, c = r.scheme.color;
    final t = Theme.of(context).textTheme;
    final share = best == Decimal.zero
        ? 0.0
        : (r.maturityValue / best).toDouble().clamp(0.05, 1.0);
    final months = r.scheme == Scheme.kvp
        ? kvpMonths(r.input.rate)
        : r.scheme.tenureMonths;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isBest
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Brand.yellow, width: 2),
            )
          : null,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ResultScreen(result: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // On its own line so it never squeezes the name.
              if (isBest) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill(
                    s.highestReturn,
                    icon: Icons.emoji_events_rounded,
                    background: Brand.yellow,
                    foreground: Brand.ink,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  IconBadge(r.scheme.icon, c, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.schemeName(r.scheme),
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${pct(r.input.rate)}% · ${s.months(months)}',
                          style: t.bodySmall,
                        ),
                        if (!openToAll(r.scheme))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Pill(
                              r.scheme == Scheme.scss
                                  ? s.seniorsOnly
                                  : s.girlChildOnly,
                              icon: Icons.info_outline_rounded,
                              background: c.withValues(alpha: 0.12),
                              foreground: r.scheme.textColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 14,
                          color: c,
                          backgroundColor: c.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRupee(
                    r.maturityValue,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                children: [
                  Text(
                    '${s.totalInterest}: ${rupee(r.totalInterest)}',
                    style: t.bodySmall,
                  ),
                  if (r.scheme.payout != null && r.periodicPayout != null)
                    Text(
                      '${s.payout(r.scheme.payout!)}: ${rupee(r.periodicPayout!)}',
                      style: t.bodySmall,
                    ),
                  if (r.scheme.amountKind == AmountKind.yearly)
                    Text(
                      s.yearlyDepositOf(rupee(r.input.amount)),
                      style: t.bodySmall,
                    ),
                  if (r.scheme == Scheme.rd)
                    Text(
                      '${s.amountLabel(AmountKind.monthly)}: ${rupee(r.input.amount)}',
                      style: t.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// MIS / SCSS / TD 5 with the interest put into an RD.
class _ComboCompareCard extends StatelessWidget {
  const _ComboCompareCard({required this.plan, required this.best});
  final ComboPlan plan;
  final Decimal best;

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final sc = plan.base.scheme, c = sc.color;
    final share = (plan.total / best).toDouble().clamp(0.05, 1.0);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(result: plan.base),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(sc.icon, c, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.comboTitle(sc.code),
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${s.effectiveReturn(plan.effectiveRate.toStringAsFixed(2))}'
                          ' · ${s.months(plan.months)}',
                          style: t.bodySmall,
                        ),
                        if (!openToAll(sc))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Pill(
                              s.seniorsOnly,
                              icon: Icons.info_outline_rounded,
                              background: c.withValues(alpha: 0.12),
                              foreground: sc.textColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: share,
                        minHeight: 14,
                        color: c,
                        backgroundColor: c.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRupee(
                    plan.total,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${s.amountLabel(AmountKind.monthly)}: ${rupee(plan.instalment)}'
                ' · ${s.moreBy(rupee(plan.extra))}',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "I have ₹" / "I want ₹" switch on the red header.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.goal, required this.onChanged});
  final bool goal;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget side(bool g, IconData icon, String text) {
      final on = goal == g;
      return Expanded(
        child: Material(
          color: on ? Brand.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(g),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: on ? Brand.ink : Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: on ? Brand.ink : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          side(false, Icons.account_balance_wallet_rounded, s.modeHave),
          side(true, Icons.flag_rounded, s.modeWant),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.plan, required this.target});
  final GoalPlan plan;
  final Decimal target;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = plan.result, sc = r.scheme, c = sc.color;
    final t = Theme.of(context).textTheme;
    final months = sc == Scheme.kvp ? kvpMonths(r.input.rate) : sc.tenureMonths;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ResultScreen(result: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(sc.icon, c, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.schemeName(sc),
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${pct(r.input.rate)}% · ${s.months(months)}',
                          style: t.bodySmall,
                        ),
                        if (!openToAll(sc))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Pill(
                              s.girlChildOnly,
                              icon: Icons.info_outline_rounded,
                              background: c.withValues(alpha: 0.12),
                              foreground: sc.textColor(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.goalDepositLabel(sc.amountKind),
                      style: t.bodyMedium,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        rupee(r.input.amount),
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: plan.reached ? sc.textColor(context) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.reached
                    ? s.goalYouGet(rupee(r.maturityValue), s.months(months))
                    : s.goalNotReached(
                        rupee(r.input.amount),
                        rupee(r.maturityValue),
                      ),
                style: t.bodySmall?.copyWith(
                  color: plan.reached
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
