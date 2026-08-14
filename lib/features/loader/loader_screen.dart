import 'package:flutter/material.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

/// Displays the picnic scene while the app prepares the next screen.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

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
