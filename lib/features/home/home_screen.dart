import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/features/posts/post_detail_screen.dart';
import 'package:grubbd_app/features/lobby/lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.homeApi});

  final HomeApi? homeApi;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeApi homeApi;
  HomeData? homeData;
  String? errorMessage;
  bool isLoading = true;
  late Future<List<FoodPost>> posts = PostsApi().list();

  @override
  void initState() {
    super.initState();
    homeApi = widget.homeApi ?? HomeApi();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await homeApi.loadHome();
      if (!mounted) return;
      setState(() => homeData = result);
      setState(() {
        posts = PostsApi().list();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openJoinScreen() async {
    final joined = await Navigator.pushNamed(context, '/join-session');
    if (joined == true && mounted) {
      await loadHome();
    }
  }

  void showCreateMessage() {
    Navigator.pushNamed(context, '/create-session');
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadHome,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 420,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadHome, child: const Text('Try again')),
          ],
        ),
      );
    }

    final data = homeData!;
    final resumableSessions = data.recentSessions
        .where((session) => session.status == 'LOBBY' || session.status == 'ACTIVE')
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarImage(
              avatar: data.avatar,
              fallbackText: data.displayName.characters.first.toUpperCase(),
              size: 52,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Where Should We Eat?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Hungry, ${data.displayName}?',
          key: const Key('home-greeting'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const Text('Turn “anything is fine” into dinner.'),
        const SizedBox(height: 24),
        _buildSocialFeed(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-grubb'),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Create a Grubb'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            key: const Key('create-session-button'),
            onPressed: showCreateMessage,
            icon: const Icon(Icons.add),
            label: const Text('Create Session'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            key: const Key('join-session-button'),
            onPressed: openJoinScreen,
            child: const Text('Join Session'),
          ),
        ),
        if (resumableSessions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Rejoin a session',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...resumableSessions.map(
            (session) => Card(
              child: ListTile(
                leading: Icon(
                  session.status == 'ACTIVE' ? Icons.play_arrow : Icons.groups,
                ),
                title: Text(session.restaurantName ?? 'Room ${session.roomCode}'),
                subtitle: Text(session.status == 'ACTIVE' ? 'Active session' : 'Waiting in lobby'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LobbyScreen(sessionId: session.id),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialFeed() {
    return FutureBuilder<List<FoodPost>>(
      future: posts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's good?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...snapshot.data!.map(_postCard),
          ],
        );
      },
    );
  }

  Widget _postCard(FoodPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xF2FFF8EE),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Image.network(post.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(post.restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (post.story.isNotEmpty) ...[const SizedBox(height: 6), Text(post.story)],
                  if (post.rating != null) ...[const SizedBox(height: 8), Text('Rating ${post.rating!.toStringAsFixed(1)} / 5')],
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.favorite_border, size: 20), const SizedBox(width: 4), Text('${post.likeCount}'), const SizedBox(width: 14), const Icon(Icons.comment_outlined, size: 20), const SizedBox(width: 4), Text('${post.commentCount}')]),
                  if (post.vibes.isNotEmpty) Wrap(spacing: 6, children: post.vibes.map((vibe) => Chip(label: Text(vibe))).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
