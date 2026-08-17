import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/screens/twilight_screen.dart';

class TwilightBanner extends StatelessWidget {
  const TwilightBanner({super.key});

  void _openTwilight(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TwilightScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up + fade
          final slideTween = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ),
          );
          return FadeTransition(
            opacity: fadeTween,
            child: SlideTransition(position: slideTween, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Twilight', showViewAll: false),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _openTwilight(context),
          child: Hero(
            tag: 'twilight_interface_transition',
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E0A2D), Color(0xFF0D0312)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E0A2D).withAlpha(150),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    offset: Offset(-4, -4),
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&q=80',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    'T W I L I G H T',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
