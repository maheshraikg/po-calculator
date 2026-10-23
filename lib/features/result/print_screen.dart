import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/models/result.dart';

void openPrintPreview(BuildContext context, CalcResult result) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => PrintScreen(result: result)));

/// A4 page size in PDF points; the page widget is laid out at this size.
const kA4 = Size(595, 842);

/// One-page A4 PDF holding [png] (the page picture) edge to edge.
Future<Uint8List> pagePdf(Uint8List png) async {
  final doc = pw.Document(title: 'PO Calculator', creator: 'PO Calculator');
  final img = pw.MemoryImage(png);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(img, fit: pw.BoxFit.contain),
    ),
  );
  return doc.save();
}

/// Preview of the customer printout, shared as a PDF.
class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key, required this.result});
  final CalcResult result;

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  final _page = GlobalKey();
  var _busy = false;

  Future<void> _share() async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _page.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final pdf = await pagePdf(bytes!.buffer.asUint8List());
      final name =
          'po_calculator_${widget.result.scheme.code.toLowerCase()}.pdf';
      final dir = await Directory.systemTemp.createTemp('print');
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(pdf, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: name)],
          text: s.schemeName(widget.result.scheme),
        ),
      );
    } catch (e) {
      debugPrint('PDF failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(s.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: const Color(0xFF6B6B70),
      appBar: AppBar(title: Text(s.printout)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Material(
            elevation: 6,
            child: FittedBox(
              child: RepaintBoundary(
                key: _page,
                // Always light, like paper, whatever the app theme.
                child: Theme(
                  data: buildTheme(Brightness.light),
                  child: PrintPage(result: widget.result),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _share,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(s.sharePdf),
      ),
    );
  }
}

/// The printout: an A4 page in the app's language.
class PrintPage extends StatelessWidget {
  const PrintPage({super.key, required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, sc = r.scheme;
    final t = Theme.of(context).textTheme;
    const ink = Color(0xFF1B1B1F), muted = Color(0xFF5E5E66);
    final p = sc.payout;
    final today = DateUtils.dateOnly(DateTime.now());
    Widget row(String a, String b, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(a, style: t.bodyMedium?.copyWith(color: muted)),
          ),
          Text(
            b,
            style: (big ? t.titleLarge : t.titleSmall)?.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final facts = [
      row(s.amountLabel(r.input.amountKind), rupee(r.input.amount)),
      row(s.openingDate, dmy(r.input.opening)),
      row(s.rate, '${pct(r.input.rate)}%'),
      if (p != null && r.periodicPayout != null)
        row(s.payout(p), rupee(r.periodicPayout!)),
      row(s.totalDeposit, rupee(r.totalDeposit)),
      row(s.totalInterest, rupee(r.totalInterest)),
      row(s.maturityDate, dmy(r.maturityDate)),
      row(s.maturityValue, rupee(r.maturityValue), big: true),
    ];
    return Container(
      width: kA4.width,
      height: kA4.height,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
      // Long tables shrink rather than run off the page.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: kA4.width - 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    s.appTitle,
                    style: t.titleMedium?.copyWith(
                      color: Brand.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(dmy(today), style: t.bodySmall?.copyWith(color: muted)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: sc.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(sc.icon, color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${s.schemeName(sc)} (${sc.code})',
                        style: t.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...facts,
              if (sc.payout != null) ...[
                const SizedBox(height: 6),
                Text(
                  s.payoutTableNote(rupee(r.totalDeposit)),
                  style: t.bodySmall?.copyWith(color: muted),
                ),
              ],
              if (r.schedule.length > 1) ...[
                const SizedBox(height: 14),
                Text(
                  s.yearWise,
                  style: t.titleSmall?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _PrintTable(result: r),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Brand.yellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.estimateOnly,
                  style: t.bodySmall?.copyWith(color: Brand.ink),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.notAffiliated,
                style: t.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Year-wise table, one short line per year, so even 21 years fit a page.
class _PrintTable extends StatelessWidget {
  const _PrintTable({required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, t = Theme.of(context).textTheme;
    final payout = r.scheme.payout != null;
    const line = Color(0xFFE2DEDA), ink = Color(0xFF1B1B1F);
    final head = t.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: ink,
    );
    final cell = t.bodySmall?.copyWith(color: ink, height: 1.1);
    final heads = [
      s.year,
      s.date,
      ...payout
          ? [s.interestPaid, s.paidSoFar, s.deposit]
          : [s.deposit, s.interest, s.balance],
    ];
    var paid = r.schedule.first.interest - r.schedule.first.interest;
    Widget c(String v, TextStyle? st, {bool right = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Text(v, style: st, textAlign: right ? TextAlign.right : null),
    );
    return Table(
      columnWidths: const {0: FlexColumnWidth(0.6), 1: FlexColumnWidth(1.3)},
      border: const TableBorder(horizontalInside: BorderSide(color: line)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF4F1EE)),
          children: [
            for (final (i, h) in heads.indexed) c(h, head, right: i > 1),
          ],
        ),
        for (final row in r.schedule)
          TableRow(
            children: [
              c('${row.year}', cell, right: false),
              c(dmy(row.date), cell, right: false),
              if (payout) ...[
                c(rupee(row.interest), cell),
                c(rupee(paid += row.interest), cell),
                c(rupee(row.balance), cell),
              ] else ...[
                c(rupee(row.deposit), cell),
                c(rupee(row.interest), cell),
                c(
                  rupee(row.balance),
                  cell?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
