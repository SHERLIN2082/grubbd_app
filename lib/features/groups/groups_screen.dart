import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/groups_api.dart';
import 'package:grubbd_app/features/groups/group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.api});
  final GroupsApi? api;
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late final GroupsApi api = widget.api ?? GroupsApi();
  late Future<List<FoodGroup>> groups = api.list();

  Future<void> addGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('Create group'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Group name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create'))],
    ));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await api.create(name);
    if (mounted) setState(() {
      groups = api.list();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 2),
    appBar: AppBar(title: const Text('Groups'), actions: [IconButton(onPressed: addGroup, icon: const Icon(Icons.add))]),
    body: FutureBuilder<List<FoodGroup>>(
      future: groups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
        final items = snapshot.data!;
        if (items.isEmpty) return const Center(child: Text('Create a group to decide where to eat together.'));
        return ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, index) => const Divider(), itemBuilder: (_, index) => ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: items[index].id))), leading: const CircleAvatar(child: Icon(Icons.groups)), title: Text(items[index].name), subtitle: Text('${items[index].memberIds.length} members'), trailing: PopupMenuButton<String>(onSelected: (value) async { if (value == 'join') { await api.join(items[index].id); if (mounted) setState(() { groups = api.list(); }); } else if (value == 'decide' && mounted) { Navigator.pushNamed(context, '/create-session'); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'join', child: Text('Join group')), PopupMenuItem(value: 'decide', child: Text('Start a group decision'))])));
      },
    ),
  );
}
