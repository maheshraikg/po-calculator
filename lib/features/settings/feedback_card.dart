import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import 'settings_screen.dart';

const String kDeveloperEmail = 'maheshraikg@gmail.com';

/// The mailto: link for a suggestion or bug report, with the app version
/// and language filled in.
Uri feedbackUri({
  required String subject,
  required String body,
  required String lang,
}) => Uri(
  scheme: 'mailto',
  path: kDeveloperEmail,
  query: [
    'subject=${Uri.encodeComponent(subject)}',
    'body=${Uri.encodeComponent('$body\n\n\n---\nPO Calculator $kAppVersion · $lang')}',
  ].join('&'),
);

/// Developer name and buttons to send a suggestion or report a bug.
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({super.key});

  Future<void> _mail(BuildContext context, String subject, String body) async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        feedbackUri(
          subject: subject,
          body: body,
          lang: context.settings.lang.name,
        ),
      );
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: kDeveloperEmail));
      messenger.showSnackBar(SnackBar(content: Text(s.emailCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SectionCard(
      icon: Icons.code_rounded,
      title: s.developer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBadge(Icons.person_rounded, Brand.red, size: 36),
            title: Text(
              s.developerName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const SelectableText(kDeveloperEmail),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBadge(
              Icons.lightbulb_rounded,
              Brand.red,
              size: 36,
            ),
            title: Text(s.sendSuggestion),
            subtitle: Text(s.feedbackSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                _mail(context, 'PO Calculator – suggestion', s.suggestionBody),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const IconBadge(
              Icons.bug_report_rounded,
              Brand.red,
              size: 36,
            ),
            title: Text(s.reportBug),
            subtitle: Text(s.feedbackSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                _mail(context, 'PO Calculator – bug report', s.bugBody),
          ),
        ],
      ),
    );
  }
}
