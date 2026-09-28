import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    // ponytail: width only -> intrinsic 3:2 ratio preserved; forcing a square
    // box letterboxed the 816px-wide mark inside the 1536px canvas.
    return Image.asset(
      'assets/images/salus_logo.png',
      width: size,
    );
  }
}
