import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post, this.api});
  final FoodPost post;
  final PostsApi? api;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final PostsApi api = widget.api ?? PostsApi();
  late Future<List<Map<String, dynamic>>> comments = api.comments(widget.post.id);
  final commentController = TextEditingController();
  late int likeCount = widget.post.likeCount;
  bool isLiked = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
    try {
      await api.toggleLike(widget.post.id);
    } catch (_) {}
  }

  Future<void> addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;
    await api.addComment(widget.post.id, text);
    commentController.clear();
    if (mounted) {
      setState(() {
        comments = api.comments(widget.post.id);
      });
    }
  }

  Future<void> openMap() async {
    final query = Uri.encodeComponent(widget.post.restaurantName);
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> sharePost() async {
    final text = 'Check out this Grubb at ${widget.post.restaurantName} on Grubbd! "${widget.post.story}"';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;

    return Scaffold(
      bottomNavigationBar: const SocialBottomBar(),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(post.restaurantName),
        actions: [
          IconButton(
            tooltip: 'Share Grubb',
            onPressed: sharePost,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Directions',
            onPressed: openMap,
            icon: const Icon(Icons.directions_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Hero Image or Banner
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Image.network(
                    post.imageUrl!,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(post.restaurantName),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            post.rating?.toStringAsFixed(1) ?? 'New',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // Author row & Restaurant
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFE0D9),
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFFFF594D),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.restaurantName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review by ${post.authorName}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF756D69)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: openMap,
                  icon: const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFFFF594D)),
                  label: const Text('Map', style: TextStyle(color: Color(0xFFFF594D), fontSize: 12, fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Review Story
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('💬', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'The Foodie Experience',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.story,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2C2523)),
                ),
              ],
            ),
          ),

          // Dishes
          if (post.dishes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionBox(
              title: 'What They Ordered 🍽️',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.dishes.map((dish) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.2)),
                    ),
                    child: Text(
                      dish,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFFF594D),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Vibes
          if (post.vibes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionBox(
              title: 'Vibe Check ✨',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.vibes.map((vibe) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      vibe,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF55504E)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Like & Social Action row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: toggleLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: const Color(0xFFFF594D),
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likeCount likes',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: sharePost,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share with friends'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Comments Section
          const Text(
            'Community Comments 💬',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 10),

          _comments(),

          const SizedBox(height: 12),

          // Add comment box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    onSubmitted: (_) => addComment(),
                    decoration: const InputDecoration(
                      hintText: 'Ask about the flavor, portion, or dessert...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E948E)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: addComment,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFFF594D)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionBox({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E1A1A))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _comments() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: comments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
          );
        }
        final list = snapshot.data ?? <Map<String, dynamic>>[];
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              children: const [
                Text('🧁', style: TextStyle(fontSize: 26)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No comments yet. Be the first to ask how the dessert was or share your recommendation!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: list.map((item) {
            final author = item['author']?.toString() ?? 'Foodie';
            final text = item['text']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFFFE0D9),
                    child: Text(
                      author.isNotEmpty ? author[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFFFF594D), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                        const SizedBox(height: 3),
                        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF2C2523), height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _imageFallback(String name) {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFFFE0D9),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_rounded, color: Color(0xFFFF594D), size: 44),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF594D))),
        ],
      ),
    );
  }
}
