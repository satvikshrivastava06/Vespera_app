import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';

class NewsItemWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final Color badgeColor;
  final String imageUrl;

  const NewsItemWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.badgeColor,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      borderRadius: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                // Use weserv.nl as an image proxy to handle CORS and resizing on web
                'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=200&h=200&fit=cover',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: VesperaStyle.accent.withAlpha(50),
                  child: const Icon(Icons.newspaper, color: VesperaStyle.accent),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: VesperaStyle.accent.withAlpha(20),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: VesperaStyle.accent),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: VesperaStyle.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: VesperaStyle.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
