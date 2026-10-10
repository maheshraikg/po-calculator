import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/scope.dart';
import '../domain/models/result.dart';

/// Year-wise table that always fits the card width (no sideways scroll)
/// and grows with large phone fonts. For payout schemes (MIS, SCSS, TD) the
/// interest goes to the savings account, so it shows interest paid, the
/// total paid so far and the deposit, which stays the same.
class ScheduleTable extends StatelessWidget {
  const ScheduleTable({super.key, required this.rows, this.payout = false});
  final List<ScheduleRow> rows;
  final bool payout;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final head = t.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    final body = t.bodySmall?.copyWith(fontSize: 13);
    Widget num(String v, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(v, style: style ?? body, maxLines: 1),
        ),
      ),
    );
    Widget label(String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      child: Text(v, style: head, textAlign: TextAlign.right),
    );
    var paid = Decimal.zero;
    final heads = payout
        ? [s.interestPaid, s.paidSoFar, s.deposit]
        : [s.deposit, s.interest, s.balance];
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.15)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
              child: Text(s.year, style: head),
            ),
            for (final h in heads) label(h),
          ],
        ),
        for (final r in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.year}', style: head),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(dmy(r.date), style: body, maxLines: 1),
                    ),
                  ],
                ),
              ),
              if (payout) ...[
                num(rupee(r.interest)),
                num(rupee(paid += r.interest)),
                num(rupee(r.balance)),
              ] else ...[
                num(rupee(r.deposit)),
                num(rupee(r.interest)),
                num(
                  rupee(r.balance),
                  style: body?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Two-column table (label, amount).
class PairTable extends StatelessWidget {
  const PairTable({
    super.key,
    required this.head1,
    required this.head2,
    required this.rows,
  });
  final String head1;
  final String head2;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => _FullWidth(
    child: DataTable(
      columnSpacing: 24,
      horizontalMargin: 8,
      headingRowHeight: 44,
      columns: [
        DataColumn(label: Text(head1)),
        DataColumn(label: Text(head2), numeric: true),
      ],
      rows: [
        for (final (a, b) in rows)
          DataRow(cells: [DataCell(Text(a)), DataCell(Text(b))]),
      ],
    ),
  );
}

/// Scrolls sideways when the table is wider than the card, and otherwise
/// stretches it to the card's full width.
class _FullWidth extends StatelessWidget {
  const _FullWidth({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: c.maxWidth),
        child: child,
      ),
    ),
  );
}
