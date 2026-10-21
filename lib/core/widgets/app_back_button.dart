import 'package:flutter/material.dart';

/// A prominent, beginner-friendly back button that ensures users can always
/// return to the previous screen or fallback safely to Home.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.fallbackRoute = '/home',
    this.onPressed,
    this.color,
    this.tooltip = 'Back',
  });

  final String fallbackRoute;
  final VoidCallback? onPressed;
  final Color? color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      splashRadius: 24,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: color ?? const Color(0xFF1E1A1A),
          size: 18,
        ),
      ),
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, fallbackRoute, (_) => false);
        }
      },
    );
  }
}

