import 'package:flutter/material.dart';
import 'package:vespera/theme/player_theme.dart';
import 'package:vespera/widgets/player/waveform_widget.dart';

class PlayerTitleBlock extends StatelessWidget {
  const PlayerTitleBlock({
    super.key,
    this.titleSize = 28,
    this.artistSize = 16,
    this.isLiked = true,
    this.onLikeToggle,
    this.showActionRow = true,
  });

  final double titleSize;
  final double artistSize;
  final bool isLiked;
  final VoidCallback? onLikeToggle;
  final bool showActionRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(PlayerTheme.songTitle, style: PlayerTheme.titleStyle(titleSize)),
        const SizedBox(height: 6),
        if (showActionRow)
          PlayerArtistActionRow(
            artistSize: artistSize,
            isLiked: isLiked,
            onLikeToggle: onLikeToggle,
          )
        else
          Text(
            PlayerTheme.artistName,
            style: PlayerTheme.artistStyle(artistSize),
          ),
      ],
    );
  }
}

/// Library + artist + heart on one row (reference layout).
class PlayerArtistActionRow extends StatelessWidget {
  const PlayerArtistActionRow({
    super.key,
    required this.artistSize,
    this.isLiked = true,
    this.onLikeToggle,
  });

  final double artistSize;
  final bool isLiked;
  final VoidCallback? onLikeToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        children: [
          Icon(
            Icons.library_music_outlined,
            color: Colors.white.withValues(alpha: 0.55),
            size: 22,
          ),
          Expanded(
            child: Text(
              PlayerTheme.artistName,
              textAlign: TextAlign.center,
              style: PlayerTheme.artistStyle(artistSize),
            ),
          ),
          GestureDetector(
            onTap: onLikeToggle,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerWaveformSection extends StatelessWidget {
  const PlayerWaveformSection({
    super.key,
    required this.position,
    required this.duration,
    required this.progress,
    this.maxBarHeight = 30,
    this.showTrackActions = false,
    this.isLiked = true,
    this.onLikeToggle,
  });

  final String position;
  final String duration;
  final double progress;
  final double maxBarHeight;
  final bool showTrackActions;
  final bool isLiked;
  final VoidCallback? onLikeToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          if (showTrackActions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white.withValues(alpha: 0.55),
                    size: 22,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onLikeToggle,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 36,
            child: WaveformWidget(
              progress: progress,
              maxBarHeight: maxBarHeight,
              barWidth: 2.0,
              barGap: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: PlayerTheme.artistStyle(12).fontFamily,
                ),
              ),
              Text(
                duration,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: PlayerTheme.artistStyle(12).fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
