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
  kyc: 'https://www.indiapost.gov.in/api/documents/file/U2FsdGVkX1-9mfnUCdZFTv33OeXpoU-WoMJZ-FaPekRTdsjuZn3DeZMDziOdJlU6xtSBMWiglU8XDHYEeTRRWA',
  sb7: 'https://www.indiapost.gov.in/api/documents/file/U2FsdGVkX1-jEwh0-b1zssAtFRvIzaUd8bCWForCVTxVVN6yCfvaLgAspYw7SeumEA2Mnb04xYikn_TFX-x9Kw',
  sb7b: 'https://www.indiapost.gov.in/api/documents/file/application-form-for-pre-mature-closure-of-account-20250816-94647b',
  sb7c: 'https://www.indiapost.gov.in/api/documents/file/1002tsi0ocui0e42h3e7lt04p3a063gh0sjra3ivyj3bwi204nwv0e1xv02tlj',
  maturity:
      'https://www.nsiindia.gov.in/writereaddata/FileUploads/FORM%209.pdf',
  all: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
  nsi: 'https://www.nsiindia.gov.in/InternalPage.aspx?Id_Pk=38',
  handbooks: 'https://www.indiapost.gov.in/banking-services/handbooks',
);

/// Card with links to the official forms, opened in the phone's browser.
class OfficialForms extends StatelessWidget {
  const OfficialForms({super.key, required this.color});
  final Color color;

  Future<void> _open(BuildContext context, String url) async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: url));
      messenger.showSnackBar(SnackBar(content: Text(s.linkCopied2)));
    }
  }

  Future<void> _send(BuildContext context, String title, String url) async {
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
            onPressed: () => _open(context, url),
          ),
          IconButton(
            tooltip: s.sendForm,
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _send(context, title, url),
          ),
        ],
      ),
      onTap: () => _open(context, url),
    );
    // A web page listing many forms.
    Widget link(IconData icon, String title, String url) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(icon, color, size: 34),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => _open(context, url),
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
