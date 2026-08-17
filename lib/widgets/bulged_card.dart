import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/services/audio_service.dart';

class BulgedCard extends StatelessWidget {
  final CategoryItem item;
  final double width;
  final double height;
  final bool isHorizontal;

  const BulgedCard({
    super.key,
    required this.item,
    this.width = 145,
    this.height = 220,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final audioService = AudioPlayerService();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Playing: ${item.title}..."),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFE052FF),
          ),
        );

        if (item.searchQuery.isNotEmpty) {
          audioService.playFromSearch(item.searchQuery, item.title);
        } else if (item.audioId.isNotEmpty) {
          audioService.playSong(item.audioId, item.title);
        }
      },
      child: isHorizontal ? _buildHorizontalCard() : _buildVerticalCard(),
    );
  }

  Widget _buildVerticalCard() {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Convex 3D surface light
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(255),  // Blinding highlight
            VesperaStyle.background,      // Midtone
            const Color(0xFFC4D0E5),      // Substantially darker shade for deep curvature
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withAlpha(220), 
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-10, -10),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0xFF90A4C4),
            offset: Offset(15, 15),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: height * 0.65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              image: DecorationImage(
                image: NetworkImage(item.image),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: VesperaStyle.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: VesperaStyle.textSecondary,
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: NetworkImage(item.image),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(80),
            BlendMode.darken,
          ),
        ),
        border: Border.all(
          color: Colors.white.withAlpha(200),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0xFF90A4C4),
            offset: Offset(10, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 25,
            bottom: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 10),
                    ],
                  ),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
