import 'package:flutter/material.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

/// Configures the application and decides which screen appears first.
class GrubbdApp extends StatelessWidget {
  const GrubbdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstScreen(),
    );
  }
}
