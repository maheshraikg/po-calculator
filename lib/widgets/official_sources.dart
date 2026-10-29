import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../features/staff/official_forms.dart';
import 'common.dart';

/// Official government sources for the scheme facts in the app (Google
/// Play's Misleading Claims policy asks for them). Pages on the National
/// Portal of India, which opens from anywhere: Play's reviewers could not
/// open indiapost.gov.in, nsiindia.gov.in and others from abroad.
const kOfficialSources = (
  postOffice: 'https://www.india.gov.in/category/science-it-communication/subcategory/post-telecom/details/information-on-post-office-saving-schemes-of-india-post',
  ssy: 'https://www.india.gov.in/category/benefits-social-development/subcategory/women-children/details/sukanya-samriddhi-yojna',
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
            s.sourcePostOffice,
            kOfficialSources.postOffice,
          ),
          link(Icons.girl_rounded, s.sourceSsy, kOfficialSources.ssy),
          Note(s.notGovernmentApp, icon: Icons.gpp_maybe_outlined),
        ],
      ),
    );
  }
}
