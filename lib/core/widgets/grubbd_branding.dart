import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';

const String grubbdTagline = 'Can\'t decide? End the food debate with Grubbd';

const TextStyle grubbdTaglineStyle = TextStyle(
  color: Colors.white,
  fontFamily: 'Playfair Display',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.2,
  shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4)],
);

class GrubbdLogo extends StatelessWidget {
  const GrubbdLogo({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppAssets.grubbdLogo, width: width, fit: BoxFit.contain);
  }
}

class GrubbdTagline extends StatelessWidget {
  const GrubbdTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      grubbdTagline,
      textAlign: TextAlign.center,
      style: grubbdTaglineStyle,
    );
  }
}

/// Groups the shared logo and tagline into the animated loading treatment.
class CircularGrubbdLoader extends StatelessWidget {
  const CircularGrubbdLoader({
    super.key,
    required this.animation,
    required this.size,
    required this.logoSize,
  });

  final Animation<double> animation;
  final double size;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            key: const Key('tagline-circle-animation'),
            turns: animation,
            child: const SizedBox.expand(
              child: CustomPaint(
                key: Key('loader-tagline'),
                painter: _CircularTextPainter(
                  text: 'CAN\'T DECIDE? • END THE FOOD DEBATE WITH GRUBBD • ',
                ),
              ),
            ),
          ),
          _AnimatedGrubbdLogo(
            key: const Key('loader-logo'),
            animation: animation,
            size: logoSize,
          ),
        ],
      ),
    );
  }
}

class _AnimatedGrubbdLogo extends StatelessWidget {
  const _AnimatedGrubbdLogo({
    super.key,
    required this.animation,
    required this.size,
  });

  final Animation<double> animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final phase = animation.value * 2 * math.pi;

        return Transform.translate(
          offset: Offset(0, math.sin(phase) * 5),
          child: Transform.rotate(
            angle: math.sin(phase) * 0.035,
            child: Transform.scale(
              scale: 1 + math.sin(phase) * 0.045,
              child: child,
            ),
          ),
        );
      },
      child: GrubbdLogo(width: size),
    );
  }
}

class _CircularTextPainter extends CustomPainter {
  const _CircularTextPainter({required this.text});

  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.40;
    final angleStep = 2 * math.pi / text.length;

    for (var index = 0; index < text.length; index++) {
      final angle = -math.pi / 2 + index * angleStep;
      final painter = TextPainter(
        text: TextSpan(
          text: text[index],
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Playfair Display',
            fontSize: size.shortestSide * 0.064,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.rotate(angle + math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTextPainter oldDelegate) =>
      oldDelegate.text != text;
}
