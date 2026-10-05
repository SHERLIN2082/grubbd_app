import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/food_trail_api.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Add a place'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Restaurant name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add'))]));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await api.add(name);
    if (mounted) setState(() {
      visits = api.list();
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(),
    appBar: AppBar(title: const Text('My Food Trail'), actions: [IconButton(onPressed: addVisit, icon: const Icon(Icons.add))]),
    body: FutureBuilder<List<FoodTrailVisit>>(future: visits, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
      final items = snapshot.data!;
      if (items.isEmpty) return const Center(child: Text('Your visited places will appear here.'));
      final mapped = items.where((item) => item.latitude != null && item.longitude != null).toList();
      return Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Map'), icon: Icon(Icons.map_outlined)), ButtonSegment(value: false, label: Text('List'), icon: Icon(Icons.list))], selected: {showMap}, onSelectionChanged: (value) => setState(() => showMap = value.first))),
        Expanded(child: showMap && mapped.isNotEmpty ? FlutterMap(options: MapOptions(initialCenter: LatLng(mapped.first.latitude!, mapped.first.longitude!), initialZoom: 11), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.grubbd.grubbd_app'), MarkerLayer(markers: mapped.map((item) => Marker(point: LatLng(item.latitude!, item.longitude!), width: 44, height: 44, child: const Icon(Icons.location_on, color: Color(0xFFE94F54), size: 38))).toList())]) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, index) => Card(child: ListTile(leading: const Icon(Icons.location_on, color: Color(0xFFE94F54)), title: Text(items[index].restaurantName), subtitle: Text(items[index].address ?? 'Visited place'))))),
      ]);
    }),
  );
}
