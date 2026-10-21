import 'package:flutter/material.dart';
import 'package:grubbd_app/core/deep_links/deep_link_service.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/core/widgets/avatar_image.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/join_session_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.homeApi});

  final HomeApi? homeApi;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final HomeApi homeApi;
  String? displayName;
  String? avatar;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    homeApi = widget.homeApi ?? HomeApi();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final profileApi = ProfileApi();
      final isComplete = await profileApi.loginAndCheckProfile();
      if (!isComplete) {
        if (mounted) await Navigator.pushReplacementNamed(context, '/profile');
        return;
      }
      final homeData = await homeApi.loadHome();
      if (!mounted) return;

      setState(() {
        displayName = homeData.displayName;
        avatar = homeData.avatar;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x28000000), blurRadius: 24, offset: Offset(0, 8)),
                      ],
                    ),
                    child: buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (isLoading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF594D)),
              SizedBox(height: 16),
              Text(
                'Getting your table ready...',
                style: TextStyle(color: Color(0xFF756D69), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return buildError();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF594D), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x20FF594D), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: AvatarImage(
            avatar: avatar ?? '',
            fallbackText: displayName?.isNotEmpty == true
                ? displayName![0].toUpperCase()
                : '?',
            size: 88,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to Grubbd, $displayName! 🎉',
          key: const Key('welcome-message'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'End the "anything is fine" debate and find delicious food together.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF756D69), height: 1.35),
        ),
        const SizedBox(height: 22),

        // 3 Beginner Perks / How Grubbd Works
        _featureTile('🍔', 'Swipe with Friends', 'Match on restaurants in 60 seconds'),
        const SizedBox(height: 8),
        _featureTile('📸', 'Share Your Grubbs', 'Post dish photos, stories & vibe checks'),
        const SizedBox(height: 8),
        _featureTile('🗺️', 'Build Your Food Trail', 'Track places you love and want to try'),

        const SizedBox(height: 26),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const Key('welcome-continue-button'),
            onPressed: openHome,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF594D),
              elevation: 3,
              shadowColor: const Color(0x40FF594D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Let\'s Eat! 🚀',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureTile(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF594D).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E1A1A))),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF756D69))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildError() {
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF594D), size: 48),
        const SizedBox(height: 12),
        Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF756D69))),
        const SizedBox(height: 16),
        FilledButton(onPressed: loadProfile, child: const Text('Try again')),
      ],
    );
  }

  void openHome() {
    final roomCode = DeepLinkService.getRoomCode();

    if (roomCode != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JoinSessionScreen(initialRoomCode: roomCode),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }
}
