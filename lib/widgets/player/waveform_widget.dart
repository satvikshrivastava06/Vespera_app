import 'package:flutter/material.dart';
import 'package:vespera/theme/player_theme.dart';

class WaveformWidget extends StatelessWidget {
  const WaveformWidget({
    super.key,
    required this.progress,
    this.barWidth = 2.0,
    this.barGap = 1.8,
    this.maxBarHeight = 30,
  });

  final double progress;
  final double barWidth;
  final double barGap;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        heights: PlayerTheme.waveformHeights,
        progress: progress.clamp(0.0, 1.0),
        barWidth: barWidth,
        barGap: barGap,
        maxBarHeight: maxBarHeight,
      ),
      size: Size.infinite,
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.heights,
    required this.progress,
    required this.barWidth,
    required this.barGap,
    required this.maxBarHeight,
  });

  final List<double> heights;
  final double progress;
  final double barWidth;
  final double barGap;
  final double maxBarHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final count = heights.length;
    final totalWidth = count * barWidth + (count - 1) * barGap;
    var x = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;
    final progressX = size.width * progress;

    for (var i = 0; i < count; i++) {
      final barHeight = heights[i] * maxBarHeight;
      final top = centerY - barHeight / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(1),
      );

      final barCenterX = x + barWidth / 2;
      final isPlayed = progress > 0 && barCenterX <= progressX;

      final paint = Paint()..style = PaintingStyle.fill;
      if (isPlayed) {
        paint.shader = PlayerTheme.playGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        );
      } else {
        paint.color = Colors.white.withValues(alpha: 0.95);
      }

      canvas.drawRRect(rect, paint);
      x += barWidth + barGap;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => old.progress != progress;
}
