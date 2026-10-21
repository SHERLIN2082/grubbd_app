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
import 'package:grubbd_app/core/network/groups_api.dart';
import 'package:grubbd_app/core/network/posts_api.dart';
import 'package:grubbd_app/core/network/collections_api.dart';
import 'package:grubbd_app/core/network/food_trail_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/profile/update_profile_screen.dart';
import 'package:grubbd_app/features/sessions/location_search_screen.dart';
import 'package:grubbd_app/features/groups/group_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index = widget.initialIndex;

  late final pages = [
    HomeScreen(onSwitchTab: (newIndex) => setState(() => index = newIndex)),
    _ExplorePage(onBackToHome: () => setState(() => index = 0)),
    _GroupsPage(onBackToHome: () => setState(() => index = 0)),
    _ProfilePage(onBackToHome: () => setState(() => index = 0)),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: index == 0 && !Navigator.canPop(context),
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else if (index != 0) {
        setState(() => index = 0);
      }
    },
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const Image(
              image: AssetImage(AppAssets.firstScreenBackground),
              fit: BoxFit.cover,
            ),
          ),
          IndexedStack(index: index, children: pages),
        ],
      ),
      bottomNavigationBar: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Squads',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    ),
  ),
);
}

// -------------------------------------------------------------
// EXPLORE PAGE
// -------------------------------------------------------------

class _ExplorePage extends StatefulWidget {
  const _ExplorePage({this.onBackToHome});
  final VoidCallback? onBackToHome;

  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  late Future<List<SwipeRestaurant>> restaurants = _loadRestaurants();
  final searchController = TextEditingController();
  List<SwipeRestaurant> typedResults = [];
  bool searching = false;
  String selectedFilter = 'All';
  bool showMap = false;
  final Set<String> savedPlaceIds = <String>{};

  final categories = const [
    ('All', '🌟 All'),
    ('Pizza', '🍕 Pizza'),
    ('Asian', '🍜 Asian'),
    ('Cafe', '☕ Cafe'),
    ('Burgers', '🍔 Burgers'),
    ('Desserts', '🍰 Desserts'),
    ('Italian', '🍝 Italian'),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialSavedPlaces();
  }

  Future<void> _loadInitialSavedPlaces() async {
    try {
      final saved = await SavedPlacesApi().list();
      if (mounted) {
        setState(() {
          savedPlaceIds.addAll(saved.map((e) => e.externalId));
        });
      }
    } catch (_) {}
  }

  Future<void> _selectFilter(String filter) async {
    setState(() {
      selectedFilter = filter;
      searching = true;
      typedResults = [];
    });
    try {
      if (filter == 'All') {
        setState(() {
          restaurants = _loadRestaurants();
          typedResults = [];
        });
      } else {
        final position = await _currentPosition();
        final results = await PlacesApi().nearby(
          latitude: position.latitude,
          longitude: position.longitude,
          category: filter.toLowerCase(),
        );
        results.sort((first, second) => (second.rating ?? 0).compareTo(first.rating ?? 0));
        if (mounted) setState(() => typedResults = results);
      }
    } catch (_) {
      if (mounted) setState(() => typedResults = []);
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on device location to explore restaurants near you.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is needed to find nearby bites.');
    }
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  Future<void> _toggleSaved(SwipeRestaurant restaurant) async {
    try {
      final saved = await SavedPlacesApi().toggle(
        externalId: restaurant.id,
        restaurantName: restaurant.name,
        address: restaurant.address,
      );
      if (mounted) {
        setState(() {
          if (saved) {
            savedPlaceIds.add(restaurant.id);
          } else {
            savedPlaceIds.remove(restaurant.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1A1A),
            content: Text(
              saved ? 'Saved "${restaurant.name}" to your places! 🔖' : 'Removed from saved places',
            ),
          ),
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
    setState(() {
      searching = true;
      typedResults = [];
    });
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
    final position = await _currentPosition();
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header
        Row(
          children: [
            AppBackButton(
              tooltip: 'Back to Home',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  widget.onBackToHome?.call();
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Explore & Discover 🌮',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Find top-rated spots or satisfy your craving',
                    style: TextStyle(color: Color(0xFF756D69), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            // Map / List view toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: IconButton(
                tooltip: showMap ? 'Switch to List' : 'Switch to Map',
                onPressed: () => setState(() => showMap = !showMap),
                icon: Icon(
                  showMap ? Icons.view_agenda_outlined : Icons.map_outlined,
                  color: const Color(0xFFFF594D),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Modern Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: TextField(
            controller: searchController,
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search sushi, tacos, burgers, cafes...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E948E)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF594D)),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        _selectFilter('All');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF594D)),
                      onPressed: () => _search(searchController.text),
                    ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Craving Categories Bar
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedFilter == cat.$1;
              return ChoiceChip(
                label: Text(
                  cat.$2,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF2C2523),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFF594D),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.08),
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) => _selectFilter(cat.$1),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        if (searching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
          ),

        // List or Map rendering
        if (!searching)
          FutureBuilder<List<SwipeRestaurant>>(
            future: restaurants,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFF594D))),
                );
              }

              if (snapshot.hasError && typedResults.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_rounded, size: 44, color: Color(0xFFFF594D)),
                      const SizedBox(height: 12),
                      const Text(
                        'Location Needed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF756D69), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() => restaurants = _loadRestaurants()),
                        child: const Text('Turn on & Retry'),
                      ),
                    ],
                  ),
                );
              }

              final displayList = typedResults.isNotEmpty ? typedResults : (snapshot.data ?? <SwipeRestaurant>[]);

              if (displayList.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: const [
                      Text('🍽️', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text(
                        'No restaurants found',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try searching for another cuisine or expanding your radius.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF756D69), fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              if (showMap) {
                return _buildRestaurantMap(displayList);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found ${displayList.length} places',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1A1A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_outlined, size: 13, color: Color(0xFFFF594D)),
                            SizedBox(width: 4),
                            Text(
                              'Tap card for Maps',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF594D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...displayList.map(_restaurantCard),
                ],
              );
            },
          ),
      ],
    ),
  );

  Widget _restaurantCard(SwipeRestaurant restaurant) {
    final isSaved = savedPlaceIds.contains(restaurant.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openMap(restaurant),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFF594D).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.restaurant_rounded, color: Color(0xFFFF594D), size: 24),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                restaurant.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            if (restaurant.rating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      restaurant.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            restaurant.address ?? 'Nearby eatery',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF756D69)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Directions',
              onPressed: () => _openMap(restaurant),
              icon: const Icon(Icons.directions_outlined, color: Color(0xFF26A69A)),
            ),
            IconButton(
              tooltip: isSaved ? 'Remove save' : 'Save place',
              onPressed: () => _toggleSaved(restaurant),
              icon: Icon(
                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isSaved ? const Color(0xFFFF594D) : const Color(0xFF756D69),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantMap(List<SwipeRestaurant> restaurants) {
    final mapped = restaurants.where((item) => item.latitude != null && item.longitude != null).toList();
    if (mapped.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: const Text('No GPS coordinates available for these places.'),
      );
    }
    final first = mapped.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 480,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(initialCenter: LatLng(first.latitude!, first.longitude!), initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.grubbd.grubbd_app',
                ),
                MarkerLayer(
                  markers: mapped
                      .map(
                        (item) => Marker(
                          point: LatLng(item.latitude!, item.longitude!),
                          width: 44,
                          height: 44,
                          child: Tooltip(
                            message: item.name,
                            waitDuration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: () => _openMap(item),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 6),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.restaurant, color: Color(0xFFFF594D), size: 22),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: Color(0xFFFF594D)),
                    SizedBox(width: 4),
                    Text(
                      'Tap pin for Google Maps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// GROUPS PAGE
// -------------------------------------------------------------

class _GroupsPage extends StatefulWidget {
  const _GroupsPage({this.onBackToHome});
  final VoidCallback? onBackToHome;

  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  late Future<List<RecentSession>> historyData = HomeApi().loadHistory();
  late Future<List<FoodGroup>> groups = GroupsApi().list();

  Future<void> _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Food Squad 🍕', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give your dining crew a fun name (e.g. Lunch Pals, Pizza Friday).',
              style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Squad Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create Squad'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await GroupsApi().create(name);
    if (mounted) {
      setState(() {
        groups = GroupsApi().list();
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      color: const Color(0xFFFF594D),
      onRefresh: () async {
        setState(() {
          historyData = HomeApi().loadHistory();
          groups = GroupsApi().list();
        });
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header
          Row(
            children: [
              AppBackButton(
                tooltip: 'Back to Home',
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    widget.onBackToHome?.call();
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Food Squads 🍕',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Plan food together without endless debates',
                      style: TextStyle(color: Color(0xFF756D69), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _createGroup,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF594D),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Explainer Card for Beginners
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x285C6BC0), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dinner Decisions Made Easy 🗳️',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Form a squad with friends or coworkers. Tap "Start Dinner Vote" to find what everyone wants!',
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/create-session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3949AB),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Start Dinner Vote 🚀', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('👥', style: TextStyle(fontSize: 46)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Active Squads Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Squads',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/groups'),
                child: const Text('Manage', style: TextStyle(color: Color(0xFFFF594D), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          FutureBuilder<List<FoodGroup>>(
            future: groups,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final squadList = snapshot.data ?? <FoodGroup>[];
              if (squadList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      const Text('🍕', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('No squads yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('Tap "New" at the top to add your first crew!', style: TextStyle(fontSize: 12, color: Color(0xFF756D69))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: squadList.map((g) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: g.id)),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEDE7F6),
                        child: const Icon(Icons.groups_rounded, color: Color(0xFF5C6BC0)),
                      ),
                      title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      subtitle: Text('${g.memberIds.length} members', style: const TextStyle(fontSize: 12, color: Color(0xFF756D69))),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF756D69)),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Decisions History
          const Text(
            'Past Group Decisions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 10),

          FutureBuilder<List<RecentSession>>(
            future: historyData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final items = (snapshot.data ?? <RecentSession>[])
                  .where((session) => session.status == 'COMPLETED')
                  .toList();

              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('No completed votes yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('When your squad finishes a swipe session, your matched winner shows up here.', style: TextStyle(fontSize: 12, color: Color(0xFF756D69))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: items.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
                      ),
                      title: Text(
                        s.restaurantName ?? 'Room ${s.roomCode}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      subtitle: Text(
                        s.members.isEmpty
                            ? 'Matched Restaurant'
                            : 'Voted by ${s.members.map((m) => m['displayName']).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF756D69)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ),
  );
}

// -------------------------------------------------------------
// PROFILE PAGE
// -------------------------------------------------------------

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({this.onBackToHome});
  final VoidCallback? onBackToHome;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  late Future<HomeData> profileData = HomeApi().loadHome();
  late Future<List<FoodPost>> posts = PostsApi().list();
  late Future<List<FoodCollection>> collections = CollectionsApi().list();
  late Future<List<FoodTrailVisit>> trail = FoodTrailApi().list();

  Future<void> _settings(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location & Privacy 📍', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Grubbd uses device GPS solely to help you and your friends locate delicious eateries and compute nearby distances. Your location data is never sold or used for tracking.',
          style: TextStyle(color: Color(0xFF756D69), height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of Grubbd?'),
        content: const Text('You will need to sign back in next time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      color: const Color(0xFFFF594D),
      onRefresh: () async {
        setState(() {
          profileData = HomeApi().loadHome();
          posts = PostsApi().list();
          collections = CollectionsApi().list();
          trail = FoodTrailApi().list();
        });
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Row(
            children: [
              AppBackButton(
                tooltip: 'Back to Home',
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    widget.onBackToHome?.call();
                  }
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Account 🥑',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your food profile, collections & preferences',
                      style: TextStyle(color: Color(0xFF756D69), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User Card
          FutureBuilder<HomeData>(
            future: profileData,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = user?.displayName ?? 'Foodie';
              final avatar = user?.avatar ?? '';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final updated = await showUpdateProfileDialog(
                              context,
                              currentName: name,
                              currentAvatar: avatar,
                            );
                            if (updated == true && mounted) {
                              setState(() {
                                profileData = HomeApi().loadHome();
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFF594D), width: 2.5),
                                ),
                                child: AvatarImage(
                                  avatar: avatar,
                                  fallbackText: name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  size: 60,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF594D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1A1A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE0D9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Grubbd Explorer 🌮',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFF594D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit Profile',
                          onPressed: () async {
                            final updated = await showUpdateProfileDialog(
                              context,
                              currentName: name,
                              currentAvatar: avatar,
                            );
                            if (updated == true && mounted) {
                              setState(() {
                                profileData = HomeApi().loadHome();
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF594D)),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Posts 📸', posts.then((p) => '${p.length}')),
                        _buildStat('Collections 🔖', collections.then((c) => '${c.length}')),
                        _buildStat('Trail 🗺️', trail.then((t) => '${t.length}')),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Food Hub Section
          const Text(
            'Your Food Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 10),

          _menuTile(
            icon: Icons.account_circle_rounded,
            color: const Color(0xFFFF594D),
            title: 'My Food Profile',
            subtitle: 'View your shared Grubbs, reviews & badges',
            onTap: () => Navigator.pushNamed(context, '/social-profile'),
          ),
          _menuTile(
            icon: Icons.badge_outlined,
            color: const Color(0xFFFF594D),
            title: 'Update Profile & Avatar',
            subtitle: 'Change your foodie nickname or character icon',
            onTap: () async {
              final user = await profileData;
              if (!context.mounted) return;
              final updated = await showUpdateProfileDialog(
                context,
                currentName: user.displayName,
                currentAvatar: user.avatar,
              );
              if (updated == true && mounted) {
                setState(() {
                  profileData = HomeApi().loadHome();
                });
              }
            },
          ),
          _menuTile(
            icon: Icons.bookmark_rounded,
            color: const Color(0xFFFF9F1C),
            title: 'My Collections',
            subtitle: 'Saved spots and dream dinner wishlists',
            onTap: () => Navigator.pushNamed(context, '/collections'),
          ),
          _menuTile(
            icon: Icons.route_rounded,
            color: const Color(0xFF26A69A),
            title: 'My Food Trail',
            subtitle: 'Interactive map and passport of visited places',
            onTap: () => Navigator.pushNamed(context, '/food-trail'),
          ),
          _menuTile(
            icon: Icons.groups_rounded,
            color: const Color(0xFF5C6BC0),
            title: 'Manage Squads',
            subtitle: 'Create or invite friends to your dining crews',
            onTap: () => Navigator.pushNamed(context, '/groups'),
          ),

          const SizedBox(height: 20),

          // Settings & Legal
          const Text(
            'Preferences & Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
          ),
          const SizedBox(height: 10),

          _menuTile(
            icon: Icons.location_on_outlined,
            color: const Color(0xFF756D69),
            title: 'Set Default City / Search Location',
            subtitle: 'Change where Grubbd looks for restaurants',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationSearchScreen(api: CreateSessionApi()),
              ),
            ),
          ),
          _menuTile(
            icon: Icons.settings_outlined,
            color: const Color(0xFF756D69),
            title: 'Location Permissions & Privacy',
            subtitle: 'How Grubbd uses GPS coordinates',
            onTap: () => _settings(context),
          ),
          _menuTile(
            icon: Icons.description_outlined,
            color: const Color(0xFF756D69),
            title: 'Terms of Service',
            subtitle: 'Read our community guidelines',
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
          _menuTile(
            icon: Icons.privacy_tip_outlined,
            color: const Color(0xFF756D69),
            title: 'Privacy Policy',
            subtitle: 'Your data security on Grubbd',
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),

          const SizedBox(height: 14),

          // Log out
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
              ),
              onTap: () => _logout(context),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );

  Widget _buildStat(String label, Future<String> future) {
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        final val = snapshot.data ?? '—';
        return Column(
          children: [
            Text(
              val,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1A1A),
              ),
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

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF756D69))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF756D69), size: 20),
      ),
    );
  }
}
