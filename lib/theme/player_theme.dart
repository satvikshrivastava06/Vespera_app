import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matched to `player interface.png` & `player lyrics interface.png`.
abstract final class PlayerTheme {
  static const String portraitAsset = 'assets/player/portrait.png';

  /// Charlie Puth — Attention (cover art).
  static const String albumArtUrl =
      'https://i.scdn.co/image/ab67616d0000b273c5649eeb2f91104c00805cc34';

  static const Color accentPurple = Color(0xFF9B3FE8);
  static const Color accentMagenta = Color(0xFFE94B6A);

  static const LinearGradient playGradient = LinearGradient(
    colors: [Color(0xFF8B3FE8), Color(0xFFE84872)],
    begin: Alignment(-0.6, -0.8),
    end: Alignment(0.8, 0.9),
  );

  static const Color glassButtonFill = Color(0x8C3D3D48);
  static const Color lyricsDockFill = Color(0xE61E1E24);
  static const Color lyricsTabFill = Color(0xF025252C);

  static TextStyle titleStyle(double size) => GoogleFonts.poppins(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      );

  static TextStyle artistStyle(double size) => GoogleFonts.poppins(
        color: Colors.white.withValues(alpha: 0.78),
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.2,
      );

  static TextStyle headerStyle() => GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle dockLabelStyle() => GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static const String songTitle = 'Attention';
  static const String artistName = 'Charlie Puth';
  static const String durationCollapsed = '2:38';
  static const String durationExpanded = '3:32';
  static const String positionCollapsed = '0:00';
  static const String positionExpanded = '1:07';

  /// Waveform shape from reference (symmetric, denser center).
  static List<double> get waveformHeights {
    const raw = [
      0.15, 0.22, 0.3, 0.38, 0.48, 0.58, 0.68, 0.78, 0.88, 0.96, 1.0, 0.96,
      0.88, 0.78, 0.68, 0.58, 0.48, 0.38, 0.3, 0.22, 0.15, 0.1, 0.08, 0.12,
      0.18, 0.28, 0.4, 0.52, 0.64, 0.76, 0.86, 0.94, 1.0, 0.94, 0.84, 0.72,
      0.6, 0.48, 0.36, 0.26, 0.18, 0.12, 0.08, 0.1, 0.14, 0.2, 0.28, 0.36,
      0.44, 0.52, 0.6, 0.7, 0.8, 0.9, 0.98, 1.0, 0.95, 0.85, 0.72, 0.58,
      0.44, 0.32, 0.22, 0.14, 0.1,
    ];
    return raw;
  }

  /// Visible lines on lyrics screen (reference mockup).
  static const List<String> lyricsVisibleLines = [
    'You just want attention,',
    "You don't want my heart",
    'Maybe you just hate the',
    'Thought of me with',
  ];

  static const int activeLyricIndex = 1;
  static const double collapsedProgress = 0.0;
  static const double expandedProgress = 0.31;
}
