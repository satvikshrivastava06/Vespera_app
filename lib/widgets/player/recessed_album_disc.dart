import 'package:flutter/material.dart';
import 'package:vespera/widgets/player/portrait_image.dart';

/// Circular album art with recessed / sunken ring from the player reference.
class RecessedAlbumDisc extends StatelessWidget {
  const RecessedAlbumDisc({super.key, this.diameter = 272});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final inner = diameter - 28;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 1,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.35),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipOval(
            child: PortraitImage(
              width: inner,
              height: inner,
              alignment: const Alignment(0, -0.15),
            ),
          ),
        ),
      ),
    );
  }
}
