import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
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
              'Give your squad a memorable name (e.g. Lunch Crew, Taco Tuesday).',
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
    await api.create(name);
    if (mounted) {
      setState(() {
        groups = api.list();
      });
    }
  }

  Future<void> groupAction(String action, FoodGroup group) async {
    final invite = 'Join my Grubbd food squad "${group.name}"! Squad code: ${group.id}';
    if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: invite));
      return;
    }
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: invite));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E1A1A),
            content: Text('Squad invite link copied to clipboard! 📋'),
          ),
        );
      }
      return;
    }
    if (action == 'leave') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Leave squad?'),
          content: Text('Are you sure you want to leave ${group.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF594D)),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await api.leave(group.id);
        if (mounted) setState(() { groups = api.list(); });
      }
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete squad?'),
          content: Text('Delete "${group.name}" permanently? All members will be removed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await api.remove(group.id);
        if (mounted) setState(() { groups = api.list(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 2),
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Food Squads 🍕'),
      actions: [
        IconButton(
          tooltip: 'New Squad',
          onPressed: addGroup,
          icon: const Icon(Icons.add_rounded, size: 28),
        ),
      ],
    ),
    body: FutureBuilder<List<FoodGroup>>(
      future: groups,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
        }
        final items = snapshot.data ?? <FoodGroup>[];

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('👥', style: TextStyle(fontSize: 42)),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Food Squads Yet!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E1A1A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Never spend 45 minutes arguing in the WhatsApp chat again. Form a crew, share an invite link, and settle dinner in 60 seconds with group swiping!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF756D69), height: 1.35),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: addGroup,
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('Create Your First Squad'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF5C6BC0).withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Text('💡', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap any squad to view members or launch a 60-second group food vote.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF311B92), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((group) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFEDE7F6),
                    child: const Icon(Icons.groups_rounded, color: Color(0xFF5C6BC0), size: 26),
                  ),
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  subtitle: Text('${group.memberIds.length} hungry members', style: const TextStyle(fontSize: 12.5, color: Color(0xFF756D69))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Share Invite',
                        icon: const Icon(Icons.share_outlined, color: Color(0xFF5C6BC0)),
                        onPressed: () => groupAction('share', group),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF756D69)),
                        onSelected: (value) async {
                          if (value == 'join') {
                            await api.join(group.id);
                            if (mounted) setState(() { groups = api.list(); });
                          } else {
                            await groupAction(value, group);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'share', child: Text('Share Invite Link 🔗')),
                          PopupMenuItem(value: 'copy', child: Text('Copy Squad Code 📋')),
                          PopupMenuItem(value: 'leave', child: Text('Leave Squad')),
                          PopupMenuItem(value: 'delete', child: Text('Delete Squad', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    ),
  );
}
