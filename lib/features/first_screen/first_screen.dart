import 'package:flutter/material.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({
    super.key,
    this.showBranding = true,
    this.autoNavigate = false,
  });

  final bool showBranding;
  final bool autoNavigate;

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      _openLoaderAfterDelay();
    }
  }

  Future<void> _openLoaderAfterDelay() async {
    // Keep the first screen visible for five seconds.
    await Future<void>.delayed(const Duration(seconds: 5));

    // The user may have closed the screen while we were waiting.
    if (!mounted) return;

    // Replace the first screen with the loader screen.
    await Navigator.pushReplacementNamed(context, '/loader');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage(AppAssets.firstScreenBackground),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final brandingSize = constraints.maxWidth * 0.46;
                return Stack(
                  children: [
                    if (widget.showBranding)
                      Positioned(
                        left: (constraints.maxWidth - brandingSize) / 2,
                        top: constraints.maxHeight * 0.34,
                        child: GrubbdCircularBranding(
                          size: brandingSize,
                          logoSize: constraints.maxWidth * 0.18,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
