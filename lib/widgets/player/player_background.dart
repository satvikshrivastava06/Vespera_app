import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vespera/widgets/player/portrait_image.dart';

/// Blurred portrait backdrop for the main player screen.
class PlayerBlurredBackground extends StatelessWidget {
  const PlayerBlurredBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const PortraitImage(alignment: Alignment(0, -0.35)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A2D6E).withValues(alpha: 0.72),
                  const Color(0xFF3A2858).withValues(alpha: 0.78),
                  const Color(0xFF4A2838).withValues(alpha: 0.82),
                  const Color(0xFF2A1A32).withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 1.05,
              colors: [
                const Color(0xFF8E5A9A).withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full portrait + bottom frost for lyrics screen.
class LyricsScreenBackground extends StatelessWidget {
  const LyricsScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomH = MediaQuery.sizeOf(context).height * 0.52;

    return Stack(
      fit: StackFit.expand,
      children: [
        const PortraitImage(alignment: Alignment(0, -0.25)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomH,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 1.0],
                    colors: [
                      const Color(0xFF180E22).withValues(alpha: 0.05),
                      const Color(0xFF140A1C).withValues(alpha: 0.72),
                      const Color(0xFF0A0610).withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
