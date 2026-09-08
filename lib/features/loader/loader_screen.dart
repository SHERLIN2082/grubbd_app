import 'package:flutter/material.dart';
import 'package:grubbd_app/core/deep_links/deep_link_service.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/sessions/join_session_screen.dart';

/// Displays the picnic scene while the app prepares the next screen.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key, this.profileApi});

  final ProfileApi? profileApi;

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final ProfileApi profileApi;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    profileApi = widget.profileApi ?? ProfileApi();
    _openNextScreenAfterDelay();
  }

  Future<void> _openNextScreenAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    try {
      final hasSavedDeviceId = await profileApi.hasSavedDeviceId();
      if (!mounted) return;

      if (!hasSavedDeviceId) {
        debugPrint('[AUTH FLOW] No device ID found -> Profile Setup');
        await Navigator.pushReplacementNamed(context, '/profile');
        return;
      }

      debugPrint('[AUTH FLOW] Device ID found -> Authenticating existing user');
      await profileApi.loginAndCheckProfile();
      if (!mounted) return;

      final roomCode = DeepLinkService.getRoomCode();
      if (roomCode != null) {
        debugPrint('[DEEP LINK] Opening room $roomCode');
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => JoinSessionScreen(initialRoomCode: roomCode),
          ),
        );
        return;
      }

      debugPrint('[AUTH FLOW] Existing user authenticated -> Welcome');
      await Navigator.pushReplacementNamed(context, '/welcome');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FirstScreen(showBranding: false),
          LayoutBuilder(
            builder: (context, constraints) {
              final loaderSize = (constraints.maxWidth * 0.50).clamp(
                170.0,
                200.0,
              );
              final logoSize = constraints.maxWidth * 0.18;
              final logoCenterY =
                  constraints.maxHeight * 0.255 + logoSize * 0.46;

              return Semantics(
                label:
                    'Loading. Can\'t decide? End the food debate with Grubbd',
                child: Stack(
                  children: [
                    Positioned(
                      left: (constraints.maxWidth - loaderSize) / 2,
                      top: logoCenterY - loaderSize / 2,
                      child: CircularGrubbdLoader(
                        animation: _rotationController,
                        size: loaderSize,
                        logoSize: logoSize,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
