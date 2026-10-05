import 'package:flutter/material.dart';
import 'package:grubbd_app/features/profile/avatar_setup_screen.dart';

/// Separate entry point for editing an existing profile.
/// Initial profile setup remains owned by [AvatarSetupScreen] and its
/// existing `/profile` route.
class UpdateProfileScreen extends StatelessWidget {
  const UpdateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvatarSetupScreen(
      showBackButton: true,
      isUpdate: true,
      showBottomBar: true,
    );
  }
}
