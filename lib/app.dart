import 'package:flutter/material.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/loader/loader_screen.dart';
import 'package:grubbd_app/features/profile/avatar_setup_screen.dart';

/// Configures the application and decides which screen appears first.
class GrubbdApp extends StatelessWidget {
  const GrubbdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FirstScreen(autoNavigate: true),
      routes: {
        '/loader': (_) => const LoaderScreen(),
        '/profile': (_) => const AvatarSetupScreen(),
      },
    );
  }
}
