import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/services/audio_service.dart';

enum CategoryStyle { standard, insetImage, newRelease }

class CategorySection extends StatelessWidget {
  final String title;
  final List<CategoryItem>? items;
  final CategoryStyle style;
  final double cardWidth;
  final double cardHeight;

  const CategorySection({
    super.key,
    required this.title,
    this.items,
    this.style = CategoryStyle.standard,
    this.cardWidth = 140,
    this.cardHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    // Robust internal fallbacks
    final List<CategoryItem> displayItems = (items != null && items!.isNotEmpty)
        ? items!
        : [
            CategoryItem(title: 'Deep House', image: 'https://picsum.photos/seed/${title}1/300/300'),
            CategoryItem(title: 'Classic Mood', image: 'https://picsum.photos/seed/${title}2/300/300'),
            CategoryItem(title: 'Studio', image: 'https://picsum.photos/seed/${title}3/300/300'),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, items: displayItems),
        const SizedBox(height: 20),
        SizedBox(
          height: cardHeight + 10, // Padding for shadow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: _buildCard(context, displayItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, CategoryItem item) {
    if (style == CategoryStyle.newRelease) {
      return NeumorphicContainer(
        width: cardWidth,
        height: cardHeight,
        borderRadius: 30,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesperaStyle.textSecondary.withAlpha(20),
            ),
            child: const Icon(Icons.album_rounded, color: VesperaStyle.textSecondary),
          ),
        ),
      );
    }

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
      child: NeumorphicContainer(
        width: cardWidth,
        height: cardHeight,
        borderRadius: 30,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (style == CategoryStyle.insetImage)
              Flexible(
                child: NeumorphicContainer(
                  width: cardWidth - 32,
                  height: cardWidth - 32,
                  borderRadius: 22,
                  isInset: true,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(2), // Even smaller margin for maximum fit
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: NetworkImage(item.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: Container(
                  width: cardWidth - 32,
                  height: cardWidth - 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: NetworkImage(item.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: VesperaStyle.textPrimary,
              ),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: VesperaStyle.cyanText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final String? subtitle;
  final String image;
  final String audioId;
  final String searchQuery;

  const CategoryItem({
    required this.title,
    this.subtitle,
    required this.image,
    this.audioId = '',
    this.searchQuery = '',
  });
}
