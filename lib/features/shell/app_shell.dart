import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:grubbd_app/features/home/home_screen.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/places_api.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/core/network/saved_places_api.dart';
import 'package:grubbd_app/features/sessions/location_search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index = widget.initialIndex;
  final pages = const [
    HomeScreen(),
    _ExplorePage(),
    _GroupsPage(),
    _ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const Image(
            image: AssetImage(AppAssets.firstScreenBackground),
            fit: BoxFit.cover,
          ),
        ),
        IndexedStack(index: index, children: pages),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: const Color(0xDDFFF8EE),
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      height: 68,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class _ExplorePage extends StatefulWidget {
  const _ExplorePage();
  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  late Future<List<SwipeRestaurant>> restaurants = _loadRestaurants();
  final searchController = TextEditingController();
  List<Map<String, String>> searchResults = [];
  List<SwipeRestaurant> typedResults = [];
  bool searching = false;

  Future<void> _toggleSaved(SwipeRestaurant restaurant) async {
    try {
      final saved = await SavedPlacesApi().toggle(
        externalId: restaurant.id,
        restaurantName: restaurant.name,
        address: restaurant.address,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saved ? 'Saved to your places' : 'Removed from saved places')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) return;
    setState(() => searching = true);
    try {
      final results = await PlacesApi().searchRestaurants(query.trim());
      if (mounted) setState(() => typedResults = results);
    } catch (_) {
      if (mounted) setState(() => typedResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _openMap(SwipeRestaurant restaurant) async {
    final query = Uri.encodeComponent(
      '${restaurant.name}, ${restaurant.address ?? ''}',
    );
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<List<SwipeRestaurant>> _loadRestaurants() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on location to find restaurants');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is needed');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final preference = await ProfileApi().getFoodPreference();
    return PlacesApi().nearby(
      latitude: position.latitude,
      longitude: position.longitude,
      foodPreference: preference,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              'Explore',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Find somewhere delicious for your group.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search restaurants or cuisines',
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          children: [
            Chip(label: Text('All')),
            Chip(label: Text('Asian')),
            Chip(label: Text('Italian')),
            Chip(label: Text('Café')),
            Chip(label: Text('Desserts')),
          ],
        ),
        const SizedBox(height: 16),
        if (searching) const LinearProgressIndicator(),
        if (typedResults.isNotEmpty)
          ...typedResults.map(
            (restaurant) => Card(
              child: ListTile(
                onTap: () => _openMap(restaurant),
                leading: const Icon(Icons.restaurant, color: Color(0xFFE94F54)),
                title: Text(restaurant.name),
                subtitle: Text('  •  '),
                trailing: IconButton(
                  tooltip: 'Save place',
                  onPressed: () => _toggleSaved(restaurant),
                  icon: const Icon(Icons.bookmark_border),
                ),
              ),
            ),
          ),
        const SizedBox(height: 28),
        const Text(
          'Trending near you',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<SwipeRestaurant>>(
          future: restaurants,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() {
                          restaurants = _loadRestaurants();
                        }),
                    child: const Text('Try again'),
                  ),
                ],
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (restaurant) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _openMap(restaurant),
                        leading: const Icon(
                          Icons.restaurant,
                          color: Color(0xFFE94F54),
                        ),
                        title: Text(
                          restaurant.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${restaurant.rating?.toStringAsFixed(1) ?? 'New'}  â€¢  ${restaurant.address ?? 'Nearby'}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Save place',
                          onPressed: () => _toggleSaved(restaurant),
                          icon: const Icon(Icons.bookmark_border),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _GroupsPage extends StatefulWidget {
  const _GroupsPage();
  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  late Future<List<RecentSession>> data = HomeApi().loadHistory();

  Future<void> _showCreateOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: const Text('Create a Grubb'),
              subtitle: const Text('Share a food experience'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(this.context, '/create-grubb');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Create Session'),
              subtitle: const Text('Decide where your group should eat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(this.context, '/create-session');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Groups',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: _showCreateOptions,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Plan food with your people.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Open my groups'),
            subtitle: const Text('Create and manage your food groups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/groups'),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Your Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<List<RecentSession>>(
          future: data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text(
                'Could not load your sessions. Pull to refresh.',
              );
            }
            final items = snapshot.data!
                .where((session) => session.status == 'COMPLETED')
                .toList();
            if (items.isEmpty) {
              return const Text(
                'No sessions yet. Create one and invite your friends.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                ...items.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(s.restaurantName ?? 'Room ${s.roomCode}'),
                    subtitle: Text(
                      s.members.isEmpty
                          ? s.status
                          : '${s.status} · ${s.members.map((member) => member['displayName']).join(', ')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  Future<void> _settings(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: const Text(
          'Grubbd uses your device location only when you search for nearby restaurants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your profile and preferences',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Your Grubbd profile'),
            subtitle: const Text('Update your name or avatar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('View food profile'),
          subtitle: const Text('Posts, collections, and trail'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/social-profile'),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Location'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationSearchScreen(api: CreateSessionApi()),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Groups'),
          subtitle: const Text('Plan food with your people'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/groups'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.collections_bookmark_outlined),
          title: const Text('My Collections'),
          subtitle: const Text('Saved places and food ideas'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/collections'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.route_outlined),
          title: const Text('Food Trail'),
          subtitle: const Text('Places you have visited'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/food-trail'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _settings(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms & Conditions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/terms'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/privacy'),
        ),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: Color(0xFFE94F54)),
          title: const Text('Logout'),
          onTap: () => _logout(context),
        ),
      ],
    ),
  );
}
