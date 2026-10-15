import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/scope.dart';
import '../../widgets/common.dart';

/// Official form PDFs found on www.indiapost.gov.in (Department of Posts)
/// and www.nsiindia.gov.in (National Savings Institute, Ministry of
/// Finance). If a PDF moves, the two "all forms" pages still list them.
const kFormLinks = (
  aof: 'https://www.indiapost.gov.in/api/documents/file/103o1nb2vy390fz153juo737nye34dwb0s5c13mn9n34umv02teh3g2ty34feo',
  kyc: 'https://www.indiapost.gov.in/api/documents/file/kyc-form-annexure-ii-20250816-3c618a',
  sb7: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
  sb7b: 'https://www.indiapost.gov.in/api/documents/file/application-form-for-pre-mature-closure-of-account-20250816-94647b',
  sb7c: 'https://www.indiapost.gov.in/api/documents/file/1002tsi0ocui0e42h3e7lt04p3a063gh0sjra3ivyj3bwi204nwv0e1xv02tlj',
  maturity:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%209.pdf',
  dupPassbook: 'https://www.indiapost.gov.in/api/documents/file/1034vgz2oxl701hcp3cu870hc7a03a4g0s5cb3fmtn3e8eo04nkp0e32834uon',
  nomination:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%2010.pdf',
  sbToRd: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
  extension: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
  chequeBook: 'https://www.indiapost.gov.in/api/documents/file/application-for-fresh-cheque-book-20250816-dde18d',
  claim: 'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%2011.pdf',
  affidavit:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%2013.pdf',
  disclaimer:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%2014.pdf',
  indemnity:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%2015.pdf',
  all: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
  nsi: 'https://www.nsiindia.gov.in/InternalPage.aspx?Id_Pk=38',
  handbooks: 'https://www.indiapost.gov.in/banking-services/handbooks',
  // Replaces Form 15G/15H from 1 April 2026 (Income-tax Act, 2025).
  form121: 'https://www.incometaxindia.gov.in/w/form-no.-121',
  // SB-7, SB-83 and SB-EXT1 have no permanent file address on India Post
  // (the site hands out expiring links), so they open the forms page (all).
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
      subtitle: url == kFormLinks.all ? Text(s.onFormsPage) : null,
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
    // A web page listing many forms.
    Widget link(IconData icon, String title, String url) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(icon, color, size: 34),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
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
          form(Icons.receipt_long_rounded, s.formNo121, kFormLinks.form121),
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
          _Heading(s.formsMore),
          link(Icons.folder_open_rounded, s.formsAll, kFormLinks.all),
          link(Icons.account_balance_rounded, s.formsNsi, kFormLinks.nsi),
          link(Icons.menu_book_rounded, s.formsHandbook, kFormLinks.handbooks),
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
