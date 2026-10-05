import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/collections_api.dart';
import 'package:grubbd_app/core/network/saved_places_api.dart';

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

  Future<void> addCollection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('New collection'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Collection name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create'))],
    ));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await api.create(name);
    if (mounted) setState(() {
      collections = api.list();
    });
  }

  Future<void> manageCollection(FoodCollection item) async {
    final action = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Rename'), onTap: () => Navigator.pop(context, 'rename')),
      ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete'), onTap: () => Navigator.pop(context, 'delete')),
    ])));
    if (action == 'delete') {
      await api.remove(item.id);
      if (mounted) setState(() {
        collections = api.list();
      });
    } else if (action == 'rename' && mounted) {
      final controller = TextEditingController(text: item.name);
      final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Rename collection'), content: TextField(controller: controller, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save'))]));
      controller.dispose();
      if (name != null && name.isNotEmpty) {
        await api.update(item.id, name: name);
        if (mounted) setState(() {
          collections = api.list();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(),
    appBar: AppBar(title: const Text('My Collections'), actions: [if (!savedView) IconButton(onPressed: addCollection, icon: const Icon(Icons.add))]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('My Collections')), ButtonSegment(value: true, label: Text('Saved'))], selected: {savedView}, onSelectionChanged: (value) => setState(() => savedView = value.first))),
      Expanded(child: savedView ? _savedView() : _collectionsView()),
    ]),
  );

  Widget _collectionsView() => FutureBuilder<List<FoodCollection>>(
      future: collections,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('Create your first food collection.'));
        return GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: items.length, itemBuilder: (_, index) => Card(child: InkWell(onLongPress: () => manageCollection(items[index]), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.bookmark, color: Color(0xFFE94F54)), const Spacer(), Text(items[index].name, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${items[index].placeIds.length} places')])))));
      },
    );

  Widget _savedView() => FutureBuilder<List<SavedPlace>>(
    future: savedPlaces,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
      final items = snapshot.data!;
      if (items.isEmpty) return const Center(child: Text('Saved restaurants will appear here.'));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: items.length, itemBuilder: (_, index) => Card(child: ListTile(leading: const Icon(Icons.bookmark, color: Color(0xFFE94F54)), title: Text(items[index].restaurantName), subtitle: Text(items[index].address ?? 'Saved place'))));
    },
  );
}
