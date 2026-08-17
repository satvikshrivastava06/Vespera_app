import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/screens/explore_screen.dart';
import 'package:vespera/widgets/floating_bottom_nav.dart';

/// Profile screen — dark editorial layout with orange-red accents (#FF4500).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _accent = Color(0xFFFF4500);
  final PageController _heroController = PageController();
  int _heroPage = 0;

  static const List<_HeroSlide> _heroSlides = [
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80',
      seed: 'hero_red_moon',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1614728263952-84ea256f9679?w=800&q=80',
      seed: 'hero_dark_wave',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1506318137071-a8e063bc4cbd?w=800&q=80',
      seed: 'hero_crimson',
    ),
  ];

  static const List<_TasteCard> _tasteCards = [
    _TasteCard('Dead inside', '2020', 'taste_dead'),
    _TasteCard('Alone', '2023', 'taste_alone'),
    _TasteCard('Heartless', '2023', 'taste_heart'),
    _TasteCard('Void', '2022', 'taste_void'),
  ];

  static const List<_TrackRow> _tracks = [
    _TrackRow('We Are Chaos', '2023 • Easy Living', 'track_chaos'),
    _TrackRow('Smile', '2023 • Berrechid', 'track_smile'),
    _TrackRow('Night Crawler', '2024 • Vespera', 'track_night'),
  ];

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader()),
              SliverToBoxAdapter(child: _buildMusicTasteSection()),
              SliverToBoxAdapter(child: _buildRecommendationsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              active: FloatingNavActive.profile,
              onHomeTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              onExploreGridTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExploreScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    const heroHeight = 340.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _heroController,
                onPageChanged: (i) => setState(() => _heroPage = i),
                itemCount: _heroSlides.length,
                itemBuilder: (context, index) {
                  final slide = _heroSlides[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        slide.imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => Image.network(
                          'https://picsum.photos/seed/${slide.seed}/800/600',
                          fit: BoxFit.cover,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.35),
                              _bg.withValues(alpha: 0.55),
                              _bg,
                            ],
                            stops: const [0.0, 0.45, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SubscribeButton(onTap: () {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(child: _buildPageIndicators()),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_heroSlides.length, (i) {
        final active = i == _heroPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _accent : const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildMusicTasteSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Your music taste',
            titleColor: _accent,
            seeAllColor: _accent.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 198,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _tasteCards.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final card = _tasteCards[index];
                return _TasteAlbumCard(
                  title: card.title,
                  year: card.year,
                  imageSeed: card.seed,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Based on your music taste',
            titleColor: const Color(0xFFB0B0B5),
            seeAllColor: _accent,
          ),
          const SizedBox(height: 16),
          ..._tracks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _TrackListTile(
                title: t.title,
                subtitle: t.subtitle,
                imageSeed: t.seed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required Color titleColor,
    required Color seeAllColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: titleColor,
              letterSpacing: -0.25,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'See all',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: seeAllColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SubscribeButton({required this.onTap});

  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4500),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4500).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Subscribe',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TasteAlbumCard extends StatelessWidget {
  final String title;
  final String year;
  final String imageSeed;

  const _TasteAlbumCard({
    required this.title,
    required this.year,
    required this.imageSeed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://picsum.photos/seed/$imageSeed/240/320',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            year,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageSeed;

  const _TrackListTile({
    required this.title,
    required this.subtitle,
    required this.imageSeed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            'https://picsum.photos/seed/$imageSeed/120/120',
            width: 54,
            height: 54,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.more_vert_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: 22,
        ),
      ],
    );
  }
}

class _HeroSlide {
  final String imageUrl;
  final String seed;

  const _HeroSlide({required this.imageUrl, required this.seed});
}

class _TasteCard {
  final String title;
  final String year;
  final String seed;

  const _TasteCard(this.title, this.year, this.seed);
}

class _TrackRow {
  final String title;
  final String subtitle;
  final String seed;

  const _TrackRow(this.title, this.subtitle, this.seed);
}
