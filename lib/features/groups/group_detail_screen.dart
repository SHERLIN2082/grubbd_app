import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/shell/social_bottom_bar.dart';
import 'package:grubbd_app/core/network/groups_api.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> shareInvite(FoodGroup item) async {
    final invite = 'Join my Grubbd squad "${item.name}"! Squad code: ${item.id}';
    await SharePlus.instance.share(ShareParams(text: invite));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const SocialBottomBar(selectedIndex: 2),
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Squad Details'),
      actions: [
        IconButton(
          tooltip: 'Invite Friends',
          onPressed: () async {
            final current = await group;
            shareInvite(current);
          },
          icon: const Icon(Icons.share_outlined),
        ),
      ],
    ),
    body: FutureBuilder<FoodGroup>(
      future: group,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF594D)));
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final item = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Squad Hero Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x305C6BC0), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🍕', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.memberIds.length} Squad Members',
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      item.description!,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/create-session'),
                          icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF3949AB)),
                          label: const Text(
                            'Start Dinner Vote',
                            style: TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Share Invite',
                        onPressed: () => shareInvite(item),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.person_add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Members Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Squad Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                ),
                Text(
                  '${item.memberIds.length} Total',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF756D69)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Members list
            if (item.members.isEmpty)
              ...item.memberIds.map((member) => _memberTile(member, 'Member'))
            else
              ...item.members.map((member) {
                final name = member['displayName']?.toString() ?? 'Grubbd Member';
                final isHost = member['isHost'] == true;
                return _memberTile(name, isHost ? 'Squad Leader ⭐' : 'Foodie');
              }),

            const SizedBox(height: 24),

            // Start swipe session action
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ready to eat together? 🌮',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1A1A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Grubbd will create a live session with nearby places. All squad members can swipe right on what they want!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF756D69), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/create-session'),
                      icon: const Icon(Icons.restaurant_rounded),
                      label: const Text('Start Food Vote Session 🚀'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF594D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    ),
  );

  Widget _memberTile(String name, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFE0D9),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Color(0xFFFF594D), fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
        subtitle: Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF756D69))),
      ),
    );
  }
}
