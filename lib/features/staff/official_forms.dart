import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/scope.dart';
import '../../widgets/common.dart';

/// Base address of the form PDFs kept in this repository (forms/), taken
/// unchanged from the Department of Posts SB Order No. 35/2020. India Post's
/// own document links expire, so the app never links to them directly.
const kFormsBase =
    'https://raw.githubusercontent.com/maheshraikg/po-calculator/main/forms/';

const kFormLinks = (
  aof: '${kFormsBase}sb_aof_account_opening.pdf',
  kyc: '${kFormsBase}sb_kyc.pdf',
  sb7: '${kFormsBase}sb7_withdrawal.pdf',
  sb7b: '${kFormsBase}sb7b_premature_closure.pdf',
  sb7c: '${kFormsBase}sb7c_loan_withdrawal.pdf',
  maturity: '${kFormsBase}sb7a_closure_on_maturity.pdf',
  dupPassbook: '${kFormsBase}sb41_duplicate_passbook.pdf',
  nomination: '${kFormsBase}form10_nomination.pdf',
  sbToRd: '${kFormsBase}sb83_auto_transfer_sb_to_rd.pdf',
  extension: '${kFormsBase}sb_ext1_extension.pdf',
  chequeBook: '${kFormsBase}sb_cqe4_cheque_book.pdf',
  payInSlip: '${kFormsBase}sb103_pay_in_slip.pdf',
  transfer: '${kFormsBase}form5_transfer_of_account.pdf',
  claim: '${kFormsBase}form11_deceased_claim.pdf',
  affidavit: '${kFormsBase}form13_affidavit.pdf',
  disclaimer: '${kFormsBase}form14_disclaimer.pdf',
  indemnity: '${kFormsBase}form15_indemnity.pdf',
);

/// Opens [url] in the browser; if that fails, copies it.
Future<void> openLink(BuildContext context, String url) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) {
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(SnackBar(content: Text(s.linkCopied2)));
  }
}

/// Shares [title] and [url] (e.g. to a customer on WhatsApp).
Future<void> sendLink(BuildContext context, String title, String url) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await SharePlus.instance.share(
      ShareParams(text: '$title\n$url\n— ${s.appTitle}'),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(s.shareFailed)));
  }
}

/// Card with links to the official forms, opened in the phone's browser.
class OfficialForms extends StatelessWidget {
  const OfficialForms({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    // A form PDF: tap or Download opens it in the browser, which saves it;
    // Send shares the link (e.g. to a customer on WhatsApp).
    Widget form(IconData icon, String title, String url) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(icon, color, size: 34),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: s.downloadForm,
            icon: Icon(Icons.download_rounded, color: color),
            onPressed: () => openLink(context, url),
          ),
          IconButton(
            tooltip: s.sendForm,
            icon: const Icon(Icons.share_rounded),
            onPressed: () => sendLink(context, title, url),
          ),
        ],
      ),
      onTap: () => openLink(context, url),
    );
    return SectionCard(
      icon: Icons.description_rounded,
      title: s.officialForms,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          form(Icons.note_add_rounded, s.formAof, kFormLinks.aof),
          form(Icons.badge_rounded, s.formKyc, kFormLinks.kyc),
          form(Icons.payments_rounded, s.formSb7, kFormLinks.sb7),
          form(Icons.lock_open_rounded, s.formSb7b, kFormLinks.sb7b),
          form(Icons.request_quote_rounded, s.formSb7c, kFormLinks.sb7c),
          form(
            Icons.event_available_rounded,
            s.formMaturity,
            kFormLinks.maturity,
          ),
          _Heading(s.formsServices),
          form(
            Icons.menu_book_rounded,
            s.formDupPassbook,
            kFormLinks.dupPassbook,
          ),
          form(
            Icons.person_add_alt_rounded,
            s.formNomination,
            kFormLinks.nomination,
          ),
          form(Icons.sync_alt_rounded, s.formSbToRd, kFormLinks.sbToRd),
          form(Icons.update_rounded, s.formExtension, kFormLinks.extension),
          form(Icons.receipt_rounded, s.formChequeBook, kFormLinks.chequeBook),
          form(Icons.input_rounded, s.formPayInSlip, kFormLinks.payInSlip),
          form(Icons.move_up_rounded, s.formTransfer, kFormLinks.transfer),
          Note(s.silentAccountNote, icon: Icons.bedtime_rounded),
          _Heading(s.formsClaim),
          form(Icons.assignment_ind_rounded, s.formClaim, kFormLinks.claim),
          form(Icons.gavel_rounded, s.formAffidavit, kFormLinks.affidavit),
          form(
            Icons.do_not_disturb_on_rounded,
            s.formDisclaimer,
            kFormLinks.disclaimer,
          ),
          form(
            Icons.verified_user_rounded,
            s.formIndemnity,
            kFormLinks.indemnity,
          ),
          Note(s.downloadNote, icon: Icons.download_rounded),
          Note(s.formsNote),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 2),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}
