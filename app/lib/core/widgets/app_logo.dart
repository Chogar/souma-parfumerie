import 'package:flutter/material.dart';

/// Logo officiel SOUMAPARFUMERIE (assets/branding/logo.jpg).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 120,
    this.showBorder = false,
  });

  final double size;
  final bool showBorder;

  static const String assetPath = 'assets/branding/logo.jpg';

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: const Color(0xFF1A1A2E),
          child: Icon(Icons.spa, size: size * 0.4, color: const Color(0xFFC9A227)),
        ),
      ),
    );

    if (!showBorder) return image;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC9A227), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: image,
    );
  }
}
