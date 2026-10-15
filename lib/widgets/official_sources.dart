import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../features/staff/official_forms.dart';
import 'common.dart';

/// Official government sources for the scheme rules, rates and tax facts
/// in the app (Google Play's Misleading Claims policy asks for them).
const kOfficialSources = (
  indiaPost: 'https://www.indiapost.gov.in',
  nsi: 'https://www.nsiindia.gov.in',
  rates: 'https://dea.gov.in',
  incomeTax: 'https://www.incometaxindia.gov.in',
);

/// Disclaimer and tappable links to the official sources.
class OfficialSourcesCard extends StatelessWidget {
  const OfficialSourcesCard({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = color ?? Theme.of(context).colorScheme.primary;
    Widget link(IconData icon, String title, String url) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(icon, c, size: 34),
      title: Text(title),
      subtitle: Text(Uri.parse(url).host),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => openLink(context, url),
    );
    return SectionCard(
      icon: Icons.verified_rounded,
      title: s.officialSources,
      color: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(s.sourcesIntro),
          const SizedBox(height: 4),
          link(
            Icons.local_post_office_rounded,
            s.sourceIndiaPost,
            kOfficialSources.indiaPost,
          ),
          link(Icons.savings_rounded, s.sourceNsi, kOfficialSources.nsi),
          link(Icons.percent_rounded, s.sourceRates, kOfficialSources.rates),
          link(
            Icons.receipt_long_rounded,
            s.sourceIncomeTax,
            kOfficialSources.incomeTax,
          ),
          Note(s.notGovernmentApp, icon: Icons.gpp_maybe_outlined),
        ],
      ),
    );
  }
}
