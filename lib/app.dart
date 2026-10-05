import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grubbd_app/features/loader/loader_screen.dart';
import 'package:grubbd_app/features/profile/avatar_setup_screen.dart';
import 'package:grubbd_app/features/profile/update_profile_screen.dart';
import 'package:grubbd_app/features/sessions/create_session_screen.dart';
import 'package:grubbd_app/features/sessions/join_session_screen.dart';
import 'package:grubbd_app/features/welcome/welcome_screen.dart';
import 'package:grubbd_app/features/shell/app_shell.dart';
import 'package:grubbd_app/features/posts/create_grubb_screen.dart';
import 'package:grubbd_app/features/collections/collections_screen.dart';
import 'package:grubbd_app/features/groups/groups_screen.dart';
import 'package:grubbd_app/features/food_trail/food_trail_screen.dart';
import 'package:grubbd_app/features/profile/social_profile_screen.dart';
import 'package:grubbd_app/features/legal/legal_document_screen.dart';

/// Configures the application and decides which screen appears first.
class GrubbdApp extends StatelessWidget {
  const GrubbdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF594D),
          surface: const Color(0xFFFFFBF1),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF1),
        textTheme: GoogleFonts.merriweatherTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBF1),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFBF1),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFFFBF1),
          indicatorColor: Color(0xFFFFD9CF),
        ),
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
        '/update-profile': (_) => const UpdateProfileScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/home': (_) => const AppShell(),
        '/explore': (_) => const AppShell(initialIndex: 1),
        '/groups-tab': (_) => const AppShell(initialIndex: 2),
        '/profile-tab': (_) => const AppShell(initialIndex: 3),
        '/create-session': (_) => const CreateSessionScreen(),
        '/join-session': (_) => const JoinSessionScreen(),
        '/create-grubb': (_) => const CreateGrubbScreen(),
        '/collections': (_) => const CollectionsScreen(),
        '/groups': (_) => const GroupsScreen(),
        '/food-trail': (_) => const FoodTrailScreen(),
        '/social-profile': (_) => const SocialProfileScreen(),
        '/terms': (_) => const LegalDocumentScreen(privacy: false),
        '/privacy': (_) => const LegalDocumentScreen(privacy: true),
      },
    );
  }
}
