import 'package:flutter/material.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';

/// The first screen shown when the application opens.
class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(AppAssets.firstScreenBackground),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
