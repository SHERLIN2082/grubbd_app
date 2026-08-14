import 'package:flutter/material.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/core/widgets/grubbd_branding.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key, this.showBranding = true});

  final bool showBranding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColorFiltered(
              colorFilter: ColorFilter.matrix([
                0.92,
                0,
                0,
                0,
                16,
                0,
                0.92,
                0,
                0,
                16,
                0,
                0,
                0.92,
                0,
                16,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: Image(
                image: AssetImage(AppAssets.firstScreenBackground),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const ColoredBox(color: Color(0x10FFFFFF)),
            LayoutBuilder(
              builder: (context, constraints) {
                final plateSize = constraints.maxWidth * 0.20;
                final biscuitSize = plateSize * 0.25;
                final croissantSize = plateSize * 0.50;
                final pieSize = constraints.maxWidth * 0.215;

                Widget biscuit(double left, double top, double angle) {
                  return Positioned(
                    left: constraints.maxWidth * left,
                    top: constraints.maxHeight * top,
                    width: biscuitSize,
                    child: Transform.rotate(
                      angle: angle,
                      child: const Image(
                        image: AssetImage(AppAssets.heartBiscuit),
                      ),
                    ),
                  );
                }

                Widget croissant(double left, double top, double angle) {
                  return Positioned(
                    left: constraints.maxWidth * left,
                    top: constraints.maxHeight * top,
                    width: croissantSize,
                    child: Transform.rotate(
                      angle: angle,
                      child: const Image(
                        image: AssetImage(AppAssets.croissant),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Positioned(
                      left: constraints.maxWidth * 0.16,
                      top: constraints.maxHeight * 0.74,
                      width: plateSize,
                      child: const Image(
                        image: AssetImage(AppAssets.flowerPlate),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.10,
                      top: constraints.maxHeight * 0.87,
                      width: plateSize,
                      child: const Image(
                        image: AssetImage(AppAssets.flowerPlate),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.395,
                      top: constraints.maxHeight * 0.858,
                      width: pieSize,
                      child: const Image(image: AssetImage(AppAssets.pepPizza)),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.725,
                      top: constraints.maxHeight * 0.850,
                      width: pieSize,
                      child: const Image(image: AssetImage(AppAssets.pie)),
                    ),
                    biscuit(0.188, 0.762, -0.22),
                    biscuit(0.222, 0.773, 0.18),
                    biscuit(0.128, 0.892, -0.18),
                    biscuit(0.162, 0.903, 0.22),
                    croissant(0.235, 0.770, 1.72),
                    croissant(0.175, 0.900, 1.72),
                    if (showBranding) ...[
                      Positioned(
                        left: constraints.maxWidth * 0.42,
                        top: constraints.maxHeight * 0.255,
                        width: constraints.maxWidth * 0.18,
                        child: const GrubbdLogo(),
                      ),
                      Positioned(
                        left: constraints.maxWidth * 0.14,
                        top: constraints.maxHeight * 0.355,
                        width: constraints.maxWidth * 0.72,
                        child: const GrubbdTagline(),
                      ),
                    ],
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
