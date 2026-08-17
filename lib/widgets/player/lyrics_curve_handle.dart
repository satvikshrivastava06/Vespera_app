import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vespera/theme/player_theme.dart';

/// Curved dock — bottom pull-up on player, inverted tab on lyrics screen.
class LyricsCurveHandle extends StatelessWidget {
  const LyricsCurveHandle({
    super.key,
    required this.isTop,
    this.onTap,
    this.height = 68,
  });

  final bool isTop;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipPath(
        clipper: _LyricsCurveClipper(isTop: isTop, bulge: 26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: height,
            width: double.infinity,
            color: isTop ? PlayerTheme.lyricsTabFill : PlayerTheme.lyricsDockFill,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(
                top: isTop ? 20 : 8,
                bottom: isTop ? 8 : 14,
              ),
              child: Text('Lyrics', style: PlayerTheme.dockLabelStyle()),
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricsCurveClipper extends CustomClipper<Path> {
  _LyricsCurveClipper({required this.isTop, required this.bulge});

  final bool isTop;
  final double bulge;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isTop) {
      path.moveTo(0, size.height);
      path.lineTo(0, bulge + 8);
      path.cubicTo(
        size.width * 0.25,
        -bulge * 0.35,
        size.width * 0.75,
        -bulge * 0.35,
        size.width,
        bulge + 8,
      );
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - bulge - 8);
      path.cubicTo(
        size.width * 0.25,
        size.height + bulge * 0.4,
        size.width * 0.75,
        size.height + bulge * 0.4,
        size.width,
        size.height - bulge - 8,
      );
      path.lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _LyricsCurveClipper old) =>
      old.isTop != isTop || old.bulge != bulge;
}
