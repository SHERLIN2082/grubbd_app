import 'package:flutter/material.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/groups_api.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId, this.api});
  final String groupId;
  final GroupsApi? api;
  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final GroupsApi api = widget.api ?? GroupsApi();
  late Future<FoodGroup> group = api.getOne(widget.groupId);
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 2),
    appBar: AppBar(title: const Text('Group')),
    body: FutureBuilder<FoodGroup>(future: group, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
      final item = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(20), children: [
        Text(item.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        if (item.description != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.description!)),
        const SizedBox(height: 20),
        Text('${item.memberIds.length} members', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...(item.members.isEmpty
            ? item.memberIds.map((member) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(member)))
            : item.members.map((member) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(member['displayName']?.toString() ?? 'Grubbd member')))),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/create-session'), icon: const Icon(Icons.restaurant), label: const Text('Start a group decision')),
      ]);
    }),
  );
}
