import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/food_trail_api.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodTrailScreen extends StatefulWidget {
  const FoodTrailScreen({super.key, this.api});
  final FoodTrailApi? api;

  @override
  State<FoodTrailScreen> createState() => _FoodTrailScreenState();
}

class _FoodTrailScreenState extends State<FoodTrailScreen> {
  late final FoodTrailApi api = widget.api ?? FoodTrailApi();
  late Future<List<FoodTrailVisit>> visits = api.list();
  bool showMap = true;

  Future<void> addVisit() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Visited Place 📍', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a spot you\'ve tried to your personal food map passport.',
              style: TextStyle(fontSize: 13, color: Color(0xFF756D69)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Restaurant or Cafe Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Log Bite'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await api.add(name);
    if (mounted) {
      setState(() {
        visits = api.list();
      });
    }
  }

  Future<void> openMap(FoodTrailVisit visit) async {
    final query = Uri.encodeComponent('${visit.restaurantName}, ${visit.address ?? ''}');
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
      title: const Text('My Food Trail 🗺️'),
      actions: [
        IconButton(
          tooltip: 'Log Visited Place',
          onPressed: addVisit,
          icon: const Icon(Icons.add_location_alt_outlined, size: 26),
        ),
      ],
    ),
    body: FutureBuilder<List<FoodTrailVisit>>(
      future: visits,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
        }
        final items = snapshot.data ?? <FoodTrailVisit>[];
        final mapped = items.where((item) => item.latitude != null && item.longitude != null).toList();

        return Column(
          children: [
            // Stats & Beginner Guide Banner
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x2026A69A), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} Places Explored',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your culinary journal: every memorable bite on your map.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFFFF594D),
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Map View 🗺️', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Passport List 📋', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
                selected: {showMap},
                onSelectionChanged: (value) => setState(() => showMap = value.first),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : (showMap && mapped.isNotEmpty
                      ? _buildMap(mapped)
                      : _buildList(items)),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('🧭', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Food Trail is Empty!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log where you\'ve dined to build your personal gastronomic map and track your culinary adventures.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF756D69), height: 1.35),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: addVisit,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Log Your First Spot'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<FoodTrailVisit> mapped) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(mapped.first.latitude!, mapped.first.longitude!),
            initialZoom: 12,
          ),
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
                      child: GestureDetector(
                        onTap: () => openMap(item),
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
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<FoodTrailVisit> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final visit = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: ListTile(
            onTap: () => openMap(visit),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF26A69A)),
            ),
            title: Text(visit.restaurantName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            subtitle: Text(visit.address ?? 'Visited restaurant', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: 'Directions',
              icon: const Icon(Icons.directions_outlined, color: Color(0xFFFF594D)),
              onPressed: () => openMap(visit),
            ),
          ),
        );
      },
    );
  }
}
