import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FloatingNavActive { home, profile }

/// Glassmorphic floating bar shared by Explore main and Profile screens.
class FloatingBottomNav extends StatelessWidget {
  final FloatingNavActive active;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onExploreGridTap;
  final VoidCallback? onSearchTap;

  const FloatingBottomNav({
    super.key,
    this.active = FloatingNavActive.home,
    this.onHomeTap,
    this.onProfileTap,
    this.onExploreGridTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 34,
            left: 52,
            right: 52,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                    blurRadius: 48,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(-8, 4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 34,
            left: 52,
            right: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E1B3A).withValues(alpha: 0.92),
                        const Color(0xFF151228).withValues(alpha: 0.94),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onHomeTap,
                        child: active == FloatingNavActive.home
                            ? _activePill(
                                icon: Icons.home_rounded,
                                label: 'Home',
                              )
                            : _navIcon(Icons.home_rounded),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onSearchTap,
                        child: _navIcon(Icons.search_rounded),
                      ),
                      const SizedBox(width: 22),
                      GestureDetector(
                        onTap: onExploreGridTap,
                        child: _navIcon(Icons.grid_view_rounded),
                      ),
                      const SizedBox(width: 22),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: active == FloatingNavActive.profile
                            ? _activePill(
                                icon: Icons.person_rounded,
                                label: 'Profile',
                              )
                            : _navIcon(Icons.person_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Container(
              width: 128,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activePill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D3566), Color(0xFF2A2548)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon) {
    return Icon(
      icon,
      color: Colors.white.withValues(alpha: 0.92),
      size: 22,
    );
  }
}
