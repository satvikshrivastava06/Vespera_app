import 'package:flutter/material.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/category_section.dart';
import 'package:vespera/widgets/bulged_card.dart';

class BulgedCategorySection extends StatelessWidget {
  final String title;
  final List<CategoryItem>? items;
  final double cardWidth;
  final double cardHeight;

  const BulgedCategorySection({
    super.key,
    required this.title,
    this.items,
    this.cardWidth = 145,
    this.cardHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final List<CategoryItem> displayItems = items ?? const <CategoryItem>[];
    if (displayItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, items: displayItems),
        const SizedBox(height: 20),
        SizedBox(
          height: cardHeight + 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 25, bottom: 20, top: 15, left: 5),
                child: BulgedCard(
                  item: displayItems[index],
                  width: cardWidth,
                  height: cardHeight,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Alias for backwards compatibility if needed, but we should migrate to CategoryItem
typedef BulgedCategoryItem = CategoryItem;
