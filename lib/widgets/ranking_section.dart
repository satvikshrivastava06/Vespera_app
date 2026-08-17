import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/widgets/vespera_style.dart';
import 'package:vespera/widgets/category_section.dart';

import 'package:vespera/models/home_feed.dart';

class RankingSection extends StatelessWidget {
  final List<UserRanking>? rankings;
  
  const RankingSection({super.key, this.rankings});

  @override
  Widget build(BuildContext context) {
    // Hide the section entirely rather than invent fake users.
    // A real leaderboard system doesn't exist yet — show nothing until it does.
    if (rankings == null || rankings!.length < 3) {
      return const SizedBox.shrink();
    }
    final displayRankings = rankings!;


    // Assuming rank 1 is at index 1 for the 'top' display, rank 2 at index 0, rank 3 at index 2
    // We sort or arrange them to match the UI: Rank 2, Rank 1, Rank 3
    final rank1 = displayRankings.firstWhere((r) => r.rank == 1, orElse: () => displayRankings[1]);
    final rank2 = displayRankings.firstWhere((r) => r.rank == 2, orElse: () => displayRankings[0]);
    final rank3 = displayRankings.firstWhere((r) => r.rank == 3, orElse: () => displayRankings[2]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Monthly Ranking',
          items: displayRankings.map((r) => CategoryItem(
            title: r.name,
            subtitle: 'Rank #${r.rank}',
            image: r.imageUrl,
          )).toList(),
        ),
        const SizedBox(height: 20),
        NeumorphicContainer(
          width: double.infinity,
          height: 160,
          borderRadius: 40, // Pill shape
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildRankItem('#2', rank2.name, rank2.imageUrl, false),
              _buildRankItem('#1', rank1.name, rank1.imageUrl, true),
              _buildRankItem('#3', rank3.name, rank3.imageUrl, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankItem(String rank, String name, String imageUrl, bool isTop) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isTop ? 90 : 65,
          height: isTop ? 90 : 65,
          padding: const EdgeInsets.all(4),
          decoration: isTop
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [VesperaStyle.neonGreen, Color(0xFFC8FFD4), VesperaStyle.neonGreen],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VesperaStyle.neonGreen.withAlpha(80),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesperaStyle.background,
                ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          rank,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: isTop ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: isTop ? VesperaStyle.neonGreen : VesperaStyle.textSecondary,
          ),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: isTop ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: VesperaStyle.textPrimary,
          ),
        ),
      ],
    );
  }
}
