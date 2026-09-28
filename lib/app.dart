import 'package:flutter/material.dart';
import 'package:grubbd_app/features/loader/loader_screen.dart';
import 'package:grubbd_app/features/profile/avatar_setup_screen.dart';
import 'package:grubbd_app/features/sessions/create_session_screen.dart';
import 'package:grubbd_app/features/sessions/join_session_screen.dart';
import 'package:grubbd_app/features/welcome/welcome_screen.dart';
import 'package:grubbd_app/features/shell/app_shell.dart';

/// Configures the application and decides which screen appears first.
class GrubbdApp extends StatelessWidget {
  const GrubbdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE94F54)),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xCCFFF8EE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LoaderScreen(),
      routes: {
        '/loader': (_) => const LoaderScreen(),
        '/profile': (_) => const AvatarSetupScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/home': (_) => const AppShell(),
        '/create-session': (_) => const CreateSessionScreen(),
        '/join-session': (_) => const JoinSessionScreen(),
      },
    );
  }
}
