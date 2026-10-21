import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/collections_api.dart';
import 'package:grubbd_app/core/network/saved_places_api.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key, this.api});
  final CollectionsApi? api;

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  late final CollectionsApi api = widget.api ?? CollectionsApi();
  late Future<List<FoodCollection>> collections = api.list();
  late Future<List<SavedPlace>> savedPlaces = SavedPlacesApi().list();
  bool savedView = false;

  final starterCollections = const [
    '🍜 Late Night Cravings',
    '☕ Sunday Brunch Spots',
    '🕯️ Romantic Date Night',
    '🍰 Sweet Tooth Treats',
  ];

  Future<void> addCollection([String? prefilled]) async {
    final controller = TextEditingController(text: prefilled ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Food Collection 📁', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organize restaurants by vibe, cuisine, or occasion.',
              style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Best Ramen in City'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create Collection'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await api.create(name);
    if (mounted) {
      setState(() {
        collections = api.list();
      });
    }
  }

  Future<void> manageCollection(FoodCollection item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFFFF594D)),
                title: const Text('Rename Collection', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Collection', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'delete') {
      await api.remove(item.id);
      if (mounted) setState(() => collections = api.list());
    } else if (action == 'rename' && mounted) {
      final controller = TextEditingController(text: item.name);
      final name = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rename Collection'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
          ],
        ),
      );
      controller.dispose();
      if (name != null && name.isNotEmpty) {
        await api.update(item.id, name: name);
        if (mounted) setState(() => collections = api.list());
      }
    }
  }

  Future<void> openMap(SavedPlace place) async {
    final query = Uri.encodeComponent('${place.restaurantName}, ${place.address ?? ''}');
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(),
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Food Collections 🔖'),
      actions: [
        if (!savedView)
          IconButton(
            tooltip: 'New Collection',
            onPressed: () => addCollection(),
            icon: const Icon(Icons.add_rounded, size: 28),
          ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: const Color(0xFFFF594D),
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('My Collections 📁', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ButtonSegment(
                value: true,
                label: Text('Saved Places 📍', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
            selected: {savedView},
            onSelectionChanged: (value) => setState(() => savedView = value.first),
          ),
        ),
        Expanded(child: savedView ? _savedView() : _collectionsView()),
      ],
    ),
  );

  Widget _collectionsView() => FutureBuilder<List<FoodCollection>>(
    future: collections,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
      }
      final items = snapshot.data ?? <FoodCollection>[];

      if (items.isEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF594D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text('📁', style: TextStyle(fontSize: 42)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start Your Food Collections',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Organize your favorite restaurants or places you want to try with friends.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF756D69), fontSize: 13.5, height: 1.35),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Starter Ideas (Tap to create):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              ...starterCollections.map((title) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: Color(0xFFFF594D)),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => addCollection(title),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }

      final cardGradients = [
        [const Color(0xFFFF7043), const Color(0xFFFF8A65)],
        [const Color(0xFFFFA726), const Color(0xFFFFB74D)],
        [const Color(0xFF26A69A), const Color(0xFF4DB6AC)],
        [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
        [const Color(0xFFAB47BC), const Color(0xFFBA68C8)],
      ];

      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final grad = cardGradients[index % cardGradients.length];

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: grad[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onLongPress: () => manageCollection(item),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 20),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () => manageCollection(item),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.placeIds.length} places',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _savedView() => FutureBuilder<List<SavedPlace>>(
    future: savedPlaces,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
      }
      final items = snapshot.data ?? <SavedPlace>[];
      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('📍', style: TextStyle(fontSize: 44)),
                SizedBox(height: 14),
                Text(
                  'No Saved Places Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                ),
                SizedBox(height: 6),
                Text(
                  'When exploring restaurants in the Explore tab, tap the bookmark icon to save them here for quick access!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF756D69), height: 1.35),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final place = items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: ListTile(
              onTap: () => openMap(place),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF594D).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF594D)),
              ),
              title: Text(place.restaurantName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              subtitle: Text(place.address ?? 'Saved restaurant', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Directions',
                icon: const Icon(Icons.directions_outlined, color: Color(0xFF26A69A)),
                onPressed: () => openMap(place),
              ),
            ),
          );
        },
      );
    },
  );
}
