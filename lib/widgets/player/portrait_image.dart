import 'package:flutter/material.dart';
import 'package:vespera/theme/player_theme.dart';

/// Artist portrait — network album art with asset fallback (cropped top).
class PortraitImage extends StatelessWidget {
  const PortraitImage({
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -0.4),
    this.width,
    this.height,
  });

  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      PlayerTheme.albumArtUrl,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        PlayerTheme.portraitAsset,
        fit: fit,
        alignment: const Alignment(0, -0.82),
        width: width,
        height: height,
      ),
    );
  }
}
