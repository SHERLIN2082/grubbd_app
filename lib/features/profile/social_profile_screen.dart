import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/features/posts/post_detail_screen.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({super.key});
  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  late Future<HomeData> profile = HomeApi().loadHome();
  late Future<List<FoodPost>> posts = PostsApi().list();

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 3),
    appBar: AppBar(title: const Text('My Food Profile'), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/update-profile'), icon: const Icon(Icons.settings_outlined))]),
    body: FutureBuilder<HomeData>(
      future: profile,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (profileSnapshot.hasError) return Center(child: Text(profileSnapshot.error.toString()));
        final user = profileSnapshot.data!;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: AvatarImage(avatar: user.avatar, fallbackText: user.displayName.characters.first.toUpperCase(), size: 86)),
          const SizedBox(height: 10),
          Center(child: Text(user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('Posts', '—'), _stat('Collections', '—'), _stat('Trail', '—'),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/collections'), icon: const Icon(Icons.collections_bookmark_outlined), label: const Text('Collections'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/food-trail'), icon: const Icon(Icons.route_outlined), label: const Text('Food Trail'))),
          ]),
          const SizedBox(height: 20),
          const Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          FutureBuilder<List<FoodPost>>(future: posts, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (snapshot.hasError || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.only(top: 16), child: Text('Your food posts will appear here.'));
            return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: snapshot.data!.length, itemBuilder: (_, index) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: snapshot.data![index]))), child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.restaurant, color: Color(0xFFE94F54)), const Spacer(), Text(snapshot.data![index].restaurantName, style: const TextStyle(fontWeight: FontWeight.w700)), Text(snapshot.data![index].story, maxLines: 2, overflow: TextOverflow.ellipsis)])))));
          }),
        ]);
      },
    ),
  );

  Widget _stat(String label, String value) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(label)]);
}
