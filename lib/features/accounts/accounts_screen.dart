import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../data/saved_account_repository.dart';
import '../../domain/models/account_filter.dart';
import '../../reminders/notification_service.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../result/result_screen.dart';
import 'backup_sheet.dart';

/// Whether [a] belongs under [f] on [today].
bool matchesFilter(SavedAccount a, AccountFilter f, DateTime today) {
  final m = a.result.maturityDate;
  return switch (f) {
    AccountFilter.all => true,
    AccountFilter.thisMonth => m.year == today.year && m.month == today.month,
    AccountFilter.next3Months =>
      !m.isBefore(today) &&
          m.isBefore(DateTime(today.year, today.month + 3, today.day + 1)),
    AccountFilter.matured => m.isBefore(today),
  };
}

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  var _filter = AccountFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = context.s, repo = context.accounts;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final list = repo.accounts;
          final today = DateUtils.dateOnly(DateTime.now());
          final deposited = list.fold(
            Decimal.zero,
            (a, e) => a + e.result.totalDeposit,
          );
          final atMaturity = list.fold(
            Decimal.zero,
            (a, e) => a + e.result.maturityValue,
          );
          final upcoming = list
              .where((a) => !a.result.maturityDate.isBefore(today))
              .take(3)
              .toList();
          final white = Colors.white.withValues(alpha: 0.85);
          final shown = [
            for (final a in list)
              if (matchesFilter(a, _filter, today)) a,
          ];
          if (_filter != AccountFilter.all) {
            shown.sort(
              (a, b) => a.result.maturityDate.compareTo(b.result.maturityDate),
            );
          }
          return ListView(
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
                              s.myAccounts,
                              style: t.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: s.backup,
                            onPressed: () => showBackupSheet(context),
                            icon: const Icon(
                              Icons.cloud_sync_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const LanguageToggle(onDark: true),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.portfolioAtMaturity,
                        style: t.bodyLarge?.copyWith(color: white),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedRupee(
                          atMaturity,
                          style: t.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Pill(
                            '${s.portfolio}: ${rupee(deposited)}',
                            icon: Icons.account_balance_wallet_rounded,
                            background: Brand.yellow,
                            foreground: Brand.ink,
                          ),
                          if (upcoming.isNotEmpty)
                            Pill(
                              '${upcoming.first.name} · '
                              '${s.inDays(upcoming.first.result.maturityDate.difference(today).inDays)}',
                              icon: Icons.notifications_active_rounded,
                              background: Colors.white.withValues(alpha: 0.18),
                              foreground: Colors.white,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 72,
                        color: Brand.red.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.noAccounts,
                        textAlign: TextAlign.center,
                        style: t.titleMedium,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in AccountFilter.values)
                            ChoiceChip(
                              label: Text(
                                '${s.accountFilter(f)} '
                                '(${list.where((a) => matchesFilter(a, f, today)).length})',
                              ),
                              selected: _filter == f,
                              selectedColor: Brand.yellow,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_filter != AccountFilter.all)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            s.filteredTotal(
                              shown.length,
                              rupee(
                                shown.fold(
                                  Decimal.zero,
                                  (a, e) => a + e.result.maturityValue,
                                ),
                              ),
                            ),
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (shown.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            s.noAccountsInFilter,
                            textAlign: TextAlign.center,
                            style: t.bodyLarge,
                          ),
                        ),
                      for (final (i, a) in shown.indexed)
                        Appear(
                          key: ValueKey('${a.id}-$_filter'),
                          delay: Appear.step(i, ms: 70),
                          child: _AccountCard(account: a, today: today),
                        ),
                      const SizedBox(height: 8),
                      Note(s.estimateOnly),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.today});
  final SavedAccount account;
  final DateTime today;

  Future<void> _toggle(BuildContext context, bool on) async {
    final s = context.s, repo = context.accounts;
    final messenger = ScaffoldMessenger.of(context);
    if (on && !await NotificationService.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(s.permissionDenied)));
      return;
    }
    await repo.setRemind(account.id, on);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = account.result, c = r.scheme.color;
    final t = Theme.of(context).textTheme;
    final matured = r.maturityDate.isBefore(today);
    final total = r.maturityDate.difference(r.input.opening).inDays;
    final done = today.difference(r.input.opening).inDays;
    final progress = total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);
    final daysLeft = r.maturityDate.difference(today).inDays;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(result: r, saved: true),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c, width: 6)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconBadge(r.scheme.icon, c, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: t.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${r.scheme.code} · ${pct(r.input.rate)}% · '
                            '${rupee(r.input.amount)}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: s.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => context.accounts.remove(account.id),
                    ),
                  ],
                ),
                ValueTile(s.maturityValue, rupee(r.maturityValue)),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            color: c,
                            backgroundColor: c.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pill(
                      matured ? s.matured : s.inDays(daysLeft),
                      icon: matured
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_bottom_rounded,
                      background: matured
                          ? const Color(0xFFDFF3E1)
                          : Brand.yellowSoft,
                      foreground: matured ? const Color(0xFF1B5E20) : Brand.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.percentDone((progress * 100).round())} · '
                  '${s.maturityDate}: ${dmy(r.maturityDate)}',
                  style: t.bodySmall,
                ),
                if (!matured)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          account.remind
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: c,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.reminder, style: t.titleSmall),
                              Text(s.reminderHelp, style: t.bodySmall),
                            ],
                          ),
                        ),
                        Switch(
                          value: account.remind,
                          activeThumbColor: c,
                          onChanged: (v) => _toggle(context, v),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
