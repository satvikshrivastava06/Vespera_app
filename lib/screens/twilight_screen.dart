import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class TwilightScreen extends StatefulWidget {
  const TwilightScreen({super.key});

  @override
  State<TwilightScreen> createState() => _TwilightScreenState();
}

class _TwilightScreenState extends State<TwilightScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;
  late Animation<double> _orbPulse;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _orbPulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbController.dispose();
    _chatController.dispose();
    _chatFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050313),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Background radial gradient meshes (bg-app) ──────────────────
            Positioned.fill(
              child: CustomPaint(painter: _BgMeshPainter()),
            ),

            // ── Main scrollable content ────────────────────────────────────
            SafeArea(
              child: Hero(
                tag: 'twilight_interface_transition',
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => _chatFocus.unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24)
                          .copyWith(top: 40, bottom: 24), // pt-10 = 40px
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Header (Matching index.tsx) ────────────────────────
                          _buildHeader(context),
                          const SizedBox(height: 28), // mt-7 approx

                          // ── Featured pill ─────────────────────────────────
                          Center(
                            child: _GlassPill(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Featured',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24), // mt-6

                          // ── Energy Orb ────────────────────────────────────
                          _buildOrb(),
                          const SizedBox(height: 16), // mt-4

                          // ── Greeting ──────────────────────────────────────
                          Text(
                            'Good day!',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How may i assist you today?',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28), // mt-7

                          // ── Improve my mood card ──────────────────────────
                          _buildMoodCard(),
                          const SizedBox(height: 16), // mt-4

                          // ── Two small cards (Music DNA, Semantic Search) ──────────
                          Row(
                            children: [
                              Expanded(child: _buildMusicDnaCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildSemanticSearchCard()),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          _buildSuggestions(),
                          const SizedBox(height: 32),

                          // ── Chat input section ────────────────────────────
                          _buildChatInput(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Header: Logo + Title (Left) and Vespera button (Right)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Logo + Text
        Row(
          children: [
            Image.asset(
              'assets/twilight-logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Twilight AI',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),

        // Right side: Vespera button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: _GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Vespera',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Energy orb with pulsing glow (orb-glow class)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbPulse,
      builder: (context, child) {
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7850FF)
                    .withValues(alpha: 0.55 * _orbPulse.value),
                blurRadius: 60,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF5078FF)
                    .withValues(alpha: 0.35 * _orbPulse.value),
                blurRadius: 120,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/energy-orb.png',
        width: 280,
        height: 280,
        fit: BoxFit.contain,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // "Improve my mood" card
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildMoodCard() {
    return _GlassCardBorder(
      borderRadius: 24,
      child: Stack(
        children: [
          // Aurora streaks image background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/aurora-streaks.jpg',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.85),
                colorBlendMode: BlendMode.screen,
              ),
            ),
          ),
          // Gradient from left to hide image under text
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D0A1F).withValues(alpha: 0.95),
                      const Color(0xFF0D0A1F).withValues(alpha: 0.40),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20), // p-5
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Improve my mood',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "creates a personalized playlist that starts with 'how you feel' and gently lifts you toward a better mood, using AI it blends emotion and sound to uplift your mood.",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _ArrowButton(size: 40),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Music DNA card
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildMusicDnaCard() {
    return _GlassCardBorder(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(child: _MusicDnaIcon()),
            ),
            const SizedBox(height: 14),
            Text(
              'Music DNA',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Personal preference analytics with AI companion.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12.8,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                _ArrowButton(size: 34),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Semantic Search card
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSemanticSearchCard() {
    return _GlassCardBorder(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(child: _SemanticSearchIcon()),
            ),
            const SizedBox(height: 14),
            Text(
              'Semantic search',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'search music by meaning, not just keywords. Describe your feelings mood or situation.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
                _ArrowButton(size: 34),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Suggestions
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Column(
      children: [
        _SuggestionCard(text: "What are the trending songs in India?"),
        const SizedBox(height: 12),
        _SuggestionCard(text: "I want to hear some rock music from 90s"),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Bottom chat input
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildChatInput() {
    return _GlassCardBorder(
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 20),
              child: Text(
                'Message Chatbot Ai....',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              children: [
                _ChatIconBtn(icon: Icons.add),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Stack(
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: Colors.white.withValues(alpha: 0.70),
                                size: 16,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Icon(
                                  Icons.search,
                                  color: Colors.white.withValues(alpha: 0.70),
                                  size: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            focusNode: _chatFocus,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your question',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ChatIconBtn(icon: Icons.mic_none_rounded),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B59FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B59FF).withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════════

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassCardBorder extends StatelessWidget {
  const _GlassCardBorder({required this.child, this.borderRadius = 24});
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: CustomPaint(
          painter: _GlassBorderPainter(radius: borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0A1F).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.8],
      ).createShader(rect);
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.arrow_outward_rounded,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }
}

class _ChatIconBtn extends StatelessWidget {
  const _ChatIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
      ),
    );
  }
}

class _MusicDnaIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _MusicDnaPainter(),
    );
  }
}

class _MusicDnaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    // Main circle headish part (cx=9, cy=7, r=3.2 in 24x24)
    canvas.drawCircle(
      Offset(size.width * 0.375, size.height * 0.291),
      size.width * 0.133,
      p,
    );
    // Shoulder part
    final path = Path()
      ..moveTo(size.width * 0.145, size.height * 0.812)
      ..quadraticBezierTo(
        size.width * 0.145,
        size.height * 0.575,
        size.width * 0.375,
        size.height * 0.575,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.575,
        size.width * 0.6,
        size.height * 0.812,
      )
      ..close();
    canvas.drawPath(path, p);
    // Triangle part (13.5 19.5, 17.8 13.3, 22.5 19.5)
    final path2 = Path()
      ..moveTo(size.width * 0.56, size.height * 0.812)
      ..lineTo(size.width * 0.74, size.height * 0.55)
      ..lineTo(size.width * 0.93, size.height * 0.812)
      ..close();
    canvas.drawPath(path2, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SemanticSearchIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _SemanticSearchPainter(),
    );
  }
}

class _SemanticSearchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final dark = Paint()
      ..color = const Color(0xFF0E0B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Main rect (x=3, y=4, w=14, h=14 in 24x24)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.125,
        size.height * 0.166,
        size.width * 0.58,
        size.height * 0.583,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rect, white);

    // Horizontal line
    canvas.drawLine(
      Offset(size.width * 0.125, size.height * 0.33),
      Offset(size.width * 0.705, size.height * 0.33),
      dark,
    );

    // Vertical ticks
    for (var x in [0.29, 0.46, 0.625]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.166),
        Offset(size.width * x, size.height * 0.33),
        dark,
      );
    }

    // Pen/Pencil part (14 20l6-6 2 2-6 6h-2v-2z)
    final penPath = Path()
      ..moveTo(size.width * 0.583, size.height * 0.833)
      ..lineTo(size.width * 0.833, size.height * 0.583)
      ..lineTo(size.width * 0.916, size.height * 0.666)
      ..lineTo(size.width * 0.666, size.height * 0.916)
      ..lineTo(size.width * 0.583, size.height * 0.916)
      ..close();
    canvas.drawPath(penPath, white);

    // Pen tip line
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.666),
      Offset(size.width * 0.833, size.height * 0.75),
      dark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BgMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawGlow(canvas, size, Offset(size.width * 0.2, size.height * 0.1), const Color(0xFF503CB4), 0.25);
    _drawGlow(canvas, size, Offset(size.width * 0.9, size.height * 0.9), const Color(0xFF7828C8), 0.18);
    _drawGlow(canvas, size, Offset(size.width * 0.5, size.height * 0.5), const Color(0xFF1E1450), 0.40);
  }
  void _drawGlow(Canvas canvas, Size size, Offset center, Color color, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), Colors.transparent]).createShader(Rect.fromCircle(center: center, radius: size.width * 0.8));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuggestionCard extends StatelessWidget {
  final String text;
  const _SuggestionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _GlassCardBorder(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
