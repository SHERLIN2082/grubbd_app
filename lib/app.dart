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
          primary: const Color(0xFFFF594D),
          secondary: const Color(0xFFFF9F1C),
          surface: const Color(0xFFFFFDF9),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF1),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBF1),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E1A1A)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x18E94F54),
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: const Color(0xFFE94F54).withOpacity(0.08)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF594D),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0x33FF594D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E1A1A),
            side: const BorderSide(color: Color(0xFFFF594D), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFDF9),
          indicatorColor: const Color(0xFFFFE0D9),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFFFF594D),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              );
            }
            return const TextStyle(
              color: Color(0xFF756D69),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFFF594D), size: 24);
            }
            return const IconThemeData(color: Color(0xFF756D69), size: 24);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(
            color: Color(0xFF9E948E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFFE94F54).withOpacity(0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF594D), width: 2),
          ),
        ),
      ),
      home: const LoaderScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/update-profile') {
          return PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            pageBuilder: (context, _, _) => const UpdateProfileScreen(),
          );
        }
        return null;
      },
      routes: {
        '/loader': (_) => const LoaderScreen(),
        '/profile': (_) => const AvatarSetupScreen(),
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
