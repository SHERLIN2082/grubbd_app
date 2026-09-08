import 'package:flutter/material.dart';

class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.avatar,
    required this.fallbackText,
    this.size = 36,
  });

  final String avatar;
  final String fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cleanAvatar = avatar.trim();

    return SizedBox.square(
      dimension: size,
      child: cleanAvatar.startsWith('assets/images/avatars/')
          ? Image.asset(
              cleanAvatar,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : Center(child: _fallback()),
    );
  }

  Widget _fallback() {
    return Text(
      fallbackText,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}
