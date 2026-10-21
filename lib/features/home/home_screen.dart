import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';
import 'package:grubbd_app/features/posts/post_detail_screen.dart';
import 'package:grubbd_app/features/lobby/lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.homeApi, this.onSwitchTab});

  final HomeApi? homeApi;
  final void Function(int index)? onSwitchTab;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFF594D),
          onRefresh: loadHome,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildContent(),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF594D)),
              SizedBox(height: 16),
              Text(
                'Warming up the kitchen...',
                style: TextStyle(color: Color(0xFF756D69), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 420,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFFF594D)),
                  const SizedBox(height: 14),
                  Text(
                    'Oops! Could not connect',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF756D69)),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: loadHome,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
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
        // Top App Bar row with user avatar & logo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                if (widget.onSwitchTab != null) {
                  widget.onSwitchTab!(3);
                } else {
                  Navigator.pushNamed(context, '/profile-tab');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF594D), width: 2),
                ),
                child: AvatarImage(
                  avatar: data.avatar,
                  fallbackText: data.displayName.characters.first.toUpperCase(),
                  size: 42,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0E000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_very_satisfied, color: Color(0xFFFF594D), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Save the spot. Share the vibe.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1A1A)),
                  ),
                ],
              ),
            ),
            const GrubbdLogo(width: 44),
          ],
        ),

        const SizedBox(height: 24),

        // Personalized Energetic Greeting
        Text(
          'Hungry, ${data.displayName}? 🍕',
          key: const Key('home-greeting'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Turn "I don\'t know, anything is fine" into your best meal yet.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF756D69),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 20),

        // Reusable session alert banner if active
        if (resumableSessions.isNotEmpty) ...[
          _buildRejoinBanner(resumableSessions.first),
          const SizedBox(height: 16),
        ],

        // Hero Card: The Group Decision Swipe
        _buildHeroSessionCard(),

        const SizedBox(height: 16),

        // Share a Grubb Banner
        _buildShareGrubbCard(),

        const SizedBox(height: 24),

        // 4 High-Energy Quick Action Cards
        const Text(
          'Explore Grubbd',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
        ),
        const SizedBox(height: 12),
        _buildQuickActions(),

        const SizedBox(height: 28),

        // Social Feed: What's good
        _buildSocialFeed(),
      ],
    );
  }

  Widget _buildRejoinBanner(RecentSession session) {
    final isActive = session.status == 'ACTIVE';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF9F1C), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x12FF9F1C), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFF9F1C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Active Food Vote! 🔥' : 'Waiting in Lobby ⏳',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFE65100)),
                ),
                Text(
                  'Room ${session.roomCode} · ${session.restaurantName ?? 'Decision in progress'}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF756D69)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LobbyScreen(sessionId: session.id),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9F1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Rejoin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSessionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF594D), Color(0xFFFF7E5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38FF594D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Opacity(
              opacity: 0.15,
              child: const Icon(Icons.lunch_dining, size: 140, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎯', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'GROUP DECISION DUEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Can\'t agree where to eat?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Swipe on nearby restaurants with friends. When everyone likes the same place, it\'s a match!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        key: const Key('create-session-button'),
                        onPressed: showCreateMessage,
                        icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF594D), size: 22),
                        label: const Text(
                          'Start Swiping',
                          style: TextStyle(
                            color: Color(0xFFFF594D),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        key: const Key('join-session-button'),
                        onPressed: openJoinScreen,
                        icon: const Icon(Icons.vpn_key_outlined, color: Colors.white, size: 18),
                        label: const Text(
                          'Join Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.6),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareGrubbCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9F1C), Color(0xFFFFBE59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snap & Post a Grubb 📸',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Share your dish, rate the vibe & inspire others!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF756D69)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/create-grubb'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF594D),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      ('Explore', 'Nearby gems', Icons.explore_rounded, const Color(0xFF26A69A), '/explore'),
      ('Squads', 'Group dinners', Icons.groups_rounded, const Color(0xFF5C6BC0), '/groups-tab'),
      ('Collections', 'Saved cravings', Icons.bookmark_rounded, const Color(0xFFFF7043), '/collections'),
      ('Food Trail', 'Visited bites', Icons.route_rounded, const Color(0xFF8D6E63), '/food-trail'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.85,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (action.$5 == '/explore' && widget.onSwitchTab != null) {
                widget.onSwitchTab!(1);
              } else if (action.$5 == '/groups-tab' && widget.onSwitchTab != null) {
                widget.onSwitchTab!(2);
              } else {
                Navigator.pushNamed(context, action.$5);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: action.$4.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.$3, color: action.$4, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF1E1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF756D69),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialFeed() {
    return FutureBuilder<List<FoodPost>>(
      future: posts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
          );
        }

        final feed = snapshot.data ?? <FoodPost>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'What\'s Good in Town? 🍜',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1A1A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cravings & vibes shared by real foodies',
                        style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/explore'),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Color(0xFFFF594D), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (feed.isEmpty)
              _buildEmptyFeedState()
            else
              ...feed.map(_postCard),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFeedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF594D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🌮', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Food Posts Yet!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the pioneer in your squad. Snap your meal, rate the vibe, and put your favorite bite on the map!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Color(0xFF756D69), height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/create-grubb'),
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: const Text('Share Your First Grubb'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF594D),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(FoodPost post) {
    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
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
            // Author row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFE0D9),
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFFFF594D),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const Text(
                          'posted a Grubb',
                          style: TextStyle(color: Color(0xFF756D69), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (post.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB300), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                          const SizedBox(width: 3),
                          Text(
                            post.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Image section with fallback
            if (hasImage)
              Stack(
                children: [
                  Image.network(
                    post.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(post.restaurantName),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          post.restaurantName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFFFF594D), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      post.restaurantName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),

            // Post content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.story.isNotEmpty) ...[
                    Text(
                      '"${post.story}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: Color(0xFF2C2523),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dishes
                  if (post.dishes.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: post.dishes.map((dish) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🍽️', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                dish,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF594D),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Vibes
                  if (post.vibes.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: post.vibes.map((vibe) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vibe,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF55504E),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 18),

                  // Actions row
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await PostsApi().toggleLike(post.id);
                          loadHome();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_border, color: Color(0xFFFF594D), size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likeCount}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, color: Color(0xFF756D69), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF756D69),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF594D).withOpacity(0.9),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFF594D)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(String name) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFE0D9), const Color(0xFFFFF0EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_rounded, size: 40, color: Color(0xFFFF594D)),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFF594D)),
            ),
          ],
        ),
      ),
    );
  }
}
