import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:grubbd_app/core/network/collections_api.dart';
import 'package:grubbd_app/core/network/food_trail_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/features/posts/post_detail_screen.dart';
import 'package:grubbd_app/features/profile/update_profile_screen.dart';

class SocialProfileScreen extends StatefulWidget {
  const SocialProfileScreen({super.key});
  @override
  State<SocialProfileScreen> createState() => _SocialProfileScreenState();
}

class _SocialProfileScreenState extends State<SocialProfileScreen> {
  late Future<HomeData> profile = HomeApi().loadHome();
  late Future<List<FoodPost>> posts = PostsApi().list();
  late Future<List<FoodCollection>> collections = CollectionsApi().list();
  late Future<List<FoodTrailVisit>> trail = FoodTrailApi().list();

  Future<void> _openEditProfileDialog(String? name, String? avatar) async {
    final updated = await showUpdateProfileDialog(
      context,
      currentName: name,
      currentAvatar: avatar,
    );
    if (updated == true && mounted) {
      setState(() {
        profile = HomeApi().loadHome();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 3),
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('My Food Profile 🥑'),
      actions: [
        IconButton(
          tooltip: 'Edit Profile',
          onPressed: () async {
            final user = await profile;
            if (context.mounted) {
              _openEditProfileDialog(user.displayName, user.avatar);
            }
          },
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
    body: FutureBuilder<HomeData>(
      future: profile,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
        }
        if (profileSnapshot.hasError) {
          return Center(child: Text(profileSnapshot.error.toString()));
        }
        final user = profileSnapshot.data!;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Card Header
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _openEditProfileDialog(user.displayName, user.avatar),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFF594D), width: 3),
                          ),
                          child: AvatarImage(
                            avatar: user.avatar,
                            fallbackText: user.displayName.characters.first.toUpperCase(),
                            size: 80,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF594D),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Local Food Enthusiast 🌮',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFF594D)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openEditProfileDialog(user.displayName, user.avatar),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EFEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 13, color: Color(0xFF555555)),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Real Dynamic Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('Posts 📸', posts.then((p) => '${p.length}')),
                      _stat('Collections 🔖', collections.then((c) => '${c.length}')),
                      _stat('Trail 🗺️', trail.then((t) => '${t.length}')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Quick Hub Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/collections'),
                    icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF9F1C), size: 20),
                    label: const Text('Collections', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.black.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/food-trail'),
                    icon: const Icon(Icons.route_rounded, color: Color(0xFF26A69A), size: 20),
                    label: const Text('Food Trail', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.black.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // My Posts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Grubbs 📸',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/create-grubb'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Grubb', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Posts Grid
            FutureBuilder<List<FoodPost>>(
              future: posts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
                  );
                }
                final userPosts = snapshot.data ?? <FoodPost>[];

                if (userPosts.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        const Text('📸', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        const Text(
                          'No food posts yet!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Snap your next delicious meal to inspire your friends and build your profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => Navigator.pushNamed(context, '/create-grubb'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
                          child: const Text('Post a Grubb ✨'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: userPosts.length,
                  itemBuilder: (context, index) {
                    final post = userPosts[index];
                    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasImage)
                              Image.network(
                                post.imageUrl!,
                                height: 95,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 95,
                                  color: const Color(0xFFFFE0D9),
                                  child: const Center(
                                    child: Icon(Icons.restaurant, color: Color(0xFFFF594D)),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 95,
                                width: double.infinity,
                                color: const Color(0xFFFFE0D9),
                                child: const Center(
                                  child: Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF594D), size: 32),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.restaurantName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    post.story,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF756D69)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    ),
  );

  Widget _stat(String label, Future<String> countFuture) {
    return FutureBuilder<String>(
      future: countFuture,
      builder: (context, snapshot) {
        final val = snapshot.data ?? '—';
        return Column(
          children: [
            Text(
              val,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF756D69), fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}
