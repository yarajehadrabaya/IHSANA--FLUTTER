import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background color
        Container(color: const Color(0xFFF6FBFF)),

        // Decorative blobs
        const Positioned(
          top: -80,
          left: -80,
          child: _Blob(size: 260, color: Color(0xFFE8F3FF)),
        ),
        const Positioned(
          bottom: -100,
          right: -100,
          child: _Blob(size: 300, color: Color(0xFFEAF6F3)),
        ),

        // Page content
        SafeArea(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
