import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/scope.dart';
import '../../widgets/common.dart';

/// Official India Post pages. The two form PDFs were found on
/// www.indiapost.gov.in; if India Post moves them, the savings-scheme and
/// handbook pages still list every form.
const kFormLinks = (
  aof: 'https://www.indiapost.gov.in/api/documents/file/103o1nb2vy390fz153juo737nye34dwb0s5c13mn9n34umv02teh3g2ty34feo',
  kyc: 'https://www.indiapost.gov.in/api/documents/file/U2FsdGVkX1-9mfnUCdZFTv33OeXpoU-WoMJZ-FaPekRTdsjuZn3DeZMDziOdJlU6xtSBMWiglU8XDHYEeTRRWA',
  all: 'https://app.indiapost.gov.in/enterpriseportal/banking/post-saving-schemes',
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
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
          link(Icons.note_add_rounded, s.formAof, kFormLinks.aof),
          link(Icons.badge_rounded, s.formKyc, kFormLinks.kyc),
          link(Icons.folder_open_rounded, s.formsAll, kFormLinks.all),
          link(Icons.menu_book_rounded, s.formsHandbook, kFormLinks.handbooks),
          Note(s.formsNote),
        ],
      ),
    );
  }
}
