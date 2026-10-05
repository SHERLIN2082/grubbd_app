import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.privacy});
  final bool privacy;

  @override
  Widget build(BuildContext context) {
    final title = privacy ? 'Privacy Policy' : 'Terms & Conditions';
    final sections = privacy ? _privacySections : _termsSections;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Last updated: October 2026', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
          const SizedBox(height: 24),
          Text(privacy ? 'Your trust matters to us.' : 'A few simple guidelines help keep Grubbd welcoming for everyone.', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ...sections.map((section) => Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(section.$1, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(section.$2, style: const TextStyle(height: 1.5)),
            ]),
          )),
        ],
      ),
    );
  }

  static const _termsSections = <(String, String)>[
    ('Using Grubbd', 'Grubbd helps people discover food and make plans together. Please provide accurate information and use the app respectfully.'),
    ('Your content', 'You keep ownership of the posts, photos, and comments you share. You give Grubbd permission to display them inside the service so other people can enjoy and interact with them.'),
    ('Community safety', 'Do not post illegal, abusive, hateful, threatening, or misleading content. We may remove content or restrict accounts that harm the community.'),
    ('Food and restaurant information', 'Restaurant details, prices, availability, and ratings can change. Please confirm important details directly with the restaurant.'),
    ('Changes', 'We may improve these terms as Grubbd grows. We will show the updated date when meaningful changes are made.'),
    ('Contact', 'Questions or concerns? Contact the Grubbd team through the support channel provided in your app listing.'),
  ];

  static const _privacySections = <(String, String)>[
    ('What we collect', 'We collect account details you provide, such as your display name and avatar, along with posts, comments, saved places, groups, and session activity you choose to create.'),
    ('Location', 'We use device location only when you request nearby restaurant results or choose a location for a session. You can control location permission in your device settings.'),
    ('How we use information', 'We use information to provide discovery, social, saved-place, group, and session features; improve reliability; and protect the community.'),
    ('Sharing', 'Your public profile content, posts, comments, and group information may be visible to other Grubbd users as part of the features you use. We do not sell personal information.'),
    ('Your choices', 'You can update your profile, remove saved places, delete your posts, log out, or disable device permissions. Contact support if you need help accessing or deleting account data.'),
    ('Contact', 'For privacy questions or requests, contact the Grubbd team through the support channel provided in your app listing.'),
  ];
}
