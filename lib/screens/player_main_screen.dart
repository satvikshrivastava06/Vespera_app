import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/screens/now_playing_screen.dart';
import 'package:vespera/screens/search_screen.dart';

class PlayerMainScreen extends StatefulWidget {
  const PlayerMainScreen({super.key});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Light base for the glassy theme
      body: Stack(
        children: [
          // 1. Precise atmospheric background blobs
          const _AmbientAtmosphere(),

          // 2. Main UI Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Header Navigation (Glassy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassButton(
                        icon: Icons.grid_view_rounded,
                        onTap: () => Navigator.maybePop(context),
                      ),
                      _GlassButton(
                        icon: Icons.search_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recently Played
                        const _SectionTitle(title: "Recently Played"),
                        const SizedBox(height: 18),
                        const _RecentlyPlayedGrid(),

                        const SizedBox(height: 38),

                        // You Might Like
                        const _SectionTitle(title: "You Might Like"),
                        const SizedBox(height: 18),
                        const _RecommendationList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Mini Player Dock
          Positioned(
            left: 14,
            right: 14,
            bottom: 24,
            child: _PremiumMiniPlayer(
              isPlaying: _isPlaying,
              onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (c, a1, a2) => const NowPlayingScreen(),
                    transitionsBuilder: (c, anim, a2, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 550),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientAtmosphere extends StatelessWidget {
  const _AmbientAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base Gradient Layer (Dark to Light Transition)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4A4A58), // Sophisticated charcoal/indigo top
                Color(0xFF6C6C80), // Mid transition
                Color(0xFFB8BCC6), // Light bluish-gray bottom
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        
        // 2. Mesh Glow Blobs (Vibrant but atmospheric)
        
        // Top Right: Warm Rose/Peach
        Positioned(
          top: -120,
          right: -80,
          child: _GlowBlob(
            color: const Color(0xFFE59A8E).withOpacity(0.5),
            radius: 480,
          ),
        ),

        // Middle Left: Soft Sky Indigo
        Positioned(
          top: 180,
          left: -150,
          child: _GlowBlob(
            color: const Color(0xFF6B8AFF).withOpacity(0.4),
            radius: 600,
          ),
        ),

        // Bottom Center: Ethereal Purple
        Positioned(
          bottom: -100,
          left: 100,
          child: _GlowBlob(
            color: const Color(0xFFB17AFF).withOpacity(0.35),
            radius: 500,
          ),
        ),

        // 3. The "Light Glass" Overlay
        // This creates the white-ish semi-transparent mist over the gradient
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            color: Colors.white.withOpacity(0.12), // Subtle white tint for "Light" theme
          ),
        ),

        // 4. Finishing Texture (Subtle Noise or Depth)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.2,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.black.withOpacity(0.08),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double radius;
  const _GlowBlob({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.1, 0.9],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.4),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.95), size: 24),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.8), size: 30),
        ],
      ),
    );
  }
}

class _RecentlyPlayedGrid extends StatelessWidget {
  const _RecentlyPlayedGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      {"name": "On My Way", "img": "https://picsum.photos/seed/way1/300/300"},
      {"name": "Safari", "img": "https://picsum.photos/seed/safari1/300/300"},
      {"name": "Come Alive", "img": "https://picsum.photos/seed/alive1/300/300"},
    ];

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 22),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        Image.network(items[i]["img"]!, width: 165, height: 165, fit: BoxFit.cover),
                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.2), Colors.white.withOpacity(0)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  items[i]["name"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList();

  @override
  Widget build(BuildContext context) {
    const tracks = [
      {"name": "Stay", "artist": "Justin Bieber", "img": "https://picsum.photos/seed/jb1/150/150"},
      {"name": "Rockstar", "artist": "Ilkay Sencan, Dynoro", "img": "https://picsum.photos/seed/rs1/150/150"},
      {"name": "Attention", "artist": "Omah Lay, Justin Bieber", "img": "https://picsum.photos/seed/al1/150/150"},
    ];

    return Column(
      children: tracks.map((track) => _TrackRow(track: track)).toList(),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Map<String, String> track;
  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(track["img"]!),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track["name"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  track["artist"]!,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF863FF0), Color(0xFFE427B4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE427B4).withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _PremiumMiniPlayer extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onTap;

  const _PremiumMiniPlayer({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 105,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.6),
            ),
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: NetworkImage('https://picsum.photos/seed/artist123/200/200'),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attention',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Charlie Puth',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.favorite, color: Colors.white.withOpacity(0.9), size: 28),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () { onPlayPause(); },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8E8E8),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF863FF0),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
