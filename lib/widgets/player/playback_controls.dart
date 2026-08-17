import 'package:flutter/material.dart';
import 'package:vespera/theme/player_theme.dart';
import 'package:vespera/widgets/player/glass_circle_button.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.playOuterSize = 76,
    this.skipSize = 56,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double playOuterSize;
  final double skipSize;

  @override
  Widget build(BuildContext context) {
    final inner = playOuterSize - 8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(
            Icons.shuffle_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassCircleButton(
                  icon: Icons.skip_previous_rounded,
                  size: skipSize,
                  iconSize: 32,
                ),
                const SizedBox(width: 26),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Container(
                    width: playOuterSize,
                    height: playOuterSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PlayerTheme.accentPurple.withValues(alpha: 0.5),
                          blurRadius: 22,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: inner,
                        height: inner,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PlayerTheme.playGradient,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: inner * 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 26),
                GlassCircleButton(
                  icon: Icons.skip_next_rounded,
                  size: skipSize,
                  iconSize: 32,
                ),
              ],
            ),
          ),
          Icon(
            Icons.repeat_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ],
      ),
    );
  }
}
