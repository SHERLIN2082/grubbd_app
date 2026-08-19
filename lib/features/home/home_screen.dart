import 'package:flutter/material.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.homeApi});

  final HomeApi? homeApi;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeApi homeApi;
  HomeData? homeData;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    homeApi = widget.homeApi ?? HomeApi();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await homeApi.loadHome();
      if (!mounted) return;
      setState(() => homeData = result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openJoinScreen() async {
    final joined = await Navigator.pushNamed(context, '/join-session');
    if (joined == true && mounted) {
      await loadHome();
    }
  }

  void showCreateMessage() {
    Navigator.pushNamed(context, '/create-session');
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: loadHome,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xF2FFF8EE),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 18),
                          ],
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 420,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadHome, child: const Text('Try again')),
          ],
        ),
      );
    }

    final data = homeData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE94F54),
              foregroundColor: Colors.white,
              child: Text(data.avatar),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Where Should We Eat?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFE4B5),
              child: Text(data.avatar.characters.first),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Hungry, ${data.displayName}?',
          key: const Key('home-greeting'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const Text('Turn “anything is fine” into dinner.'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            key: const Key('create-session-button'),
            onPressed: showCreateMessage,
            icon: const Icon(Icons.add),
            label: const Text('Create Session'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE94F54),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            key: const Key('join-session-button'),
            onPressed: openJoinScreen,
            child: const Text('Join Session'),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Recent Sessions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (data.recentSessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No sessions yet. Start your first one!'),
            ),
          )
        else
          ...data.recentSessions.map(_buildSessionTile),
      ],
    );
  }

  Widget _buildSessionTile(RecentSession session) {
    final title = session.restaurantName ?? 'Room ${session.roomCode}';

    return Card(
      color: const Color(0xFFFFE4B5),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.circle, size: 12, color: Color(0xFFE94F54)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${session.status}  ${formatDate(session.createdAt)}'),
      ),
    );
  }
}
