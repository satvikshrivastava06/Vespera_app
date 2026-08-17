import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/find_song_screen.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Find Song Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const FindSongScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // A smooth fade and slight scale up transition
                  var curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curve,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF233041), // Dark grey-blue
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.deepOrangeAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find Song',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // Center Logo
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(40),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF60A5FA).withAlpha(30),
                  blurRadius: 45,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
          ),
        ),
        
        // 3-dot menu
        Container(
          width: 55,
          height: 55,
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }
}

class SearchInputField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  const SearchInputField({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background and inner shadow provider
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFDFE2E8), // Light gray background
            borderRadius: BorderRadius.circular(25), // Pill shape
            border: Border.all(
              color: Colors.black.withAlpha(20),
              width: 1.5, // Subtle top rim
            ),
          ),
        ),
        // Inner content
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(15), // Inner shadow top
                Colors.transparent,
                Colors.white.withAlpha(80), // Inner highlight bottom
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search for tracks, artists...',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 4),
                  ),
                ),
              ),
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
                size: 26,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DarkSectionTitle extends StatelessWidget {
  final String title;

  const DarkSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white,
          size: 22,
        ),
      ],
    );
  }
}

class SquareAlbumCard extends StatelessWidget {
  final String imageUrl;

  const SquareAlbumCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

class VerticalTrendingCard extends StatelessWidget {
  final String imageUrl;

  const VerticalTrendingCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

class RecentSongTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String duration;

  const RecentSongTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Square thumbnail
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Duration
          Text(
            duration,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          
          // Play Button
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF0F172A), // Dark color for play icon
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class DarkGlassNavBar extends StatelessWidget {
  const DarkGlassNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 80,
          color: const Color(0xFF253342).withAlpha(150),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.home_rounded, color: Colors.blueAccent, size: 32),
              Icon(Icons.library_add_rounded, color: Colors.white60, size: 28),
              Icon(Icons.favorite_rounded, color: Colors.white60, size: 28),
              Icon(Icons.album_rounded, color: Colors.white60, size: 28),
              Icon(Icons.account_circle_rounded, color: Colors.white60, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
