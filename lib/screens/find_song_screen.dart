import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FindSongScreen extends StatefulWidget {
  const FindSongScreen({super.key});

  @override
  State<FindSongScreen> createState() => _FindSongScreenState();
}

class _FindSongScreenState extends State<FindSongScreen> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with light leaks
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF090D18), // Deep navy
                  Color(0xFF020409), // Almost black
                ],
              ),
            ),
          ),
          
          // Subtle indigo light leak top left
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF371D7B).withAlpha(100),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF371D7B), blurRadius: 120, spreadRadius: 60)
                ]
              ),
            ),
          ),
          // Subtle indigo light leak bottom right
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E3A8A).withAlpha(80),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF1E3A8A), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Dynamic Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Text
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Identifying ',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            TextSpan(
                              text: 'Songs',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side actions
                      Row(
                        children: [
                          const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 20),
                          Stack(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF090D18), width: 2),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),

                // Central Visualizer
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer magenta glow
                        Transform.scale(
                          scale: _glowAnimation.value * 1.1,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFF00FF).withAlpha(50), blurRadius: 100, spreadRadius: 40)
                              ],
                            ),
                          ),
                        ),
                        // Mid purple glow
                        Transform.scale(
                          scale: _glowAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.purpleAccent.withAlpha(80), blurRadius: 80, spreadRadius: 25)
                              ],
                            ),
                          ),
                        ),
                        // Inner teal glow
                        Transform.scale(
                          scale: _glowAnimation.value * 0.9,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.tealAccent.withAlpha(120), blurRadius: 50, spreadRadius: 15)
                              ],
                            ),
                          ),
                        ),
                        // Solid black center
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Spacer(flex: 3),

                // My Music Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'My Music',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'View all',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Track Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20), // 0.08 = 20 alpha out of 255
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withAlpha(25), // 0.1 = 25 alpha
                          ),
                        ),
                        child: Row(
                          children: [
                            // Square album art
                            Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=200&auto=format&fit=crop'), // Aesthetic space/abstract art
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'The Ascent',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Generdyn',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFA0AEC0),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Duration
                            Text(
                              '3:23',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Custom Back Button to slide down/back
          Positioned(
            top: 50,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
