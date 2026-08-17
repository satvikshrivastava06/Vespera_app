import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';

class MoodGenreSection extends StatelessWidget {
  const MoodGenreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mood and Genres',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VesperaStyle.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: VesperaStyle.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Row(
          children: [
            Expanded(
              child: MoodCard(
                title: 'Energetic',
                gradient: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: MoodCard(
                title: 'Relax',
                gradient: [Color(0xFF64B5F6), Color(0xFF4FC3F7)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MoodCard extends StatelessWidget {
  final String title;
  final List<Color> gradient;

  const MoodCard({super.key, required this.title, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      height: 100,
      borderRadius: 20,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
