import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PlayerUIStyle { darkGlass, lightNeumorphic }

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  // Design Constants - Light Theme Focus
  static const Color kPrimaryPurple = Color(0xFF863FF0);
  static const Color kPrimaryMagenta = Color(0xFFE427B4);
  static const Color kLightBackground = Color(0xFFF0F2F5);
  
  // Premium Shadows for readability on light glass
  static final List<Shadow> kTextShadow = [
    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isPlaying = true;
  bool _isLiked = true;
  bool _showLyrics = false;
  PlayerUIStyle _currentStyle = PlayerUIStyle.darkGlass;
  bool _isControlBarTransparent = false;

  void _toggleStyle() {
    setState(() {
      _currentStyle = _currentStyle == PlayerUIStyle.darkGlass 
          ? PlayerUIStyle.lightNeumorphic 
          : PlayerUIStyle.darkGlass;
    });
  }

  void _toggleControlBarTransparency() {
    setState(() {
      _isControlBarTransparent = !_isControlBarTransparent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NowPlayingScreen.kLightBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Light-Themed Atmospheric Background
          const _AmbientAtmosphere(),

          // 2. Main UI Layer (Toggle between Player and Lyrics)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
            child: _showLyrics 
              ? _LyricsView(
                  isPlaying: _isPlaying,
                  onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
                  onBack: () => setState(() => _showLyrics = false),
                  currentStyle: _currentStyle,
                )
              : _currentStyle == PlayerUIStyle.darkGlass
                ? _DarkGlassView(
                    isPlaying: _isPlaying,
                    isLiked: _isLiked,
                    onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
                    onToggleLike: () => setState(() => _isLiked = !_isLiked),
                    onShowLyrics: () => setState(() => _showLyrics = true),
                    onToggleStyle: _toggleStyle,
                  )
                : _LightNeumorphicView(
                    isPlaying: _isPlaying,
                    isLiked: _isLiked,
                    isControlBarTransparent: _isControlBarTransparent,
                    onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
                    onToggleLike: () => setState(() => _isLiked = !_isLiked),
                    onShowLyrics: () => setState(() => _showLyrics = true),
                    onToggleStyle: _toggleStyle,
                    onToggleTransparency: _toggleControlBarTransparency,
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Dark Glass Player View (Original) ---
class _DarkGlassView extends StatelessWidget {
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleLike;
  final VoidCallback onShowLyrics;
  final VoidCallback onToggleStyle;

  const _DarkGlassView({
    required this.isPlaying,
    required this.isLiked,
    required this.onTogglePlay,
    required this.onToggleLike,
    required this.onShowLyrics,
    required this.onToggleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        key: const ValueKey('player_view'),
        children: [
          const SizedBox(height: 12),
          
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NeumorphicGlassButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Text(
                  'Now Playing',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    shadows: NowPlayingScreen.kTextShadow,
                  ),
                ),
                _NeumorphicGlassButton(
                  icon: Icons.style_rounded,
                  onTap: onToggleStyle,
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Hero Album Art
          const _BeveledAlbumArt(),

          const Spacer(flex: 3),

          // Track Metadata
          _TrackMetaRow(
            isLiked: isLiked,
            onLike: onToggleLike,
          ),

          const SizedBox(height: 32),

          // Geometric Spiky Waveform
          const _GeometricWaveform(),

          const SizedBox(height: 42),

          // Primary Controls
          _PlaybackControlRow(
            isPlaying: isPlaying,
            onToggle: onTogglePlay,
          ),

          const Spacer(flex: 4),

          // Bottom Wave Panel (Triggers Lyrics)
          GestureDetector(
            onTap: onShowLyrics,
            child: const _LyricsWavePanel(isHeader: false),
          ),
        ],
      ),
    );
  }
}

// --- Lyrics View (Cloned from player lyrics interface.png) ---
class _LyricsView extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onBack;
  final PlayerUIStyle currentStyle;

  const _LyricsView({
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onBack,
    required this.currentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStyle == PlayerUIStyle.lightNeumorphic) {
      return _LightLyricsView(
        isPlaying: isPlaying,
        onTogglePlay: onTogglePlay,
        onBack: onBack,
      );
    }
    return Stack(
      key: const ValueKey('lyrics_view'),
      children: [
        // 1. Large Artist Visual (Full Screen Background)
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.3, 0.68], // Fades out exactly before the song name "Attention"
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: Image.network(
              'https://picsum.photos/seed/artist_full/800/800',
              fit: BoxFit.cover,
            ),
          ),
        ),

        Column(
          children: [
            // 2. Top Inverted Wave Header
            _LyricsWavePanel(isHeader: true, onBack: onBack),

            // 3. Middle Lyrics Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LyricLine(text: "You just want attention,", opacity: 0.5),
                  const SizedBox(height: 18),
                  _LyricLine(text: "You don't want my heart", opacity: 1.0, isBold: true),
                  const SizedBox(height: 18),
                  _LyricLine(text: "Maybe you just hate the", opacity: 0.5),
                  const SizedBox(height: 18),
                  _LyricLine(text: "Thought of me with", opacity: 0.5),
                ],
              ),
            ),

            // 4. Persistent Player Controls (Bottom Part)
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Song Info Row
                  _TrackMetaRow(isLiked: true, onLike: () {}),
                  const SizedBox(height: 24),
                  
                  // Waveform Progress
                  const _GeometricWaveform(isInteractive: true),
                  const SizedBox(height: 32),
                  
                  // Controls
                  _PlaybackControlRow(isPlaying: isPlaying, onToggle: onTogglePlay),
                  
                  const SizedBox(height: 16),
                  
                  // Bottom Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.shuffle_rounded, color: Colors.white.withOpacity(0.8), size: 24),
                        Icon(Icons.repeat_rounded, color: Colors.white.withOpacity(0.8), size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LyricLine extends StatelessWidget {
  final String text;
  final double opacity;
  final bool isBold;
  const _LyricLine({required this.text, required this.opacity, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          color: Colors.white.withOpacity(opacity),
          fontSize: isBold ? 28 : 22,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          shadows: NowPlayingScreen.kTextShadow,
        ),
      ),
    );
  }
}

// --- Common UI Components ---

class _AmbientAtmosphere extends StatelessWidget {
  const _AmbientAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A4A58), Color(0xFF6C6C80), Color(0xFFB8BCC6)],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        Positioned(top: -100, right: -50, child: _GlowBlob(color: const Color(0xFFE59A8E).withOpacity(0.4), radius: 250)),
        Positioned(top: 200, left: -100, child: _GlowBlob(color: const Color(0xFF6B8AFF).withOpacity(0.35), radius: 300)),
        Positioned(bottom: 100, right: -80, child: _GlowBlob(color: const Color(0xFFB17AFF).withOpacity(0.35), radius: 250)),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: Container(color: Colors.white.withOpacity(0.12))),
      ],
    );
  }
}

class _BeveledAlbumArt extends StatelessWidget {
  const _BeveledAlbumArt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 325, height: 325,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(10, 10)),
                BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, offset: const Offset(-8, -8)),
              ],
            ),
          ),
          Container(
            width: 295, height: 295,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: -2)]),
            child: const CircleAvatar(backgroundImage: NetworkImage('https://picsum.photos/seed/artist234/600/600')),
          ),
        ],
      ),
    );
  }
}

class _TrackMetaRow extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLike;

  const _TrackMetaRow({required this.isLiked, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.playlist_play_rounded, color: Colors.white.withOpacity(0.9), size: 32),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attention',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, shadows: NowPlayingScreen.kTextShadow),
                ),
                Text(
                  'Charlie Puth',
                  style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w500, shadows: NowPlayingScreen.kTextShadow),
                ),
              ],
            ),
          ),
          GestureDetector(onTap: onLike, child: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 32)),
        ],
      ),
    );
  }
}

class _GeometricWaveform extends StatelessWidget {
  final bool isInteractive;
  const _GeometricWaveform({this.isInteractive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(height: 70, width: double.infinity, child: CustomPaint(painter: _WaveformPainter(progress: 0.45))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0:00', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              Text('2:38', style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const int count = 50;
    final double gap = size.width / count;
    final double width = gap * 0.5;

    for (int i = 0; i < count; i++) {
      double h = (10 + (15 * (i % 8) / 8) + (10 * (i * 3 % 11) / 11));
      paint.color = (i / count < progress) ? Colors.white : Colors.white.withOpacity(0.2);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(i * gap + gap/2, size.height / 2), width: width, height: h * 2), Radius.circular(width)), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlaybackControlRow extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onToggle;

  const _PlaybackControlRow({required this.isPlaying, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NeumorphicGlassButton(icon: Icons.skip_previous_rounded, onTap: () {}, size: 65),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [NowPlayingScreen.kPrimaryPurple, NowPlayingScreen.kPrimaryMagenta])),
              child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 42),
            ),
          ),
          _NeumorphicGlassButton(icon: Icons.skip_next_rounded, onTap: () {}, size: 65),
        ],
      ),
    );
  }
}

class _NeumorphicGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _NeumorphicGlassButton({required this.icon, required this.onTap, this.size = 58});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.transparent), // Base for safety
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shiny Reflection Border Layer
                Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2.5), // The border thickness
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.05), // To show glass behind
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white, size: size * 0.45),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricsWavePanel extends StatelessWidget {
  final bool isHeader;
  final VoidCallback? onBack;
  const _LyricsWavePanel({required this.isHeader, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: isHeader ? _InvertedWaveClipper() : _BaseWaveClipper(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: isHeader ? 95 : 75,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.only(
              bottomLeft: isHeader ? const Radius.circular(30) : Radius.zero,
              bottomRight: isHeader ? const Radius.circular(30) : Radius.zero,
              topLeft: !isHeader ? const Radius.circular(30) : Radius.zero,
              topRight: !isHeader ? const Radius.circular(30) : Radius.zero,
            ),
          ),
          child: Stack(
            children: [
              // Shiny Reflective Border Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: _ShinyGlassBorderPainter(
                    isHeader: isHeader,
                    borderRadius: 30,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: isHeader ? 22 : 20, bottom: isHeader ? 15 : 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isHeader) Icon(Icons.shuffle_rounded, color: Colors.white.withOpacity(0.9), size: 24),
                    
                    GestureDetector(
                      onTap: isHeader ? onBack : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHeader) Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                          Text(
                            'Lyrics',
                            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, shadows: NowPlayingScreen.kTextShadow),
                          ),
                        ],
                      ),
                    ),

                    if (!isHeader) Icon(Icons.repeat_rounded, color: Colors.white.withOpacity(0.9), size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Premium Painter for the 'Shiny Glass' Reflection effect on the panel borders
class _ShinyGlassBorderPainter extends CustomPainter {
  final bool isHeader;
  final double borderRadius;

  _ShinyGlassBorderPainter({required this.isHeader, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromLTRBAndCorners(
      0, 0, size.width, size.height,
      bottomLeft: isHeader ? Radius.circular(borderRadius) : Radius.zero,
      bottomRight: isHeader ? Radius.circular(borderRadius) : Radius.zero,
      topLeft: !isHeader ? Radius.circular(borderRadius) : Radius.zero,
      topRight: !isHeader ? Radius.circular(borderRadius) : Radius.zero,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.6),   // Strong highlight
          Colors.white.withOpacity(0.1),   // Translucent side
          Colors.white.withOpacity(0.5),   // Dynamic reflection
          Colors.white.withOpacity(0.05),  // Shadow/Dark side
        ],
        stops: const [0.0, 0.45, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Light Neumorphic Player View (Exact Clone of player1.png) ---
class _LightNeumorphicView extends StatelessWidget {
  final bool isPlaying;
  final bool isLiked;
  final bool isControlBarTransparent;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleLike;
  final VoidCallback onShowLyrics;
  final VoidCallback onToggleStyle;
  final VoidCallback onToggleTransparency;

  const _LightNeumorphicView({
    required this.isPlaying,
    required this.isLiked,
    required this.isControlBarTransparent,
    required this.onTogglePlay,
    required this.onToggleLike,
    required this.onShowLyrics,
    required this.onToggleStyle,
    required this.onToggleTransparency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD6E4F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 54), // Spacing to account for system status bar while bleeding
          // Branding
          const Padding(
            padding: EdgeInsets.only(left: 36),
            child: Text(
              'VESPERA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 4.5,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          // Song Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'DUSK TILL DAWN',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF1E293B),
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: IconButton(
                  icon: const Icon(Icons.style_outlined, color: Color(0xFF1E293B), size: 24),
                  onPressed: onToggleStyle,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          // Artist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 24, height: 1.2),
                children: [
                  TextSpan(
                    text: 'ZAYN',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'ft. Sia',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          // Device Info
          const Padding(
            padding: EdgeInsets.only(left: 36),
            child: Text(
              "Kazuya's Air Pods Pro",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B9BD5),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          // Album Art + Controls Stack
          Expanded(
            child: Stack(
              children: [
                // Album Art Composition shifted right
                Positioned(
                  right: -20,
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: const _LightAlbumArtComposition(),
                    ),
                  ),
                ),
                
                // Left Control Bar
                Positioned(
                  left: 28,
                  top: 0,
                  bottom: 0,
                  child: Center(
                      child: _LightControlBar(
                        isPlaying: isPlaying,
                        isLiked: isLiked,
                        isTransparent: isControlBarTransparent,
                        onTogglePlay: onTogglePlay,
                        onToggleLike: onToggleLike,
                        onToggleTransparency: onToggleTransparency,
                      ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          // Active Lyric Snippet
          Center(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: "But you'll ", style: TextStyle(color: Color(0xFF94A3B8))),
                  TextSpan(text: "never", style: TextStyle(color: Color(0xFF5B9BD5), fontWeight: FontWeight.w800)),
                  TextSpan(text: " be alone", style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          // SEE ALL LYRICS Button
          Center(
            child: GestureDetector(
              onTap: onShowLyrics,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E4F0),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      offset: const Offset(-8, -8),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: const Color(0xFFA0B0C0).withOpacity(0.4),
                      offset: const Offset(12, 12),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Text(
                  'SEE ALL LYRICS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Color(0xFF5B9BD5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _StatusText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _LightAlbumArtComposition extends StatelessWidget {
  const _LightAlbumArtComposition();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Soft Glow Ring
          Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD6E4F0),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(-20, -20),
                  blurRadius: 45,
                ),
                BoxShadow(
                  color: const Color(0xFFA0B0C0).withOpacity(0.3),
                  offset: const Offset(25, 25),
                  blurRadius: 50,
                ),
              ],
            ),
          ),
          // Middle Cream Ring
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5E6DC), // Warm Background
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  offset: const Offset(-8, -8),
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(12, 12),
                  blurRadius: 25,
                ),
              ],
            ),
          ),
          // Progress Arc
          CustomPaint(
            size: const Size(320, 320),
            painter: _LightProgressArcPainter(),
          ),
          // Rectangular Art Frame
          Container(
            width: 190,
            height: 250,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574), // Wood Frame
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  offset: const Offset(12, 18),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Container(
              color: const Color(0xFFFAF7F2), // Inner Cream
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const Spacer(),
                  // Abstract Shape Art
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(painter: _LightAbstractArtPainter()),
                  ),
                  const Spacer(),
                  const Text(
                    'Album Nature',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'KAZUYA • VESPERA • SOUND',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LightControlBar extends StatelessWidget {
  final bool isPlaying;
  final bool isLiked;
  final bool isTransparent;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleTransparency;

  const _LightControlBar({
    required this.isPlaying,
    required this.isLiked,
    required this.isTransparent,
    required this.onTogglePlay,
    required this.onToggleLike,
    required this.onToggleTransparency,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isTransparent ? const Color(0xFFD6E4F0).withOpacity(0.15) : const Color(0xFFD6E4F0),
        borderRadius: BorderRadius.circular(40),
        boxShadow: isTransparent 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  offset: const Offset(-10, -10),
                  blurRadius: 25,
                ),
                BoxShadow(
                  color: const Color(0xFFA0B0C0).withOpacity(0.35),
                  offset: const Offset(12, 12),
                  blurRadius: 30,
                ),
              ],
        border: isTransparent 
            ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isTransparent ? 12 : 0, sigmaY: isTransparent ? 12 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggleTransparency,
                child: Icon(
                  isTransparent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 24,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 28),
              _ControlIcon(Icons.repeat_rounded),
              const SizedBox(height: 28),
              _ControlIcon(Icons.skip_previous_rounded),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: onTogglePlay,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 28),
              _ControlIcon(Icons.skip_next_rounded),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: onToggleLike,
                child: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  size: 26,
                  color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ControlIcon(IconData icon) {
    return Icon(icon, size: 24, color: const Color(0xFF94A3B8));
  }
}

class _LightProgressArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    
    final paint = Paint()
      ..color = const Color(0xFFE8A8A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Drawing a specific part of the arc as seen in player1.png
    canvas.drawArc(rect, -0.6, 1.2, false, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightAbstractArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Cream Circle Background
    canvas.drawCircle(center, size.width * 0.42, Paint()..color = const Color(0xFFF0E6D8));

    // Green Shape
    final greenPath = Path();
    greenPath.moveTo(center.dx + 5, center.dy + 15);
    greenPath.quadraticBezierTo(center.dx + 40, center.dy, center.dx + 45, center.dy + 35);
    greenPath.quadraticBezierTo(center.dx + 40, center.dy + 60, center.dx + 10, center.dy + 55);
    greenPath.quadraticBezierTo(center.dx - 10, center.dy + 40, center.dx + 5, center.dy + 15);
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF5C6B4A));

    // Tan Shape
    final tanPath = Path();
    tanPath.moveTo(center.dx - 35, center.dy - 10);
    tanPath.quadraticBezierTo(center.dx, center.dy - 40, center.dx + 25, center.dy - 10);
    tanPath.quadraticBezierTo(center.dx + 30, center.dy + 15, center.dx, center.dy + 25);
    tanPath.quadraticBezierTo(center.dx - 40, center.dy + 15, center.dx - 35, center.dy - 10);
    canvas.drawPath(tanPath, Paint()..color = const Color(0xFFD4B896));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BaseWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 40);
    p.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 0);
    p.quadraticBezierTo(size.width * 0.75, 0, size.width, 40);
    p.lineTo(size.width, size.height); p.lineTo(0, size.height); p.close();
    return p;
  }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _InvertedWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 40);
    p.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height);
    p.quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height - 40);
    p.lineTo(size.width, 0); p.close();
    return p;
  }
  @override bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GlowBlob extends StatelessWidget {
  final Color color; final double radius;
  const _GlowBlob({required this.color, required this.radius});
  @override Widget build(BuildContext context) {
    return Container(width: radius * 2, height: radius * 2, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)], stops: const [0.1, 0.9])));
  }
}

class _LightLyricsView extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onBack;

  const _LightLyricsView({
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD6E4F0),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Header with Back Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Color(0xFF1E293B)),
                  onPressed: onBack,
                ),
                const Spacer(),
                const Text(
                  'LYRICS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balancing back button
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
              child: Column(
                children: [
                  _LyricLine("But you'll never be alone", isActive: true),
                  _LyricLine("I'll be with you from dusk till dawn"),
                  _LyricLine("I'll be with you from dusk till dawn"),
                  _LyricLine("Baby, I am right here"),
                  _LyricLine("I'll hold you when things go wrong"),
                  _LyricLine("I'll be with you from dusk till dawn"),
                  _LyricLine("I'll be with you from dusk till dawn"),
                  _LyricLine("Baby, I am right here"),
                ],
              ),
            ),
          ),

          // Mini Controls for Lyrics View
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFD6E4F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.skip_previous_rounded, size: 32, color: Color(0xFF94A3B8)),
                GestureDetector(
                  onTap: onTogglePlay,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E4F0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          offset: const Offset(-5, -5),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA0B0C0).withOpacity(0.3),
                          offset: const Offset(5, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32, color: const Color(0xFF5B9BD5)),
                  ),
                ),
                const Icon(Icons.skip_next_rounded, size: 32, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _LyricLine(String text, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isActive ? 28 : 22,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          color: isActive ? const Color(0xFF5B9BD5) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
