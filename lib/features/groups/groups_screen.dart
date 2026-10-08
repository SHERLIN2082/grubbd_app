import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/groups_api.dart';
import 'package:grubbd_app/features/groups/group_detail_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> groupAction(String action, FoodGroup group) async {
    final invite = 'Join my Grubbd group "${group.name}". Group code: ${group.id}';
    if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: invite));
      return;
    }
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: invite));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite copied')));
      return;
    }
    if (action == 'leave') {
      final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text('Leave ${group.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ));
      if (confirmed == true) {
        await api.leave(group.id);
        if (mounted) setState(() { groups = api.list(); });
      }
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text('Delete ${group.name} permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ));
      if (confirmed == true) {
        await api.remove(group.id);
        if (mounted) setState(() { groups = api.list(); });
      }
    }
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
        return ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, index) => const Divider(), itemBuilder: (_, index) => ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: items[index].id))), leading: const CircleAvatar(child: Icon(Icons.groups)), title: Text(items[index].name), subtitle: Text('${items[index].memberIds.length} members'), trailing: PopupMenuButton<String>(onSelected: (value) async { if (value == 'join') { await api.join(items[index].id); if (mounted) setState(() { groups = api.list(); }); } else { await groupAction(value, items[index]); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'share', child: Text('Share invite')), PopupMenuItem(value: 'copy', child: Text('Copy invite')), PopupMenuItem(value: 'leave', child: Text('Leave group')), PopupMenuItem(value: 'delete', child: Text('Delete group'))])));
      },
    ),
  );
}
