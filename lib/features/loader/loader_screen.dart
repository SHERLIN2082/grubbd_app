import 'package:flutter/material.dart';

import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _openNextScreenAfterDelay();
  }

  Future<void> _openNextScreenAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    // Temporarily open avatar setup without checking the device or logging in.
    await Navigator.pushReplacementNamed(context, '/profile');
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
          Center(
            child: Semantics(
              label: 'Loading Grubbd',
              child: CircularGrubbdLoader(
                animation: _rotationController,
                size: 190,
                logoSize: 68,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
